"solve restoration using a heuristic"
function run_rop_heuristic(network_data, model_constructor, optimizer; heuristic=random_repair, kwargs...)
    heuristic(network_data)
    return run_restoration_simulation(network_data, model_constructor, optimizer; kwargs...)
end

"repair network with random repair of items"
function random_repair(network_data; repair_component_types=["gen", "branch", "storage"])

    networks = []
    if haskey(network_data, "nw")
        for n in keys(network_data["nw"])
            push!(networks, parse(Int, n))
        end
    else
        # TODO push error for non-multinetwork
    end
    networks = sort(networks)

    net1 = network_data["nw"]["$(networks[1])"]

    repair_list = Array{NamedTuple,1}()
    for item_type in repair_component_types
        for (i, item) in get(net1, item_type, Dict())
            if get(item, "damaged", 0) == 1
                push!(repair_list, (type=item_type, index=i))

            end
        end
    end

    Random.shuffle!(repair_list)

    total_repairs = length(repair_list)
    repair_periods = length(networks) - 1
    repairs_per_period = ceil(Int, total_repairs/repair_periods)

    comp_type_status = Dict("gen" => "gen_status", "branch" => "br_status", "storage" => "status")
    for n in networks
        if n > 0
            for r in 1:repairs_per_period
                if !isempty(repair_list)
                    item = pop!(repair_list)
                    for nw in networks
                        if nw >= n
                            network_data["nw"]["$nw"][item.type][item.index]["damaged"] = 0
                            network_data["nw"]["$nw"][item.type][item.index][comp_type_status[item.type]] = 1
                        else
                            network_data["nw"]["$nw"][item.type][item.index]["damaged"] = 1
                            network_data["nw"]["$nw"][item.type][item.index][comp_type_status[item.type]] = 0
                        end
                    end
                end
            end
        end
    end

end

# not developed function #
# ""
# function largest_item_repair(network_data)

#     networks = []
#     if haskey(network_data, "nw")
#         for n in keys(network_data["nw"])
#             push!(networks, parse(Int, n))
#         end
#     else
#         # TODO push error for non-multinetwork
#     end

#     total_repairs = 0 #count damaged items

#     repair_periods = length(networks)

#     repairs_per_period = ceil(Int, total_repairs/repair_periods)

#     for n in networks
#         #pick an item to repair
#     end

#     return network_data
# end
