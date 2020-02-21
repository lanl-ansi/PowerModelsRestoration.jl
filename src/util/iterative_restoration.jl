## Process::
# 1. take network and create XX repair periods and solve ROP.
# 2. take each single network from 1 and break into XX repair periods and solve ROP.
#       - this requires extensive rehashing of the data dict to set status values
#       - if a device is repaired after this network, the status is 0 ->seems to be set by solution builder? need to double check buses.
#       - if a device is repaired before this network, the status is 1, damaged is 0
#       - if a device is repaired in this network, the status is 1, damaged is 1
# 3. repeat 2 until the number of repairs is <= XX and there is only 1 item repaired per time period
# 4. report a final restoration dictionary with the ordered repairs (this dictionary should only contain
#     solution data from last period restoration)


"solve restoration using iterative period length"
function run_iterative_restoration(network, model_constructor, optimizer; repair_periods=2, kwargs...)
    if _IMs.ismultinetwork(network)
        Memento.error(_PMs._LOGGER, "iterative restoration does not support multinetwork starting conditions")
    end

    ## initialize solution dictionary (will be incrementaly updated)
    solution = Dict{String,Any}(
        "optimizer" => PowerModels._MOI.get(optimizer.constructor(), PowerModels._MOI.SolverName())::String,
        "termination_status" => PowerModels._MOI.OPTIMIZE_NOT_CALLED::PowerModels._MOI.TerminationStatusCode,
        "primal_status" => PowerModels._MOI.NO_SOLUTION::PowerModels._MOI.ResultStatusCode,
        "dual_status" => PowerModels._MOI.NO_SOLUTION::PowerModels._MOI.ResultStatusCode,
        "objective" => 0.0::Float64,
        "objective_lb" => 0.0::Float64,
        "solve_time" => 0.0::Float64,
        "solution" => Dict{String,Any}("nw" => Dict{String,Any}(), "multinetwork" => true),
        "machine" => Dict(
            "cpu" => Sys.cpu_info()[1].model,
            "memory" => string(Sys.total_memory()/2^30, " Gb")
            ),
        "data" => replicate_restoration_network(network, count=count_damaged_items(network))
    )

    Memento.info(_PMs._LOGGER, "Iterative Restoration Algorithm starting...")
    ## Run initial MLD problem
    Memento.info(_PMs._LOGGER, "begin baseline Maximum Load Delivery")

    network_mld = deepcopy(network)
    propagate_damage_status!(network_mld)
    set_component_inactive!(network_mld, get_damaged_items(network_mld))
    _PMs.propagate_topology_status!(network_mld)

    solution_mld = run_mld_strg(network_mld, model_constructor, optimizer, kwargs...)
    clean_status!(solution_mld["solution"])
    _PMs.update_data!(network_mld, solution_mld["solution"])

    ## Turn network into multinetwork solution to merge with solution_iterative
    mn_network_mld = _PMs.replicate(network_mld,1)
    mn_network_mld["nw"]["0"] = mn_network_mld["nw"]["1"]
    delete!(mn_network_mld["nw"],"1")
    solution_mld["solution"] = mn_network_mld

    Memento.info(_PMs._LOGGER, "begin Iterative Restoration")
    solution_iterative = _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)
    merge_solution!(solution_iterative, solution_mld)
    merge_solution!(solution, solution_iterative)

    return solution
end


function _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=2, kwargs...)

    ## Set up network data files
    restoration_network = replicate_restoration_network(network, count=repair_periods)

    ## Run ROP problem with lower bound on restoration cardinality and partial load restoration
    restoration_solution = _run_rop_ir(restoration_network, model_constructor, optimizer, kwargs...)

    clean_status!(restoration_solution["solution"])
    _PMs.update_data!(restoration_network, restoration_solution["solution"]) # will update, loads, storage, etc....
    update_damage_status!(restoration_network) #set status of items before/after repairs
    delete!(restoration_network["nw"],"0")

    subnet_solution_set = deepcopy(restoration_solution)
    subnet_solution_set["solution"]["nw"] = Dict{String,Any}()

    for(nw_id, network) in sort(Dict{Int,Any}([(parse(Int, k), v) for (k,v) in restoration_network["nw"]]))
        if count_repairable_items(network) > 1
            Memento.info(_PMs._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(network)) damaged items and $(count_repairable_items(network)) repairable items")

            Memento.info(_PMs._LOGGER, "Starting sub network restoration")
            for k in keys(restoration_network)
                if k != "nw"
                    network[k] = restoration_network[k]
                end
                network["multinetwork"] = false
            end

            Memento.info(_PMs._LOGGER, "Start recursive call")
            subnet_solution = _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)

            ##  Rename solution nw_ids appropriately
            last_network = isempty(subnet_solution_set["solution"]["nw"]) ? 0 : maximum(parse.(Int,keys(subnet_solution_set["solution"]["nw"])))
            temp_solution = deepcopy(subnet_solution)
            temp_solution["solution"]["nw"] = Dict{String,Any}()
            for (id, net) in subnet_solution["solution"]["nw"]
                if id != "0"
                    temp_solution["solution"]["nw"]["$(last_network+parse(Int,id))"] = net
                end
            end
            merge_solution!(subnet_solution_set, temp_solution)

        else

            last_network = isempty(subnet_solution_set["solution"]["nw"]) ? 0 : maximum(parse.(Int,keys(subnet_solution_set["solution"]["nw"])))
            subnet_solution_set["solution"]["nw"]["$(last_network+1)"] = network

            Memento.info(_PMs._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(network)) damaged items and $(count_repairable_items(network)) repairable items")
            Memento.info(_PMs._LOGGER, "sub_network does not need restoration sequencing")
        end
    end

    return subnet_solution_set
end


"Merge solution dictionaries and accumulate solvetime and objective"
function merge_solution!(solution1, solution2)
    Memento.info(_PMs._LOGGER, "networks $(keys(solution2["solution"]["nw"])) finished with status $(solution2["termination_status"])")

    solution1["termination_status"] = max(solution1["termination_status"],solution2["termination_status"])
    solution1["primal_status"] = max(solution1["primal_status"],solution2["primal_status"])
    solution1["dual_status"] = max(solution1["dual_status"],solution2["dual_status"])
    solution1["solve_time"] += solution2["solve_time"]
    solution1["objective"] += solution2["objective"]
    solution1["objective_lb"] += solution2["objective_lb"]
    for (nw_id, network) in solution2["solution"]["nw"]
        solution1["solution"]["nw"][nw_id] = network
    end
end


" Update damage status for each time period based on whether the device has already been repaired"
function update_damage_status!(mn_data)
    if _IMs.ismultinetwork(mn_data)
        for (nw_id, network) in mn_data["nw"]
            for (comp_type, comp_status) in _PMs.pm_component_status
                for (comp_id, comp) in network[comp_type]
                    if nw_id != "0" #not items are repaired in "0", do not check in previous network for a change
                        if comp[comp_status] != _PMs.pm_component_status_inactive[comp_type] &&  # if comp is active
                            mn_data["nw"]["$(parse(Int,nw_id)-1)"][comp_type][comp_id][comp_status] != _PMs.pm_component_status_inactive[comp_type] # if comp was previously active
                            if haskey(comp,"damaged") && comp["damaged"] == 1
                                # therefore the comp was repaired in a former time_step, should be considered undamaged
                                Memento.info(_PMs._LOGGER, "$(comp_type) $(comp_id) was repaired before step $(nw_id). Setting damged state to 0.")
                                comp["damaged"] = 0
                            end
                        end
                    end
                end
            end
        end
    else
        Memento.error(_PMs._LOGGER, "update_damage_status required multinetwork to identify is a device has been previously repaired.")
    end
end

""
function _run_rop_ir(file, model_constructor, optimizer; kwargs...)
    return _PMs.run_model(file, model_constructor, optimizer, _build_rop_ir; multinetwork=true,
        ref_extensions=[_PMs.ref_add_on_off_va_bounds!, ref_add_damaged_items!],
        solution_builder = solution_rop!, kwargs...)
end


""
function _build_rop_ir(pm::_PMs.AbstractPowerModel)
    for (n, network) in _PMs.nws(pm)
        variable_bus_damage_indicator(pm, nw=n)
        variable_voltage_damage(pm, nw=n)

        variable_branch_damage_indicator(pm, nw=n)
        _PMs.variable_branch_flow(pm, nw=n)

        _PMs.variable_dcline_flow(pm, nw=n)

        variable_storage_damage_indicator(pm, nw=n)
        variable_storage_mi_damage(pm, nw=n)

        variable_generation_damage_indicator(pm, nw=n)
        variable_generation_damage(pm, nw=n)

        variable_demand_factor(pm, nw=n, relax=true)
        variable_shunt_factor(pm, nw=n, relax=true)

        constraint_restoration_cardinality_ub(pm, nw=n)
        constraint_restoration_cardinality_lb(pm, nw=n)

        constraint_model_voltage_damage(pm, nw=n)

        for i in _PMs.ids(pm, :ref_buses, nw=n)
            _PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :bus, nw=n)
            constraint_bus_voltage_violation_damage(pm, i, nw=n)
            constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :gen, nw=n)
            constraint_generation_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :load, nw=n)
            constraint_load_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :shunt, nw=n)
            constraint_shunt_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :branch, nw=n)
            constraint_branch_damage(pm, i, nw=n)
            constraint_ohms_yt_from_damage(pm, i, nw=n)
            constraint_ohms_yt_to_damage(pm, i, nw=n)

            constraint_voltage_angle_difference_damage(pm, i, nw=n)

            constraint_thermal_limit_from_damage(pm, i, nw=n)
            constraint_thermal_limit_to_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :dcline, nw=n)
            _PMs.constraint_dcline(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :storage, nw=n)
            constraint_storage_damage(pm, i, nw=n)
            _PMs.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PMs.constraint_storage_loss(pm, i, nw=n)
        end
    end


    network_ids = sort(collect(_PMs.nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PMs.ids(pm, :storage, nw=n_1)
        _PMs.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PMs.ids(pm, :storage, nw=n_2)
            _PMs.constraint_storage_state(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :gen, nw=n_2)
            constraint_active_gen(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :bus, nw=n_2)
            constraint_active_bus(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :storage, nw=n_2)
            constraint_active_storage(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :branch, nw=n_2)
            constraint_active_branch(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :load, nw=n_2)
            constraint_increasing_load(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    n_final = last(network_ids)
    constraint_restore_all_items_partial_load(pm, n_final)

    objective_max_load_delivered(pm)
end

function constraint_restore_all_items_partial_load(pm, n)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)
    z_bus = _PMs.var(pm, n, :z_bus)

    for (i,storage) in  _PMs.ref(pm, n, :damaged_storage)
        JuMP.@constraint(pm.model, z_storage[i] == 1)
    end
    for (i,gen) in  _PMs.ref(pm, n, :damaged_gen)
        JuMP.@constraint(pm.model, z_gen[i] == 1)
    end
    for (i,branch) in  _PMs.ref(pm, n, :damaged_branch)
        JuMP.@constraint(pm.model, z_branch[i] == 1)
    end
    for (i,bus) in  _PMs.ref(pm, n, :damaged_bus)
        JuMP.@constraint(pm.model, z_bus[i] == 1)
    end
end

