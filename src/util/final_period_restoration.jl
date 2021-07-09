
"Return repair order where all repairs occur in final time period."
function final_period_restoration(network::Dict{String,<:Any})
    dmg_count = count_damaged_items(network)
    dmg_items = get_damaged_items(network)

    solution = Dict{String,Any}()
    solution["solution"]= Dict{String,Any}()
    solution["solution"]["nw"] = Dict{String,Any}()

    for nw in 1:(dmg_count-1)
        solution["solution"]["nw"]["$nw"] = Dict{String,Any}()
        for (comp_type, comp_status) in _PM.pm_component_status
            if haskey(network, comp_type)
                solution["solution"]["nw"]["$nw"][comp_type] = Dict{String,Any}()
                for (comp_id,comp) in network[comp_type]
                    solution["solution"]["nw"]["$nw"][comp_type][comp_id] = Dict{String,Any}()
                     status =  !haskey(dmg_items, comp_type) ? 1 : 
                             comp_id in dmg_items[comp_type] ? 0 : 1
                    solution["solution"]["nw"]["$nw"][comp_type][comp_id][comp_status] = status
                    if comp_type == "bus"
                        solution["solution"]["nw"]["$nw"][comp_type][comp_id]["status"] = status
                        solution["solution"]["nw"]["$nw"][comp_type][comp_id][comp_status] = Bool(status) ? 5 : 4
                    end
                end
            end
        end

        solution["solution"]["nw"]["$nw"]["load"] = Dict{String,Any}()
        for (load_id,load) in network["load"]
            solution["solution"]["nw"]["$nw"]["load"][load_id] = Dict{String,Any}()
            solution["solution"]["nw"]["$nw"]["load"][load_id]["pd"] = 0.0
            solution["solution"]["nw"]["$nw"]["load"][load_id]["status"] = 0
        end
    end

    ## Full repairs in final period
    nw = dmg_count
    solution["solution"]["nw"]["$nw"] = Dict{String,Any}()
    for (comp_type, comp_status) in _PM.pm_component_status
        if haskey(network, comp_type)
            solution["solution"]["nw"]["$nw"][comp_type] = Dict{String,Any}()
            for (comp_id,comp) in network[comp_type]
                solution["solution"]["nw"]["$nw"][comp_type][comp_id] = Dict{String,Any}()
                solution["solution"]["nw"]["$nw"][comp_type][comp_id][comp_status] = 1
                if comp_type == "bus"
                    solution["solution"]["nw"]["$nw"][comp_type][comp_id]["status"] = 1
                    solution["solution"]["nw"]["$nw"][comp_type][comp_id][comp_status] = 5
                end
            end
        end
    end

    solution["solution"]["nw"]["$nw"]["load"] = Dict{String,Any}()
    for (load_id,load) in network["load"]
        solution["solution"]["nw"]["$nw"]["load"][load_id] = Dict{String,Any}()
        solution["solution"]["nw"]["$nw"]["load"][load_id]["pd"] = load["pd"]
        solution["solution"]["nw"]["$nw"]["load"][load_id]["status"] = 1
    end

    return solution
end