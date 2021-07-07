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



function run_iterative_restoration(network, model_constructor, optimizer; repair_periods=2, kwargs...)
    t_start = time()
    sol = _run_iter_res(network, model_constructor, optimizer; repair_periods, kwargs...)
    fill_missing_variables!(sol, network) # some networks do not have all variables if devices were status 0
    sol["solve_time"] = time()-t_start
    return sol
end


"recrusive call to iterative restoration"
function _run_iterative_restoration(network,model_constructor,optimizer; repair_periods=2, kwargs... )
    mn_network = replicate_restoration_network(network, repair_periods, _PM._pm_global_keys)

    ## solve ROP problem
    solution = _run_rop_ir(mn_network, model_constructor, optimizer; kwargs...)

    ## Clean solution and apply result to network
    clean_status!(solution["solution"]) # replace status with bus_type for buses
    apply_repairs!(mn_network, get_repairs(solution))

    r_count = count_cumulative_repairs(solution)
    ## IF (all repairs in period 2) OR (infeasible), then run ROP and return
    if (r_count["1"]==0 && r_count["2"]!=0) || solution["termination_status"]==_PM.INFEASIBLE

        damage_count = count_repairable_items(network)
        mn_network = replicate_restoration_network(network, damage_count, _PM._pm_global_keys)

        Memento.info(_PM._LOGGER, "Starting a $(damage_count) period ROP problem")
        solution = _run_rop_ir(mn_network, model_constructor, optimizer; kwargs...)
        clean_status!(solution["solution"])

        ## remove network "0" for recursion
        delete!(solution["solution"]["nw"],"0")
        return_solution = deepcopy(solution) # return network

    else # ELSE run iter on each network
        delete!(mn_network["nw"],"0") # remove network "0" for recursion
        return_solution = deepcopy(solution) # create return network
        return_solution["solution"]["nw"]=Dict{String,Any}()

        for (nw_id) in string.(sort(parse.(Int,collect(keys(mn_network["nw"])))))
            net = mn_network["nw"][nw_id]

            ## IF more than 1 repair in time period, run recursion
            if count_repairable_items(net) != 1
                sub_net = deepcopy(net)
                for key in _PM._pm_global_keys
                    if haskey(network, key)
                        sub_net[key] = network[key]
                    end
                end

                sub_sol = _run_iter_res(sub_net, model_constructor, optimizer; repair_periods, kwargs...)
                return_keys = keys(return_solution["solution"]["nw"]) |> collect |> (y->parse.(Int,y))
                if isempty(return_keys)
                    current_net_id = 0
                else
                    current_net_id = maximum(return_keys)
                end
                for (sol_id, sol_net) in sub_sol["solution"]["nw"]
                    return_solution["solution"]["nw"]["$(current_net_id+parse(Int,sol_id))"] = sol_net
                end
            else # add solution net to return
                # Does this need to use update_solution?
                return_keys = keys(return_solution["solution"]["nw"]) |> collect |> (y->parse.(Int,y))
                if isempty(return_keys)
                    current_net_id = 0
                else
                    current_net_id = maximum(return_keys)
                end
                return_solution["solution"]["nw"]["$(current_net_id+1)"] = solution["solution"]["nw"][nw_id]
            end
        end
    end

    return return_solution
end


"get repairs in each period of the solution data"
function get_repairs(solution)
    if !_IM.ismultinetwork(solution["solution"])
        Memento.error(_PM._LOGGER, "get_repairs requires multinetwork.")
    end

    repairs = Dict{String,Array{Tuple{String,String},1}}(nw=>[] for nw in keys(solution["solution"]["nw"]))
    for (nw_id, network) in solution["solution"]["nw"]
        for comp_type in restoration_comps
            status_key = _PM.pm_component_status[comp_type]
            for (comp_id, comp) in get(network, comp_type, Dict())
                if nw_id != "0" #not items are repaired in "0", do not check in previous network for a change
                    if comp[status_key] != _PM.pm_component_status_inactive[comp_type] &&  # if comp is active
                        solution["solution"]["nw"]["$(parse(Int,nw_id)-1)"][comp_type][comp_id][status_key] == _PM.pm_component_status_inactive[comp_type] # if comp was previously inactive
                        push!(repairs[nw_id], (comp_type,comp_id))
                    end
                end
            end
        end
    end
    return repairs
end


"get a count of the repairs in each period of the solution data"
function count_repairs(solution)
    repairs = get_repairs(solution)
    repair_count = Dict{String,Int}(nw=>length(repair_list) for (nw, repair_list) in repairs )
    return repair_count
end


"get a count of the cumulative repairs in each period of the solution data"
function count_cumulative_repairs(solution)
    repair_count = count_repairs(solution)

    cumulative_count = Dict{String,Int}(nw_id=>0 for nw_id in keys(repair_count))
    end_nw_id = maximum(parse.(Int,keys(repair_count)))

    for (nw_id, count) in repair_count
        for id in parse(Int,nw_id):end_nw_id
            cumulative_count["$(id)"]+= count
        end
    end
    return cumulative_count
end



"""
    update device status and remove damaged indicator if item was repaired in network 3
    Before:
    | nw_id   |  1  |  2  |  3  |  4  |
    | ------- | --- | --- | --- | --- |
    | status  |  1  |  1  |  1  |  1  |
    | damaged |  1  |  1  |  1  |  1  |

    Repaired in network 3
    After:
    | nw_id   |  1  |  2  |  3  |  4  |
    | ------- | --- | --- | --- | --- |
    | status  |  0  |  0  |  1  |  1  |
    | damaged |  1  |  1  |  1  |  0  |
"""
function apply_repairs!(data, repairs)
    for (repair_nw_id, repair_list) in repairs
        for (comp_type, comp_id) in repair_list
            status_key = _PM.pm_component_status[comp_type]
            for (nw_id, net) in data["nw"]
                if  nw_id < repair_nw_id
                    net[comp_type][comp_id][status_key] = _PM.pm_component_status_inactive[comp_type]
                elseif nw_id > repair_nw_id
                    net[comp_type][comp_id]["damaged"] = 0
                end
            end
        end
    end
    return data
end


"""
Update sol_1 dictionary with sol_2 dictionary. `termination_status`, `primal_status`, and `dual_status`
values are the maximum of the MOI status code. `solvetime`,`objective`, and `objective_lb` are accumulated. The
`solution` dictionary is merged using `PowerModels.update_data(sol_1["solution"],sol_2["solution"])`.
"""
function update_solution!(sol_1, sol_2)
    Memento.info(_PM._LOGGER, "networks $(keys(sol_2["solution"]["nw"])) finished with status $(sol_2["termination_status"])")

    sol_1["termination_status"] = max(sol_1["termination_status"],sol_2["termination_status"])
    sol_1["primal_status"] = max(sol_1["primal_status"],sol_2["primal_status"])
    sol_1["dual_status"] = max(sol_1["dual_status"],sol_2["dual_status"])
    sol_1["solve_time"] += sol_2["solve_time"]
    sol_1["objective"] += sol_2["objective"]
    sol_1["objective_lb"] += sol_2["objective_lb"]
    _PM.update_data!(sol_1["solution"],sol_2["solution"])
end


""
function fill_missing_variables!(sol::Dict{String,<:Any}, network::Dict{String,<:Any})

    # Is there a way to do this based on formulation, any default comps?
    variable_fill = Dict(
        "bus"=>Dict{String,Any}("va"=>0.0,"status"=>0, "bus_type"=>4, "vm"=>NaN),
        "gen"=>Dict{String,Any}("gen_status"=>0,"pg"=>0.0, "qg"=>NaN),
        "branch"=>Dict{String,Any}("qf"=>NaN,"qt"=>NaN,"br_status"=>0,"pt"=>0.0,"pf"=>0.0),
        "dcline"=>Dict{String,Any}("qf"=>NaN,"qt"=>NaN,"br_status"=>0,"pt"=>0.0,"pf"=>0.0),
        "load"=>Dict{String,Any}("status"=>0.0,"qd"=>0.0,"pd"=>0.0),
        "shunt"=>Dict{String,Any}("status"=>0, "gs"=>0.0, "bs"=>0.0),
        #"storage"=>Dict{String,Any}("status"=>0) verify storage is working
    )

    for (nw_id, sol_net) in sol["solution"]["nw"]
        for (comp_type,comp_vars) in variable_fill
            for (comp_id,comp_net) in network[comp_type]
                if !(haskey(sol_net,comp_type))
                    sol_net[comp_type] = Dict{String,Any}()
                end
                if !(haskey(sol_net[comp_type], comp_id))
                    sol_net[comp_type][comp_id]=comp_vars
                end
            end
        end
    end
end

# "solve restoration using iterative period length"
# function run_iterative_restoration(network, model_constructor, optimizer; repair_periods=2, kwargs...)
#     if _IM.ismultinetwork(network)
#         Memento.error(_PM._LOGGER, "Iterative Restoration does not support multinetwork starting conditions")
#     end

#     Memento.info(_PM._LOGGER, "Iterative Restoration Algorithm starting...")
#     time_start = time()

#     ## Run initial MLD problem
#     Memento.info(_PM._LOGGER, "begin baseline Maximum Load Delivery")

#     network_mld = deepcopy(network)
#     propagate_damage_status!(network_mld)
#     set_component_inactive!(network_mld, get_damaged_items(network_mld))
#     _PM.simplify_network!(network_mld)

#     result_mld = run_mld_strg(network_mld, model_constructor, optimizer, kwargs...)

#     clean_status!(result_mld["solution"])

#     ## Turn network into multinetwork solution to merge with solution_iterative
#     mn_network_mld = _PM.replicate(result_mld["solution"], 1)
#     mn_network_mld["nw"]["0"] = mn_network_mld["nw"]["1"]
#     delete!(mn_network_mld["nw"], "1")
#     result_mld["solution"] = mn_network_mld
#     for (comp_type,status) in _PM.pm_component_status
#         if comp_type in keys(network_mld) && !(comp_type in keys(result_mld["solution"]["nw"]["0"]))
#             result_mld["solution"]["nw"]["0"][comp_type] = Dict{String,Any}()
#         end
#     end

#     Memento.info(_PM._LOGGER, "begin Iterative Restoration")
#     result_iterative = _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)
#     _merge_solution!(result_iterative, result_mld)

#     # this sets the status of components that were removed by
#     # propagate_damage_status!, set_component_inactive!, propagate_topology_status!, ...
#     for (nw,sol) in result_iterative["solution"]["nw"]
#         for (i,bus) in network["bus"]
#             init_bus = network_mld["bus"][i]
#             if bus["bus_type"] != 4 && init_bus["bus_type"] == 4
#                 sol_bus = sol["bus"][i] = get(sol["bus"], i, Dict{String,Any}("status" => 0, "va" => 0.0, "vm" => 0.0))
#                 if !haskey(sol_bus, "status")
#                     sol_bus["status"] = 0
#                 end
#             end
#         end

#         for (i,gen) in network["gen"]
#             init_gen = network_mld["gen"][i]
#             if gen["gen_status"] != 0 && init_gen["gen_status"] == 0
#                 sol_gen = sol["gen"][i] = get(sol["gen"], i, Dict{String,Any}("gen_status" => 0, "pg" => 0.0, "qg" => 0.0))
#                 if !haskey(sol_gen, "gen_status")
#                     sol_gen["status"] = 0
#                 end
#             end
#         end

#         for (i,strg) in network["storage"]
#             init_strg = network_mld["storage"][i]
#             if strg["status"] != 0 && init_strg["status"] == 0
#                 sol_storage = sol["storage"][i] = get(sol["storage"], i, Dict{String,Any}("status" => 0, "ps" => 0.0, "qs" => 0.0))
#                 if !haskey(sol_storage, "status")
#                     sol_storage["status"] = 0
#                 end
#             end
#         end

#         if haskey(sol, "branch")
#             for (i,branch) in network["branch"]
#                 init_branch = network_mld["branch"][i]
#                 if branch["br_status"] != 0 && init_branch["br_status"] == 0
#                     sol_branch = sol["branch"][i] = get(sol["branch"], i, Dict{String,Any}("br_status" => 0))
#                     if !haskey(sol_branch, "br_status")
#                         sol_branch["br_status"] = 0
#                     end
#                 end
#             end
#         else
#             # this occurs for inital solution where the MLD model does not reason over branch status
#             sol["branch"] = Dict{String,Any}()
#             for (i,branch) in network["branch"]
#                 init_branch = network_mld["branch"][i]
#                 if branch["br_status"] != 0 && init_branch["br_status"] == 0
#                     sol["branch"][i] = Dict("br_status" => 0)
#                 end
#             end
#         end
#     end

#     result_iterative["solve_time"] = time()-time_start
#     return result_iterative
# end



# function _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=2, kwargs...)
#     ## Set up network data files
#     restoration_network = replicate_restoration_network(network, count=repair_periods)

#     ## Run ROP problem with lower bound on restoration cardinality and partial load restoration
#     restoration_solution = _run_rop_ir(restoration_network, model_constructor, optimizer, kwargs...)

#     ## Was the network solved?
#     if restoration_solution["termination_status"]!= _PM.OPTIMAL && restoration_solution["termination_status"]!= _PM.LOCALLY_SOLVED
#         Memento.warn(_PM._LOGGER, "subnetwork i was not solved, returning current solution")
#         terminate_problem = true
#     else
#         terminate_problem = false
#     end

#     clean_solution!(restoration_solution)
#     _PM.update_data!(restoration_network, restoration_solution["solution"])
#     clean_status!(restoration_network)
#     _process_repair_status!(restoration_network)

#     ## do all repairs occur in one network?
#     repairs = _get_item_repairs(restoration_network)
#     terminate_recursion = count(!isempty(nw_repairs) for (nw,nw_repairs) in repairs)==1
#     if terminate_recursion
#         ## All repairs acccur in same time period: either no impact on load served, or required for feasbility
#         ## Rerun with with period for every device, with repairs fixed to final time period
#         ## This ensures that dispatches will be viable (especially storage) for the duration of the repair set

#         # save solve_time for accumulation
#         solve_time = restoration_solution["solve_time"]

#         # make a repaired devices list for processing
#         repaired_devices = Dict(comp_name=>String[] for comp_name in restoration_comps)
#         for (nw_id, list) in repairs
#             for (comp_name, comp_id) in list
#                 push!(repaired_devices[comp_name],comp_id)
#             end
#         end
#         repair_count=sum(length(comp_ids) for (comp_name,comp_ids) in repaired_devices)

#         restoration_network = replicate_restoration_network(network, count=repair_count)


#         # run multi-period restoration on this network to solve powerflow
#         restoration_solution = _run_rop_ir(restoration_network, model_constructor, optimizer, kwargs...)
#         restoration_solution["solve_time"]+=solve_time

#         # Was the network solved?
#         if restoration_solution["termination_status"]!= _PM.OPTIMAL && restoration_solution["termination_status"]!= _PM.LOCALLY_SOLVED
#             Memento.warn(_PM._LOGGER, "subnetwork i was not solved, returning current solution")
#             terminate_problem = true
#         else
#             terminate_problem = false
#         end

#         clean_solution!(restoration_solution)
#         _PM.update_data!(restoration_network, restoration_solution["solution"])
#         clean_status!(restoration_network)
#         _process_repair_status!(restoration_network)
#     end

#     # copy network metadata, remove network data. There should be a better way of doing this.
#     subnet_solution_set = deepcopy(restoration_solution)
#     subnet_solution_set["solution"]["nw"] = Dict{String,Any}()
#     # do not run restoration on network "0"
#     delete!(restoration_network["nw"],"0")

#     for(nw_id, net) in sort(Dict{Int,Any}([(parse(Int, k), v) for (k,v) in restoration_network["nw"]]))
#         net["time_elapsed"] = get(network,"time_elapsed",1.0) # is this the correct way to reset time-elapsed for each network?
#         if count_repairable_items(net) > 1 && !terminate_problem && !terminate_recursion
#             # Run another layer of recursion
#             Memento.info(_PM._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(net)) damaged items and $(count_repairable_items(net)) repairable items")

#             Memento.info(_PM._LOGGER, "Starting sub network restoration")
#             # copy global keys to create single networks
#             for k in keys(restoration_network)
#                 if k != "nw"
#                     net[k] = restoration_network[k]
#                 end
#             end
#             net["multinetwork"] = false

#             Memento.info(_PM._LOGGER, "Start recursive call")
#             subnet_solution = _run_iterative_sub_network(net, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)

#             # Rename solution nw_ids appropriately
#             last_network = isempty(subnet_solution_set["solution"]["nw"]) ? 0 : maximum(parse.(Int,keys(subnet_solution_set["solution"]["nw"])))
#             temp_solution = deepcopy(subnet_solution)
#             temp_solution["solution"]["nw"] = Dict{String,Any}()
#             for (id, net) in subnet_solution["solution"]["nw"]
#                 if id != "0"
#                     temp_solution["solution"]["nw"]["$(last_network+parse(Int,id))"] = net
#                 end
#             end
#             _merge_solution!(subnet_solution_set, temp_solution)
#         else
#             # Final recursion layer, place network in solution set
#             last_network = isempty(subnet_solution_set["solution"]["nw"]) ? 0 : maximum(parse.(Int,keys(subnet_solution_set["solution"]["nw"])))
#             subnet_solution_set["solution"]["nw"]["$(last_network+1)"] = net

#             Memento.info(_PM._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(net)) damaged items and $(count_repairable_items(net)) repairable items")
#             Memento.info(_PM._LOGGER, "sub_network does not need restoration sequencing")
#         end
#     end

#     return subnet_solution_set
# end


# "Merge solution dictionaries and accumulate solvetime and objective"
# function _merge_solution!(solution1, solution2)
#     Memento.info(_PM._LOGGER, "networks $(keys(solution2["solution"]["nw"])) finished with status $(solution2["termination_status"])")

#     solution1["termination_status"] = max(solution1["termination_status"],solution2["termination_status"])
#     solution1["primal_status"] = max(solution1["primal_status"],solution2["primal_status"])
#     solution1["dual_status"] = max(solution1["dual_status"],solution2["dual_status"])
#     solution1["solve_time"] += solution2["solve_time"]
#     solution1["objective"] += solution2["objective"]
#     solution1["objective_lb"] += solution2["objective_lb"]
#     for (nw_id, network) in solution2["solution"]["nw"]
#         solution1["solution"]["nw"][nw_id] = network
#     end
# end

# function _get_item_repairs(mn_data)
#     if !_IM.ismultinetwork(mn_data)
#         Memento.error(_PM._LOGGER, "get_item_repairs requires multinetwork.")
#     end

#     repairs = Dict{String,Array{Tuple{String,String},1}}(nw=>[] for nw in keys(mn_data["nw"]))
#     for (nw_id, network) in mn_data["nw"]
#         for comp_name in restoration_comps
#             status_key = _PM.pm_component_status[comp_name]
#             for (comp_id, comp) in get(network,comp_name,Dict())
#                 if nw_id != "0" #not items are repaired in "0", do not check in previous network for a change
#                     if comp[status_key] != _PM.pm_component_status_inactive[comp_name] &&  # if comp is active
#                         mn_data["nw"]["$(parse(Int,nw_id)-1)"][comp_name][comp_id][status_key] == _PM.pm_component_status_inactive[comp_name] # if comp was previously inactive
#                         push!(repairs[nw_id], (comp_name,comp_id))
#                     end
#                 end
#             end
#         end
#     end

#     return repairs
# end


# "Remove damage status if a device has already been repaired"
# function _process_repair_status!(mn_data)
#     if !_IM.ismultinetwork(mn_data)
#         Memento.error(_PM._LOGGER, "get_item_repairs requires multinetwork")
#     end

#     repairs = _get_item_repairs(mn_data)
#     for (nw_repair,items) in repairs
#         for (comp_name,comp_id) in items
#             for nw_network in keys(mn_data["nw"])
#                 if nw_repair < nw_network # is it still damaged in the time period the repair occurs
#                     comp = mn_data["nw"][nw_network][comp_name][comp_id]
#                     if haskey(comp,"damaged") && comp["damaged"]==1
#                         Memento.info(_PM._LOGGER, "$(comp_name) $(comp_id) was repaired at step $(nw_repair). Setting damaged state to 0 in network $(nw_network).")
#                         comp["damaged"]=0
#                     end
#                 end
#             end
#         end
#     end
# end


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

