

"Take a sn powermodels dict and constrcut a utilization based restoration utilizatio based
heuristic repair ordering"
function utilization_heuristic_restoration(data::Dict{String,<:Any})
    if _IM.ismultinetwork(data)
        Memento.error(_PM._LOGGER, "utilization_heuristic_restoration requires a single network.")
    end

    d_comp_vec = vcat([[(comp_type,comp_id) for comp_id in comp_ids] for (comp_type,comp_ids) in get_damaged_items(data)]...)
    d_comp_cost = [util_value(data,comp_type,comp_id) for (comp_type,comp_id) in d_comp_vec]
    d_comp_vec = [d_comp_vec[i] for i in sortperm(d_comp_cost)] # reordered damaged component vector

    # create repair order structure
    restoration_order = Dict{String,Any}(
        "$id"=>Dict(d_comp_vec[id][1]=>[d_comp_vec[id][2]]) for id in 1:length(d_comp_vec)
    )

    return restoration_order
end

function util_value(data::Dict{String,<:Any}, comp_type::String, comp_id::String)
    if comp_type=="branch"
        return util_value_branch(data,comp_id)
    elseif comp_type=="gen"
        return util_value_gen(data,comp_id)
    elseif comp_type=="bus"
        return util_value_bus(data,comp_id)
    elseif comp_type=="storage"
        return util_value_storage(data,comp_id)
    else
        Memento.error(_PM._LOGGER, "Component $comp_type does not have a supported utilization cost. Setting cost to NaN")
        return 0.0
    end
end

function util_value_branch(data::Dict{String,<:Any}, comp_id::String)
    return data["branch"][comp_id]["rate_a"]
end

function util_value_gen(data::Dict{String,<:Any}, comp_id::String)
    return data["gen"][comp_id]["pmax"]
end

function util_value_bus(data::Dict{String,<:Any}, comp_id::String)
    bus_load = 0.0 # this is orders of mag slower than the other util_value functions
    for (load_id,load) in data["load"]
        if load["load_bus"]==parse(Int,comp_id::String)
            bus_load+=load["pd"]
        end
    end
    return bus_load
end

function util_value_storage(data::Dict{String,<:Any}, comp_id::String)
    return data["storage"][comp_id]["energy"]
end
