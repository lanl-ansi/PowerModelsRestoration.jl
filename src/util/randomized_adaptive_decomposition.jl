
using DataStructures


function rad_heuristic(data, model_constructor, optimizer; kwargs...)

    ## creat stats
    iteration_counter = 0
    stats = Dict()
    stats["repair_list"] = SortedDict{Int,Array{String}}()
    stats["ENS"] = Float64[]
    stats["improvement"] = Float64[]
    stats["solve_time"] = Float64[]
    stats["termination_status"] = MathOptInterface.TerminationStatusCode[]
    stats["primal_status"] = MathOptInterface.ResultStatusCode[]

    # initial ordering (utilization heuristic)
    repair_ordering = utilization_heuristic_restoration(data)
    ens_dict = Dict(k=>sum(load["pd"] for (id,load) in data["load"]) for k in keys(repair_ordering))

    ## Update stats
    stats["repair_list"][iteration_counter] = get_repair_list(deepcopy(repair_ordering))
    iteration_counter +=1

    # Randomize paritions TODO
    network_count = length(keys(repair_ordering))
    PARTION_SIZE = 3
    partition_count = round(Int, network_count/PARTION_SIZE, RoundUp)

    # Setup information
    iterations_with_no_improvement = 0
    iteration_counter = 1
    t_start = time()

    while (iterations_with_no_improvement < 2) && ((time()-t_start) < 10.0)
    # for partition_count in [5,4,3,2]
        items_per_partition = length(repair_ordering)/partition_count

        partition_repairs = Dict{Int,Any}()
        partition_networks = Dict{Int,Any}()
        for r_id in 1:partition_count
            nw_ids = round(Int,(r_id-1)*items_per_partition)+1:round(Int,(r_id)*items_per_partition)
            r_dict = Dict(k=>String[] for (k,v) in repair_ordering["1"])
            for nw_id in nw_ids
                for (comp_type,comp_data) in r_dict
                    append!(comp_data, repair_ordering["$nw_id"][comp_type])
                end
            end
            partition_repairs[r_id]=r_dict
            partition_networks[r_id]=collect(nw_ids)
        end

        # create new ordering dict
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

            # apply repair orders appropriately
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

            # solve ROP
            repair_periods=length(network_ids)
            mn_network = _new_replicate_restoration_network(r_data, repair_periods, PowerModels._pm_global_keys)
            solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer; kwargs...)
            clean_solution!(solution)
            clean_status!(solution["solution"])

            # Collect stats
            total_load = sum(load["pd"] for (id,load) in r_data["load"])
            served_load = Dict(nwid=>0.0 for nwid in keys(solution["solution"]["nw"]) if nwid != "0" )
            for nwid in keys(served_load)
                for (id,load) in get(solution["solution"]["nw"][nwid],"load",Dict())
                    served_load[nwid] += load["pd"]
                end
            end
            new_ens = Dict(nwid=>(total_load - served_load[nwid]) for nwid in keys(served_load))

            # get old ENS values
            old_ens = Dict("$nwid"=> ens_dict["$nwid"] for nwid in network_ids)

            push!(stats["ENS"], sum(values(new_ens)))
            push!(stats["improvement"], sum(values(old_ens))-sum(values(new_ens)))
            push!(stats["solve_time"], solution["solve_time"])
            push!(stats["termination_status"], solution["termination_status"])
            push!(stats["primal_status"], solution["primal_status"])


            # insert reordered reapirs into new ordering if conditions are met
            if (solution["primal_status"]==MathOptInterface.FEASIBLE_POINT) && (sum(values(new_ens)) < sum(values(old_ens)))
                #add new repair orders
                iterations_with_no_improvement = 0
                r_repairs =  get_repairs(solution)
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
                Memento.info(_PM._LOGGER, "better order succeded")
                Memento.info(_PM._LOGGER, "new ENS: $(sum(values(new_ens)))")
                Memento.info(_PM._LOGGER, "old ENS: $(sum(values(old_ens)))")
            else
                # insert old order
                for nwid in network_ids
                    new_repair_ordering["$nwid"] = deepcopy(repair_ordering["$nwid"])
                end
                Memento.warn(_PM._LOGGER, "better order failed")
                Memento.info(_PM._LOGGER, "Primal status: $(solution["primal_status"])")
                Memento.info(_PM._LOGGER, "new ENS: $(sum(values(new_ens)))")
                Memento.info(_PM._LOGGER, "old ENS: $(sum(values(old_ens)))")
            end
        end
        iterations_with_no_improvement += 1
        Memento.info(_PM._LOGGER, "iterations_with_no_improvement: $iterations_with_no_improvement")

        repair_ordering = deepcopy(new_repair_ordering)


        # update stats
        stats["repair_list"][iteration_counter] = get_repair_list(deepcopy(repair_ordering))

        iteration_counter += 1

    end
    return repair_ordering,stats
end


function get_repair_list(restoration_order)
    repair_list = String[]
    for (nwid,net) in restoration_order
        for (comp_type, comp_keys) in net
            for comp_key in comp_keys
                push!(repair_list, string(comp_type,comp_key))
            end
        end
    end
    return repair_list
end

# ""
# function calc_unserved_load_pd(data_mn::Dict{String,Any}, net::Dict{String,Any})
#     served_load = calc_load_served_pd(data_mn)
#     total_load = sum(load["pd"] for (id,load) in net["load"])*length(keys(data_mn["nw"]))
#     return total_load-served_load
# end

# ""
# function calc_load_served_pd(data_mn::Dict{String,Any})
#     load_served = 0.0
#     for (nwid, net) in data_mn["nw"]
#         load_served+=sum(load["pd"] for (id,load) in net["load"])
#     end
#     return load_served
# end

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
        "nw" => Dict{String,Any}()
    )

    mn_data["multinetwork"] = true

    pm_sn_data_tmp = deepcopy(pm_sn_data)
    for k in global_keys
        if haskey(pm_sn_data_tmp, k)
            mn_data[k] = pm_sn_data_tmp[k]
        end

        # note this is robust to cases where k is not present in pm_sn_data_tmp
        delete!(pm_sn_data_tmp, k)
    end

    total_repairs = count_repairable_items(pm_sn_data)

    # if count > total_repairs
    #     Memento.warn(_PM._LOGGER, "More restoration steps than repairable components.  Reducing restoration steps to $(total_repairs).")
    #     count = trunc(Int,total_repairs)
    # end

    mn_data["name"] = "$(count) period restoration of $(name)"

    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(pm_sn_data_tmp)
    end

    repairs_per_period = total_repairs/count

    mn_data["nw"]["0"]["repairs"] = 0
    mn_data["nw"]["0"]["repaired_total"] = 0

    for n in 1:count
        if repairs_per_period*(n) < total_repairs
            mn_data["nw"]["$n"]["repairs"] = max(n,round(Int, repairs_per_period*n - mn_data["nw"]["$(n-1)"]["repaired_total"]))
        else
            mn_data["nw"]["$n"]["repairs"] = max(n,round(Int, total_repairs - mn_data["nw"]["$(n-1)"]["repaired_total"]))
        end

        mn_data["nw"]["$(n-1)"]["time_elapsed"] = mn_data["nw"]["$n"]["repairs"] * get(mn_data["nw"]["$(n-1)"], "time_elapsed", 1.0)
        mn_data["nw"]["$n"]["repaired_total"] = sum(mn_data["nw"]["$(nw)"]["repairs"] for nw=0:n)
    end
    mn_data["nw"]["$(count)"]["time_elapsed"] = get(mn_data["nw"]["$(count)"], "time_elapsed", 1.0)

    return mn_data
end