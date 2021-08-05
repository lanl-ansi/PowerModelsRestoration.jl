
using DataStructures


function rad_heuristic(data, model_constructor, optimizer; kwargs...)

    ## creat stats
    solution = Dict{String,Any}(
        "objective_lb" => 0.0,
        "objective" => 0.0,
        "solution" => Dict{String,Any}(),
        "solve_time" => 0.0
    )
    stats = Dict{String,Any}(
        "repair_list" => SortedDict{Int,Array{String}}(),
        "ENS" => Float64[],
        "sub_ENS" => Float64[],
        "improvement" => Float64[],
        "solve_time" => Float64[],
        "termination_status" => MathOptInterface.TerminationStatusCode[],
        "primal_status" => MathOptInterface.ResultStatusCode[]
    )

    t_start = time()

    ## initial ordering (utilization heuristic)
    repair_ordering = utilization_heuristic_restoration(data)
    ens_dict = Dict(k=>sum(load["pd"] for (id,load) in data["load"]) for k in keys(repair_ordering))

    solution["solution"] = replicate_restoration_network(data,count=length(keys(repair_ordering)))
    solution["solution"] = apply_restoration_sequence!(solution["solution"],repair_ordering)
    delete!(solution["solution"]["nw"],"0")
    # for (nwid, net) in solution["solution"]["nw"]  # preset  load to 0  for periods where solution is infeasible
    #     for (load_id,load) in net["load"]
    #         load["pd"] = 0.0
    #         load["qd"] = 0.0
    #     end
    # end


    ## Update stats
    iteration_counter = 0
    stats["repair_list"][iteration_counter] = get_repair_list(deepcopy(repair_ordering))
    iteration_counter +=1

    ## Randomize paritions settings
    network_count=length(keys(repair_ordering))
    partition_min = 2
    partition_max = 5

    ## Setup information
    iterations_with_no_improvement = 0
    iteration_counter = 1

    while (iterations_with_no_improvement < 10) && ((time()-t_start) < 1000.0)

        partitions = Int[]
        partition_count = 0
        while partition_count < network_count
            partition_range = min((network_count-partition_count),partition_min):min((network_count-partition_count),partition_max)
            push!(partitions,rand(partition_range))
            partition_count = sum(partitions)
        end

        nwids = sort([parse(Int,k) for k in keys(repair_ordering)], rev=true)
        partition_repairs = Dict{Int,Any}()
        partition_networks = Dict{Int,Any}()
        for  i in eachindex(partitions)
            partition_size = partitions[i]
            partition_networks[i] = [pop!(nwids) for j in 1:partition_size]

            partition_repairs[i] = Dict(k=>String[] for k in restoration_comps)
            for nw_id in partition_networks[i]
                for (comp_type,comp_data) in partition_repairs[i]
                    append!(comp_data, repair_ordering["$nw_id"][comp_type])
                end
            end
        end

        ## create new ordering dict
        new_repair_ordering = deepcopy(repair_ordering)
        for (nwid, nw) in new_repair_ordering
            for (comp_type,comp_ids) in nw
                empty!(comp_ids)
            end
        end

        ## Solve subperiod ROP problems
        for (r_id, repairs) in partition_repairs
            network_ids = sort(partition_networks[r_id])
            r_data = deepcopy(data)

            ## apply repair orders appropriately
            for (r_id_it, repairs_it) in partition_repairs
                if r_id_it < r_id #repaired before r_id, then status=1 damage=0
                    for (comp_type, comp_ids) in repairs_it
                        for comp_id in comp_ids
                            r_data[comp_type][comp_id]["damaged"] = 0
                        end
                    end
                elseif r_id_it > r_id # repaired after r_id status = 0
                    for (comp_type, comp_ids) in repairs_it
                        comp_status_key = PowerModels.pm_component_status[comp_type]
                        comp_status_inactive = PowerModels.pm_component_status_inactive[comp_type]
                        for comp_id in comp_ids
                            r_data[comp_type][comp_id][comp_status_key] = comp_status_inactive
                        end
                    end
                else
                     # repairs to be ordered in this stage
                end
            end

            ## solve ROP
            repair_periods=length(network_ids)
            mn_network = _new_replicate_restoration_network(r_data, repair_periods, PowerModels._pm_global_keys)
            rad_solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer; kwargs...)
            fill_missing_variables!(rad_solution, r_data) # some devices like load are removed for status 0.  E.g. ensure that load pd is zero if removed
            clean_solution!(rad_solution)
            clean_status!(rad_solution["solution"])

            ## Collect stats
            total_load = sum(load["pd"] for (id,load) in r_data["load"])
            served_load = Dict(nwid=>0.0 for nwid in keys(rad_solution["solution"]["nw"]) if nwid != "0" )
            for nwid in keys(served_load)
                for (id,load) in get(rad_solution["solution"]["nw"][nwid],"load",Dict())
                    served_load[nwid] += load["pd"]
                end
            end
            new_ens = Dict(nwid=>(total_load - served_load[nwid]) for nwid in keys(served_load))

            ## get old ENS values
            old_ens = Dict("$nwid"=> ens_dict["$nwid"] for nwid in network_ids)

            push!(stats["sub_ENS"], sum(values(new_ens)))
            push!(stats["improvement"], sum(values(old_ens))-sum(values(new_ens)))
            push!(stats["solve_time"], rad_solution["solve_time"])
            push!(stats["termination_status"], rad_solution["termination_status"])
            push!(stats["primal_status"], rad_solution["primal_status"])


            ## insert reordered reapirs into new ordering if conditions are met
            if (rad_solution["primal_status"]==MathOptInterface.FEASIBLE_POINT) && (sum(values(new_ens)) < sum(values(old_ens)))
                # add new repair orders
                iterations_with_no_improvement = 0
                r_repairs =  get_repairs(rad_solution)
                for (rr_id, repairs) in r_repairs
                    if rr_id != "0"
                        nw_id = network_ids[parse(Int,rr_id)]

                        new_repair_ordering["$nw_id"] = Dict(comp_type=>String[] for comp_type in restoration_comps)
                        for (comp_type,comp_id) in repairs
                            push!(new_repair_ordering["$nw_id"][comp_type],comp_id)
                        end
                    end
                end

                # update ens_dict with improved ens
                for (old_key,new_key) in zip(sort(parse.(Int,collect(keys(old_ens)))), sort(parse.(Int,collect(keys(new_ens)))))
                    ens_dict["$old_key"] = new_ens["$new_key"]
                end

                # update solution["solution"] dict
                for rr_id in keys(r_repairs)
                    if rr_id != "0"
                        nw_id = network_ids[parse(Int,rr_id)]
                        _PM.update_data!(solution["solution"]["nw"]["$nw_id"], rad_solution["solution"]["nw"]["$rr_id"])
                    end
                end

                Memento.info(_PM._LOGGER, "better order succeded")
                Memento.info(_PM._LOGGER, "new ENS: $(sum(values(new_ens)))")
                Memento.info(_PM._LOGGER, "old ENS: $(sum(values(old_ens)))")
            else
                # insert old order
                for nwid in network_ids
                    new_repair_ordering["$nwid"] = deepcopy(repair_ordering["$nwid"])
                end
                Memento.warn(_PM._LOGGER, "better order failed")
                Memento.info(_PM._LOGGER, "Primal status: $(rad_solution["primal_status"])")
                Memento.info(_PM._LOGGER, "new ENS: $(sum(values(new_ens)))")
                Memento.info(_PM._LOGGER, "old ENS: $(sum(values(old_ens)))")
            end
        end
        iterations_with_no_improvement += 1
        Memento.info(_PM._LOGGER, "iterations_with_no_improvement: $iterations_with_no_improvement")

        repair_ordering = deepcopy(new_repair_ordering)


        ## update stats
        stats["repair_list"][iteration_counter] = get_repair_list(deepcopy(repair_ordering))
        push!(stats["ENS"], sum(values(ens_dict)))

        iteration_counter += 1

        println((time()-t_start))
    end

    ## Collection final solution and return
    # println((time()-t_start))
    solution["stats"] = stats
    solution["repair_ordering"] = repair_ordering
    solution["solve_time"] = time()-t_start
    return solution
end


function get_repair_list(restoration_order)
    repair_list = String[]
    for nwid in sort(parse.(Int,collect(keys(restoration_order))))
        net = restoration_order["$nwid"]
        for (comp_type, comp_keys) in net
            for comp_key in comp_keys
                push!(repair_list, string(comp_type,comp_key))
            end
        end
    end
    return repair_list
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0. DOES NOT REDUCE COUNT"
function _new_replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())
    return _new_replicate_restoration_network(sn_data, count, union(global_keys, _PM._pm_global_keys))
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function _new_replicate_restoration_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String})
    pm_sn_data = _PM.get_pm_data(sn_data)

    @assert count > 0
    if _IM.ismultinetwork(pm_sn_data)
        Memento.error(_PM._LOGGER, "replicate_restoration_network can only be used on single networks")
    end

    # TODO: Make deepcopy to prevent altering input network.
    clean_status!(pm_sn_data)
    propagate_damage_status!(pm_sn_data)

    name = get(pm_sn_data, "name", "anonymous")

    mn_data = Dict{String,Any}(
        "nw" => Dict{String,Any}(),
        "multinetwork" => true
    )

    pm_sn_data_tmp = deepcopy(pm_sn_data)
    for k in global_keys
        if haskey(pm_sn_data_tmp, k)
            mn_data[k] = pm_sn_data_tmp[k]
        end

        # note this is robust to cases where k is not present in pm_sn_data_tmp
        delete!(pm_sn_data_tmp, k)
    end

    total_repairs = count_repairable_items(pm_sn_data)

    mn_data["name"] = "$(count) period restoration of $(name)"
    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(pm_sn_data_tmp)
    end

    mn_data["nw"]["0"]["repairs"] = 0
    mn_data["nw"]["0"]["repaired_total"] = 0
    for n in 1:count
        if n < count
            mn_data["nw"]["$n"]["repairs"] = n > total_repairs ? 0 : 1
        else
            mn_data["nw"]["$n"]["repairs"] = max(total_repairs-count+1,0)
        end

        mn_data["nw"]["$(n-1)"]["time_elapsed"] = mn_data["nw"]["$n"]["repairs"] * get(mn_data["nw"]["$(n-1)"], "time_elapsed", 1.0)
        mn_data["nw"]["$n"]["repaired_total"] = sum(mn_data["nw"]["$(nw)"]["repairs"] for nw=0:n)
    end
    mn_data["nw"]["$(count)"]["time_elapsed"] = get(mn_data["nw"]["$(count)"], "time_elapsed", 1.0)

    return mn_data
end