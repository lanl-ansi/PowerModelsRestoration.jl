

function rad_heuristic(data, model_constructor, optimizer; kwargs...)

    # initial ordering (utilization heuristic)
    repair_ordering = utilization_heuristic_restoration(data)

    # for different paritions until complete
    for partition_count in [4,3,2]
        display(repair_ordering)
        items_per_partition = length(repair_ordering)/partition_count

        partition_repairs = Dict{Int,Any}()
        for r_id in 1:partition_count
            nw_ids = round(Int,(r_id-1)*items_per_partition)+1:round(Int,(r_id)*items_per_partition)
            r_dict = Dict(k=>String[] for (k,v) in repair_ordering["1"])
            for nw_id in nw_ids
                for (comp_type,comp_data) in r_dict
                    append!(comp_data, repair_ordering["$nw_id"][comp_type])
                end
            end
            partition_repairs[r_id]=r_dict
        end
        # @show parition_repairs

        ## Solve subperiod ROP problems
        new_repair_ordering = Dict{String,Any}()
        for (r_id, repairs) in partition_repairs
            r_data = deepcopy(data)

            # apply repair orders approraityle
            for (r_id_it, repairs_it) in partition_repairs
                if r_id_it < r_id #repaired before r_id, then status =1 damage = 0
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
                     # repairs to be order in this stage
                end
            end

            # solve ROP
            repair_periods=count_repairable_items(r_data)
            mn_network = replicate_restoration_network(r_data, repair_periods, PowerModels._pm_global_keys)
            solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer; kwargs...)
            println(solution["termination_status"])
            clean_status!(solution["solution"])

            @show count_repairable_items(r_data)
            @show round(Int,(r_id-1)*items_per_partition)

            # insert reordered reapirs into  reapirs
            r_repairs =  get_repairs(solution)
            for (rr_id, repairs) in r_repairs
                if rr_id != "0"
                    nw_id = round(Int,(r_id-1)*items_per_partition)+parse(Int,rr_id)

                    new_repair_ordering["$nw_id"] = Dict(comp_type=>String[] for comp_type in restoration_comps)
                    for (comp_type,comp_id) in repairs
                        push!(new_repair_ordering["$nw_id"][comp_type],comp_id)
                    end
                end
            end
        end
        repair_ordering = deepcopy(new_repair_ordering)
        display(repair_ordering)
    end
    return repair_ordering
end
