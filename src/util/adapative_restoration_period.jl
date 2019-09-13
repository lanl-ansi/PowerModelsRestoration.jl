"solve restoration using a heuristic"
function adapative_restoration_period(network_data, model_constructor, optimizer; repair_periods=10, kwargs...)
    initial_restoration = replicate_restoration_network(network_data, count=repair_periods)
    final_restoration = Dict()

    initial_iteration = run_rop(initial_restoration, model_constructor, optimizer; kwargs...)
    _PMs.update_data!(initial_restoration,initial_iteration["solution"])
    
    repair_sequence = item_repair_sequence(initial_restoration)

    item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")

    for nw in sort(collect(keys(initial_restoration["nw"])))
        temp_data = deepcopy(initial_restoration["nw"][nw])
        # Set damaged (repairable) components.
        repair_count = 0
        for (item_type, status) in item_types
            @show item_type
            @show keys(temp_data)

            for (id, item) in temp_data[item_type]
                ## NEED TO CHANGE HOW DATA STRUCUTRE IS CREATED
                if  id in repair_sequence["nw"][nw][item_type]
                    item["damaged"] = 1
                    item[status] = 1
                    repair_count+=1
                else
                    item["damaged"] = 0
                end
            end
        end

        # Repair replications is number of damaged componets.
        replicate_restoration_network(temp_data, count=repair_count)
        temp_solution = run_rop(temp_data, model_constructor, optimizer, kwargs...)
        update_data!(temp_data, temp_solution)

        # collect results into complete restoration network. 
        if nw=="0"
            final_restoration = temp_data
            @show final_restoration["nw"]
        else
            max_net_id = maximum(parse(Int,collect(keys(final_restoration["nw"]))))
            for (net_id, net) in temp_data
                final_restoration["nw"]["$(parse(Int,net_id) + max_net_id)"] = net
            end
        end
        # account for time_elapsed and how it changes?? 
    
    end
    return final_restoration
end


function item_repair_sequence(network::Dict{String, Any})

    repair_list = Dict{String, Any}()
    repair_list["nw"] = Dict{String, Any}()

    item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")

    for (nw, net) in network["nw"]
        network_repair = Dict{String, Any}()
        for (type, status) in item_types
            item_repair = String[]
            for (i, item) in net[type]
                if item[status]==0
                    if haskey(network["nw"],"$(parse(Int,nw)+1)")
                        if network["nw"]["$(parse(Int,nw)+1)"][type][i][status]==1
                            push!(item_repair, i)
                        end
                    else
                        # Error: not all items in network are repaired
                    end
                end
            end
            network_repair[type] = item_repair

        end
        repair_list["nw"][nw]=network_repair
    end

    return repair_list
end
