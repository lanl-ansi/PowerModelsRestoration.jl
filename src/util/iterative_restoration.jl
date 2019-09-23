"solve restoration using iterative period length"
function run_iterative_restoration(network_data, model_constructor, optimizer; repair_periods=10, kwargs...)
    initial_restoration = replicate_restoration_network(network_data, count=repair_periods)
    final_restoration =  Dict{String,Any}("nw" => Dict{String,Any}())
    final_restoration["multinetwork"] = true

    for k in keys(initial_restoration)
        if k != "nw"
            final_restoration[k] = initial_restoration[k]
        end
    end

    initial_solution = run_rop(initial_restoration, model_constructor, optimizer; kwargs...)
    clean_status!(initial_solution)
    _PMs.update_data!(initial_restoration,initial_solution["solution"])
    solution = deepcopy(initial_solution)
    delete!(solution,"solution")
    delete!(solution,"data")

    repair_sequence = item_repair_sequence(initial_solution["solution"])

    item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")

    for nw_id in sort(collect(keys(initial_restoration["nw"])))
        temp_data = deepcopy(initial_restoration["nw"][nw_id])
        temp_data["time_elapsed"] = temp_data["time_elapsed"]/get(get(initial_restoration["nw"],"$(parse(Int,nw_id)+1)",Dict()),"repair_count",1)

        for k in keys(initial_restoration)
            if k != "nw" && k !="multinetwork"
                temp_data[k] = initial_restoration[k]
            end
        end

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

            # Repair replications is number of damaged componets.
            temp_data_mn = replicate_restoration_network(temp_data, count=repair_count)
            temp_solution = run_rop(temp_data_mn, model_constructor, optimizer, kwargs...)
            clean_status!(temp_solution["solution"])
            _PMs.update_data!(temp_data_mn, temp_solution)

            # collect results into complete restoration network.
            max_net_id = maximum(parse.(Int,collect(keys(final_restoration["nw"]))))
            for (net_id, net) in temp_data_mn["nw"]
                if net_id!="0"
                    final_restoration["nw"]["$(parse(Int,net_id) + max_net_id)"] = net
                end
            end
        end
    end
    solution["solution"] = final_restoration
    solution["data"] = final_restoration
    return solution
end


function item_repair_sequence(network::Dict{String, Any})

    repair_list = Dict{String, Any}()
    repair_list["nw"] = Dict{String, Any}()

    item_types = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"status")
    for (nw_id, net) in network["nw"]
        network_repair = Dict{String, Any}()
        for (type, status) in item_types
            item_repair = String[]
            if haskey(net, type)
                for (i, item) in net[type]
                    if item[status]==1
                        if haskey(network["nw"],"$(parse(Int,nw_id)-1)")
                            if isapprox(network["nw"]["$(parse(Int,nw_id)-1)"][type][i][status], 0; atol=1e-4)
                                push!(item_repair, i)
                            end
                        else
                            # Error: not all items in network are repaired
                        end
                    end
                end
                network_repair[type] = item_repair
            end
        end
        repair_list["nw"][nw_id]=network_repair
    end

    return repair_list
end

function cumulative_solution_data!(solution1, solution2)
    solution1["solve_time"] += solution2["solve_time"]
    solution1["objective"] += solution2["objective"]
end
