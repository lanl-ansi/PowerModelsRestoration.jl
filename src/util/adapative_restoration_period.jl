using JSON

"solve restoration using a heuristic"
function adapative_restoration_period(network_data, model_constructor, optimizer; repair_periods=10, kwargs...)
    initial_restoration = replicate_restoration_network(network_data, count=repair_periods)
    final_restoration = deepcopy(initial_restoration)
    for (nw_id,nw) in final_restoration["nw"]
        final_restoration["nw"][nw_id] = Dict{String, Any}()
    end

    initial_iteration = run_rop(initial_restoration, model_constructor, optimizer; kwargs...)
    # clean_status!(initial_iteration)
    _PMs.update_data!(initial_restoration,initial_iteration["solution"])

    open("network_iteration1.json","w") do f
        JSON.print(f, initial_iteration)
    end

    repair_sequence = item_repair_sequence(initial_iteration["solution"])

    item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")

    for nw_id in sort(collect(keys(initial_restoration["nw"])))
        @show nw_id
        temp_data = deepcopy(initial_restoration["nw"][nw_id])

        if nw_id=="0"
            final_restoration["nw"][nw_id] = temp_data
        else
            # Set damaged (repairable) components.
            repair_count = 0
            for (item_type, status) in item_types
                for (id, item) in temp_data[item_type]
                    if  id in repair_sequence["nw"][nw_id][item_type]
                        item["damaged"] = 1
                        item[status] = 1
                        repair_count+=1
                    else
                        item["damaged"] = 0
                    end
                end
            end
            @show repair_sequence["nw"][nw_id]
            @show repair_count
    #         # Repair replications is number of damaged componets.
    #         replicate_restoration_network(temp_data, count=repair_count)
    #         temp_solution = run_rop(temp_data, model_constructor, optimizer, kwargs...)
    #         update_data!(temp_data, temp_solution)

    #         # collect results into complete restoration network.
    #         max_net_id = maximum(parse(Int,collect(keys(final_restoration["nw"]))))
    #         for (net_id, net) in temp_data
    #             final_restoration["nw"]["$(parse(Int,net_id) + max_net_id)"] = net
    #         end
        end
        # account for time_elapsed and how it changes??

    end
    return final_restoration
end


function item_repair_sequence(network::Dict{String, Any})

    repair_list = Dict{String, Any}()
    repair_list["nw"] = Dict{String, Any}()

    item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")
    for (nw_id, net) in network["nw"]
        network_repair = Dict{String, Any}()
        for (type, status) in item_types
            item_repair = String[]
            for (i, item) in net[type]
                if item[status]==1
                    if haskey(network["nw"],"$(parse(Int,nw_id)-1)")
                        if isapprox(network["nw"]["$(parse(Int,nw_id)-1)"][type][i][status], 0)
                            push!(item_repair, i)
                        end
                    else
                        # Error: not all items in network are repaired
                    end
                end
            end
            network_repair[type] = item_repair

        end
        repair_list["nw"][nw_id]=network_repair
    end

    return repair_list
end
