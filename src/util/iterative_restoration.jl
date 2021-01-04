## Process::
# 1. take network and create XX repair periods and solve ROP.
# 2. take each single network from (1) and break into XX repair periods and solve ROP.
#       - this requires extensive reorganizing of the data dict to set status values
#       - if a device is repaired after this network, the status is 0 ->seems to be set by solution builder? need to double check buses.
#       - if a device is repaired before this network, the status is 1, damaged is 0
#       - if a device is repaired in this network, the status is 1, damaged is 1
# 3. do recursion on 2 until the number of repairs is <= XX and there is only 1 item repaired per time period
# 4. report a final restoration dictionary with the ordered repairs (this dictionary should only contain
#     solution data from last period restoration)


"solve restoration using iterative period length"
function run_iterative_restoration(network, model_constructor, optimizer; repair_periods=2, kwargs...)
    if _IM.ismultinetwork(network)
        Memento.error(_PM._LOGGER, "iterative restoration does not support multinetwork starting conditions")
    end

    Memento.info(_PM._LOGGER, "Iterative Restoration Algorithm starting...")

    ## Run initial MLD problem
    Memento.info(_PM._LOGGER, "begin baseline Maximum Load Delivery")

    network_mld = deepcopy(network)
    propagate_damage_status!(network_mld)
    set_component_inactive!(network_mld, get_damaged_items(network_mld))
    _PM.simplify_network!(network_mld)

    result_mld = run_mld_strg(network_mld, model_constructor, optimizer, kwargs...)

    clean_status!(result_mld["solution"])

    ## Turn network into multinetwork solution to merge with solution_iterative
    mn_network_mld = _PM.replicate(result_mld["solution"], 1)
    mn_network_mld["nw"]["0"] = mn_network_mld["nw"]["1"]
    delete!(mn_network_mld["nw"], "1")
    result_mld["solution"] = mn_network_mld

    Memento.info(_PM._LOGGER, "begin Iterative Restoration")
    result_iterative = _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)
    merge_solution!(result_iterative, result_mld)

    # this sets the status of components that were removed by
    # propagate_damage_status!, set_component_inactive!, propagate_topology_status!, ...
    for (nw,sol) in result_iterative["solution"]["nw"]
        for (i,bus) in network["bus"]
            init_bus = network_mld["bus"][i]
            if bus["bus_type"] != 4 && init_bus["bus_type"] == 4
                sol_bus = sol["bus"][i] = get(sol["bus"], i, Dict{String,Any}("status" => 0, "va" => 0.0, "vm" => 0.0))
                if !haskey(sol_bus, "status")
                    sol_bus["status"] = 0
                end
            end
        end

        for (i,gen) in network["gen"]
            init_gen = network_mld["gen"][i]
            if gen["gen_status"] != 0 && init_gen["gen_status"] == 0
                sol_gen = sol["gen"][i] = get(sol["gen"], i, Dict{String,Any}("gen_status" => 0, "pg" => 0.0, "qg" => 0.0))
                if !haskey(sol_gen, "gen_status")
                    sol_gen["status"] = 0
                end
            end
        end

        for (i,strg) in network["storage"]
            init_strg = network_mld["storage"][i]
            if strg["status"] != 0 && init_strg["status"] == 0
                sol_storage = sol["storage"][i] = get(sol["storage"], i, Dict{String,Any}("status" => 0, "ps" => 0.0, "qs" => 0.0))
                if !haskey(sol_storage, "status")
                    sol_storage["status"] = 0
                end
            end
        end

        if haskey(sol, "branch")
            for (i,branch) in network["branch"]
                init_branch = network_mld["branch"][i]
                if branch["br_status"] != 0 && init_branch["br_status"] == 0
                    sol_branch = sol["branch"][i] = get(sol["branch"], i, Dict{String,Any}("br_status" => 0))
                    if !haskey(sol_branch, "br_status")
                        sol_branch["br_status"] = 0
                    end
                end
            end
        else
            # this occurs for inital solution where the MLD model does not reason over branch status
            sol["branch"] = Dict{String,Any}()
            for (i,branch) in network["branch"]
                init_branch = network_mld["branch"][i]
                if branch["br_status"] != 0 && init_branch["br_status"] == 0
                    sol["branch"][i] = Dict("br_status" => 0)
                end
            end
        end
    end

    return result_iterative
end



function _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=2, kwargs...)

    ## Set up network data files
    restoration_network = replicate_restoration_network(network, count=repair_periods)

    ## Run ROP problem with lower bound on restoration cardinality and partial load restoration
    restoration_solution = _run_rop_ir(restoration_network, model_constructor, optimizer, kwargs...)

    ## Was the network solved?
    if restoration_solution["termination_status"]!= _MOI.OPTIMAL && restoration_solution["termination_status"]!= _MOI.LOCALLY_SOLVED
        Memento.warn(_PM._LOGGER, "subnetwork i was not solved, returning current solution")
        terminate_problem = true
    else
        terminate_problem = false
    end

    clean_solution!(restoration_solution)
    clean_status!(restoration_solution)
    _PM.update_data!(restoration_network, restoration_solution["solution"])
    clean_status!(restoration_network)
    process_repair_status!(restoration_network)
    delete!(restoration_network["nw"],"0")

    # copy network metadata, remove network data. There should be a better way of doing this.
    subnet_solution_set = deepcopy(restoration_solution)
    subnet_solution_set["solution"]["nw"] = Dict{String,Any}()

    ## do all repairs occur in one network?
    repairs = get_item_repairs(restoration_network)
    terminate_recursion = count(~isempty(nw_repairs) for (nw,nw_repairs) in repairs)==1

    # do not run attempt restoration on network "0"
    delete!(restoration_network["nw"],"0")

    for(nw_id, net) in sort(Dict{Int,Any}([(parse(Int, k), v) for (k,v) in restoration_network["nw"]]))
        if count_repairable_items(net) > 1 && ~terminate_problem && ~terminate_recursion
            Memento.info(_PM._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(net)) damaged items and $(count_repairable_items(net)) repairable items")

            Memento.info(_PM._LOGGER, "Starting sub network restoration")
            for k in keys(restoration_network)
                if k != "nw"
                    net[k] = restoration_network[k]
                end
                net["multinetwork"] = false
            end

            Memento.info(_PM._LOGGER, "Start recursive call")
            subnet_solution = _run_iterative_sub_network(net, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)

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
            subnet_solution_set["solution"]["nw"]["$(last_network+1)"] = net

            Memento.info(_PM._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(net)) damaged items and $(count_repairable_items(net)) repairable items")
            Memento.info(_PM._LOGGER, "sub_network does not need restoration sequencing")
        end
    end

    return subnet_solution_set
end


"Merge solution dictionaries and accumulate solvetime and objective"
function merge_solution!(solution1, solution2)
    Memento.info(_PM._LOGGER, "networks $(keys(solution2["solution"]["nw"])) finished with status $(solution2["termination_status"])")

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

function get_item_repairs(mn_data)
    repairs = Dict{String,Array{Tuple{String,String},1}}(nw=>[] for nw in keys(mn_data["nw"]))
    if _IM.ismultinetwork(mn_data)
        for (nw_id, network) in mn_data["nw"]
            for (comp_type, comp_status) in _PM.pm_component_status
                for (comp_id, comp) in network[comp_type]
                    if nw_id != "0" #not items are repaired in "0", do not check in previous network for a change
                        if comp[comp_status] != _PM.pm_component_status_inactive[comp_type] &&  # if comp is active
                            mn_data["nw"]["$(parse(Int,nw_id)-1)"][comp_type][comp_id][comp_status] == _PM.pm_component_status_inactive[comp_type] # if comp was previously inactive
                            push!(repairs[nw_id], (comp_type,comp_id))
                        end
                    end
                end
            end
        end
    else
        Memento.error(_PM._LOGGER, "get_item_repairs requires multinetwork.")
    end
    return repairs
end


"Remove damage status if a device has already been repaired"
function process_repair_status!(mn_data)
    if _IM.ismultinetwork(mn_data)
        repairs = get_item_repairs(mn_data)
        for (nw_repair,items) in repairs
            for (comp_type,comp_id) in items
                for nw_network in keys(mn_data["nw"])
                    if nw_repair <= nw_network
                        comp = mn_data["nw"][nw_network][comp_type][comp_id]
                        if haskey(comp,"damaged") && comp["damaged"]==1
                            Memento.info(_PM._LOGGER, "$(comp_type) $(comp_id) was repaired at step $(nw_repair). Setting damaged state to 0 in network $(nw_network).")
                            comp["damaged"]=0
                        end
                    end
                end
            end
        end
    else
        Memento.error(_PM._LOGGER, "get_item_repairs requires multinetwork")
    end
end


""
function _run_rop_ir(file, model_constructor, optimizer; kwargs...)
    return _PM.run_model(file, model_constructor, optimizer, _build_rop_ir; multinetwork=true,
        ref_extensions=[_PM.ref_add_on_off_va_bounds!, ref_add_damaged_items!], kwargs...)
end


""
function _build_rop_ir(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)
        variable_bus_damage_indicator(pm, nw=n)
        variable_bus_voltage_damage(pm, nw=n)

        variable_branch_damage_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)

        _PM.variable_dcline_power(pm, nw=n)

        variable_storage_damage_indicator(pm, nw=n)
        variable_storage_power_mi_damage(pm, nw=n)

        variable_gen_damage_indicator(pm, nw=n)
        variable_gen_power_damage(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        constraint_restoration_cardinality_ub(pm, nw=n)
        constraint_restoration_cardinality_lb(pm, nw=n)

        constraint_model_voltage_damage(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_bus_damage_soft(pm, i, nw=n)
            constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gen, nw=n)
            constraint_gen_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :load, nw=n)
            constraint_load_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :shunt, nw=n)
            constraint_shunt_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            constraint_branch_damage(pm, i, nw=n)
            constraint_ohms_yt_from_damage(pm, i, nw=n)
            constraint_ohms_yt_to_damage(pm, i, nw=n)

            constraint_voltage_angle_difference_damage(pm, i, nw=n)

            constraint_thermal_limit_from_damage(pm, i, nw=n)
            constraint_thermal_limit_to_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            constraint_storage_damage(pm, i, nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PM.constraint_storage_losses(pm, i, nw=n)
        end
    end


    network_ids = sort(collect(_PM.nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PM.ids(pm, :storage, nw=n_1)
        _PM.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage, nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :gen, nw=n_2)
            constraint_gen_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :bus, nw=n_2)
            constraint_bus_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :storage, nw=n_2)
            constraint_storage_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_branch_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :load, nw=n_2)
            constraint_load_increasing(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    n_final = last(network_ids)
    constraint_restore_all_items_partial_load(pm, n_final)

    objective_max_load_delivered(pm)
end

function constraint_restore_all_items_partial_load(pm, n)
    z_storage = _PM.var(pm, n, :z_storage)
    z_gen = _PM.var(pm, n, :z_gen)
    z_branch = _PM.var(pm, n, :z_branch)
    z_bus = _PM.var(pm, n, :z_bus)

    for (i,storage) in  _PM.ref(pm, n, :storage_damage)
        JuMP.@constraint(pm.model, z_storage[i] == 1)
    end
    for (i,gen) in  _PM.ref(pm, n, :gen_damage)
        JuMP.@constraint(pm.model, z_gen[i] == 1)
    end
    for (i,branch) in  _PM.ref(pm, n, :branch_damage)
        JuMP.@constraint(pm.model, z_branch[i] == 1)
    end
    for (i,bus) in  _PM.ref(pm, n, :bus_damage)
        JuMP.@constraint(pm.model, z_bus[i] == 1)
    end
end

