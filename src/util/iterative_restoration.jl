## Process::
# 1. take network and create XX repair periods and solve ROP.
# 2. take each single network from 1 and break into XX repair periods and solve ROP.
#       - this requires extensive rehashing of the data dict to set status values
#       - if a device is repaired after this network, the status is 0 ->seems to be set by solution builder? need to double check buses.
#       - if a device is repaired before this network, the status is 1, damaged is 0
#       - if a device is repaired in this network, the status is 1, damaged is 1
# 3. repeat 2 until the number of repairs is <= XX
# 4. report a final restoration dictionary with the order repairs (this dictionary should only contain
#     solution data from last period restoration)



# "solve restoration using iterative period length"
# function run_iterative_restoration(network, model_constructor::Type, optimizer; repair_periods=10, kwargs...)

# end


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
        # "objective_lb" => _guard_objective_bound(pm.model),
        "solve_time" => 0.0::Float64,
        "solution" => Dict{String,Any}("nw" => Dict{String,Any}(), "multinetwork" => true),
        "machine" => Dict(
            "cpu" => Sys.cpu_info()[1].model,
            "memory" => string(Sys.total_memory()/2^30, " Gb")
            ),
        "data" => replicate_restoration_network(network, count=count_damaged_items(network))
    )

    ## Set up network data files
    restoration_network = replicate_restoration_network(network, count=repair_periods)

    ## Run initial ROP problem
    # - do I just do a MLD on network "0", then use the iterative version requirsively from there?
    Memento.info(_PMs._LOGGER, "start first rop solution")
    initial_solution = run_rop(restoration_network, model_constructor, optimizer; kwargs...)
    clean_status!(initial_solution["solution"])
    _PMs.update_data!(restoration_network, initial_solution["solution"]) # will update, loads, storage, etc. between analyzing subnetworks
    Memento.info(_PMs._LOGGER, "completed first rop solution")

    update_damage_status!(restoration_network)

    ## Copy restoration nw "0" to final output and remove from temporary restoration network
    # - nw["0"] is not needed because it will not be used when we iterate ROP over the subnetworks
    # - this is should only happen at the top level of restoration, not subnetworks???
    solution["solution"]["nw"]["0"] = restoration_network["nw"]["0"]
    delete!(restoration_network["nw"],"0")

    for nw_id in 1:repair_periods #will need to add to solutio["nw"] dict in nw_id order with current implementation
        network=restoration_network["nw"]["$(nw_id)"]
        if count_damaged_items(network) > 1
            Memento.info(_PMs._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(network)) damaged items and XX repairable items")
            Memento.info(_PMs._LOGGER, "Start sub_network restoration")


            # need to add gobal keys to network first?
            for k in keys(restoration_network)
                if k != "nw"
                    network[k] = restoration_network[k]
                end
                network["multinetwork"] = false
            end

            restoration_solution = _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=repair_periods, kwargs...)

            ## append networks to current solution.
            last_network = maximum(parse.(Int,keys(solution["solution"]["nw"])))
            temp_solution = Dict{String,Any}("nw"=>Dict{String,Any}())
            for (id, net) in restoration_solution["solution"]["nw"] #i in 1:repair_periods
                if id != "0"
                    temp_solution["nw"]["$(last_network+parse(Int,id))"] = net
                end
            end

            restoration_solution["solution"] = temp_solution
            merge_solution!(solution, restoration_solution)

        else
            Memento.info(_PMs._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(network)) damaged items and XX repairable items")
            Memento.info(_PMs._LOGGER, "sub_network does not need restoration sequencing")
        end
    end

    return solution
end


function _run_iterative_sub_network(network, model_constructor, optimizer; repair_periods=2, kwargs...)

    ## Set up network data files
    restoration_network = replicate_restoration_network(network, count=repair_periods)

    ## Run ROP problem with lower bound on restoration cardinality
    pm = _PMs.instantiate_model(network, model_constructor, build_rop; multinetwork=true,
    ref_extensions=[_PMs.ref_add_on_off_va_bounds!, ref_add_damaged_items!], kwargs... )

    for (n, network) in _PMs.nws(pm)
        constraint_restoration_cardinality_lb(pm, nw=n)   
    end
    restoration_solution = _PMs.optimize_model!(pm, optimizer=optimizer, solution_builder = solution_rop!, kwargs...)

    # restoration_solution = run_rop(restoration_network, model_constructor, optimizer; kwargs...)

    clean_status!(restoration_solution["solution"])
    _PMs.update_data!(restoration_network, restoration_solution["solution"]) # will update, loads, storage, etc....
    Memento.info(_PMs._LOGGER, "completed first rop solution")

    update_damage_status!(restoration_network)
    delete!(restoration_network["nw"],"0")
    restoration_solution["solution"] = restoration_network

    return restoration_solution
end


"Merge solution dictionaries and accumulate solvetime and objective"
function merge_solution!(solution1, solution2)
    if solution2["termination_status"] == 2
        println("networks $(keys(solution2["solution"]["nw"])) failed" )
    end
    solution1["termination_status"] = max(solution1["termination_status"],solution2["termination_status"])
    solution1["primal_status"] = max(solution1["primal_status"],solution2["primal_status"])
    solution1["dual_status"] = max(solution1["dual_status"],solution2["dual_status"])
    solution1["solve_time"] += solution2["solve_time"]
    solution1["objective"] += solution2["objective"]
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


# function _update_damage_status!(network)
#     ## Set status/damage values for each time period    
#     for (nw_id, network) in network["nw"]
#         for (comp_type, comp_status) in _PMs.pm_component_status
#             for (comp_id, comp) in network[comp_type]
#                 if nw_id != "0" #not items are repaired in "0", do not check in previous network for a change
#                     if comp[comp_status] != _PMs.pm_component_status_inactive[comp_type] &&  # if comp is active
#                         network["nw"]["$(parse(Int,nw_id)-1)"][comp_type][comp_id][comp_status] != _PMs.pm_component_status_inactive[comp_type] # if comp was previously active
#                         if haskey(comp,"damaged") && comp["damaged"] == 1
#                             # therefore the comp was repaired in a former time_step, should be considered undamaged
#                             Memento.info(_PMs._LOGGER, "$(comp_type) $(comp_id) was repaired before step $(nw_id). Setting damged state to 0.")
#                             comp["damaged"] = 0
#                         end
#                     end
#                 end
#             end
#         end
#     end
# end





        # #add global keys to subnetwork
        # # temp_network = deepcopy(network) #is deepcopy needed? No because replicate_restoration_network does deepcopy
        # temp_restoration_network = replicate_restoration_network(network, count=repair_periods)
        # for k in keys(restoration_network)
        #     if k != "nw"
        #         temp_restoration_network[k] = restoration_network[k]
        #     end
        # end

        # Memento.info(_PMs._LOGGER, "Begin rop on subnetwork $(nw_id)")
        # temp_restoration = run_rop(temp_restoration_network, model_constructor, optimizer; kwargs...)
        # clean_status!(temp_restoration["solution"])
        # # update_status!(temp_restoration_network, temp_restoration["solution"])
        # _PMs.update_data!(temp_restoration_network, temp_restoration["solution"])

        # for (id, net) in temp_restoration_network["nw"] #i in 1:repair_periods
        #     # final_sol["nw"]["$((parse(Int,nw_id)-1)*repair_periods+i)"] = temp_restoration_network["nw"]["$(i)"]
        #     temp_sol["nw"]["$((parse(Int,nw_id)-1)*repair_periods+parse(Int,id))"] = net
            
        # end

        # temp_restoration["solution"] = temp_sol


    # ## set the "nw" repair period based on the iterations.
    # for (id, net) in restoration_network["nw"] #i in 1:repair_periods
    #     # final_sol["nw"]["$((parse(Int,nw_id)-1)*repair_periods+i)"] = temp_restoration_network["nw"]["$(i)"]
    #     sol["nw"]["$((parse(Int,nw_id)-1)*repair_periods+parse(Int,id))"] = net
        
    # end





        # ## Recursively run rop on subnetworks
    # temp_solution = Dict{String,Any}(
    #     "solve_time" => 0.0,
    #     "solution" => Dict{String,Any}("nw" => Dict{String,Any}(), "multinetwork" => true),
    # )
    # temp_sol = temp_solution["solution"]
    # for k in keys(restoration_network)
    #     if k != "nw"
    #         temp_sol[k] = restoration_network[k]
    #     end
    # end

    # for (nw_id, network) in restoration_network["nw"]
    #     Memento.info(_PMs._LOGGER, "Start sub_network restoration")
    #     Memento.info(_PMs._LOGGER, "sub_network $(nw_id) has $(count_damaged_items(network)) damaged items and XX repairable items")

    #     #add global keys to subnetwork
    #     # temp_network = deepcopy(network) #is deepcopy needed? No because replicate_restoration_network does deepcopy
    #     # temp_restoration_network = replicate_restoration_network(network, count=repair_periods)
    #     for k in keys(restoration_network)
    #         if k != "nw"
    #             temp_restoration_network[k] = restoration_network[k]
    #         end
    #     end

    #     Memento.info(_PMs._LOGGER, "Begin rop on subnetwork $(nw_id)")
    #     temp_restoration = run_rop(temp_restoration_network, model_constructor, optimizer; kwargs...)
    #     clean_status!(temp_restoration["solution"])
    #     # update_status!(temp_restoration_network, temp_restoration["solution"])
    #     _PMs.update_data!(temp_restoration_network, temp_restoration["solution"])

    #     for (id, net) in temp_restoration_network["nw"] #i in 1:repair_periods
    #         # final_sol["nw"]["$((parse(Int,nw_id)-1)*repair_periods+i)"] = temp_restoration_network["nw"]["$(i)"]
    #         temp_sol["nw"]["$((parse(Int,nw_id)-1)*repair_periods+parse(Int,id))"] = net
            
    #     end

    #     temp_restoration["solution"] = temp_sol
    # end





         # solution = Dict{String,Any}(
    #     # "optimizer" => JuMP.solver_name(pm.model),
    #     # "termination_status" => JuMP.termination_status(pm.model),
    #     # "primal_status" => JuMP.primal_status(pm.model),
    #     # "dual_status" => JuMP.dual_status(pm.model),
    #     # "objective" => _guard_objective_value(pm.model),
    #     # "objective_lb" => _guard_objective_bound(pm.model),
    #     "solve_time" => solve_time,
    #     "solution" => sol,
    #     "machine" => Dict(
    #         "cpu" => Sys.cpu_info()[1].model,
    #         "memory" => string(Sys.total_memory()/2^30, " Gb")
    #         ),
    #     "data" => replicate_restoration_network(network, count=count_damaged_items(network))
    # )










 # Do we need to do a full update_data! to copy over energy storage values?
    # _PMs.update_data!(initial_restoration,initial_solution["solution"])
    # solution = deepcopy(initial_solution)
    # delete!(solution,"solution")
    # delete!(solution,"data")

    # repair_sequence = item_repair_sequence(initial_solution["solution"])

    # item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")

    # for nw_id in sort(collect(keys(initial_restoration["nw"])))
    #     temp_data = deepcopy(initial_restoration["nw"][nw_id])
    #     temp_data["time_elapsed"] = temp_data["time_elapsed"]/get(get(initial_restoration["nw"],"$(parse(Int,nw_id)+1)",Dict()),"repair_count",1)

    #     for k in keys(initial_restoration)
    #         if k != "nw" && k !="multinetwork"
    #             temp_data[k] = initial_restoration[k]
    #         end
    #     end

    #     if nw_id=="0"
    #         final_restoration["nw"][nw_id] = temp_data
    #     else
    #         # Set damaged (repairable) components.
    #         repair_count = 0
    #         for (item_type, status) in item_types
    #             for (id, item) in temp_data[item_type]
    #                 if  id in repair_sequence["nw"][nw_id][item_type]
    #                     item["damaged"] = 1
    #                     item[status] = 1
    #                     repair_count+=1
    #                 else
    #                     item["damaged"] = 0
    #                 end
    #             end
    #         end

    #         if repair_count !=0
    #             # Repair replications is number of damaged componets.
    #             temp_data_mn = replicate_restoration_network(temp_data, count=repair_count)
    #             temp_solution = run_rop(temp_data_mn, model_constructor, optimizer, kwargs...)
    #             clean_status!(temp_solution["solution"])
    #             _PMs.update_data!(temp_data_mn, temp_solution)
    #             cumulative_solution_data!(solution, temp_solution)
    #             # collect results into complete restoration network.
    #             max_net_id = maximum(parse.(Int,collect(keys(final_restoration["nw"]))))
    #             for (net_id, net) in temp_data_mn["nw"]
    #                 if net_id!="0"
    #                     final_restoration["nw"]["$(parse(Int,net_id) + max_net_id)"] = net
    #                 end
    #             end
    #         end
    #     end
    # end
    # solution["solution"] = final_restoration
    # solution["data"] = final_restoration
    # return solution
    # return final_restoration


# function item_repair_sequence(network::Dict{String, Any})

#     repair_list = Dict{String, Any}()
#     repair_list["nw"] = Dict{String, Any}()

#     item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")
#     for (nw_id, net) in network["nw"]
#         network_repair = Dict{String, Any}()
#         for (type, status) in item_types
#             item_repair = String[]
#             if haskey(net, type)
#                 for (i, item) in net[type]
#                     if item[status]==1
#                         if haskey(network["nw"],"$(parse(Int,nw_id)-1)")
#                             if isapprox(network["nw"]["$(parse(Int,nw_id)-1)"][type][i][status], 0; atol=1e-4)
#                                 push!(item_repair, i)
#                             end
#                         else
#                             # Error: not all items in network are repaired
#                         end
#                     end
#                 end
#                 network_repair[type] = item_repair
#             end
#         end
#         repair_list["nw"][nw_id]=network_repair
#     end

#     return repair_list
# end

