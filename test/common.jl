# helper functions

""
function build_mn_data(base_data::String; replicates::Int=2)
    mp_data = PowerModels.parse_file(base_data)
    return replicate_restoration_network(mp_data, count=replicates)
end


""
function build_mn_data(mp_data::Dict{String,Any}; replicates::Int=2)
    return replicate_restoration_network(mp_data, count=replicates)
end


""
function gen_status(result, nw_id, gen_id)
    return result["solution"]["nw"][nw_id]["gen"][gen_id]["gen_status"]
end

""
function gen_status(result, gen_id)
    return result["solution"]["gen"][gen_id]["gen_status"]
end


""
function storage_status(result, nw_id, storage_id)
    return result["solution"]["nw"][nw_id]["storage"][storage_id]["status"]
end

""
function storage_status(result, storage_id)
    return result["solution"]["storage"][storage_id]["status"]
end


""
function bus_status(result, nw_id, bus_id)
    return result["solution"]["nw"][nw_id]["bus"][bus_id]["status"]
end

""
function bus_status(result, bus_id)
    return result["solution"]["bus"][bus_id]["status"]
end

""
function bus_status(result, bus_id)
    return result["solution"]["bus"][bus_id]["status"]
end

""
function branch_status(result, nw_id, branch_id)
    return result["solution"]["nw"][nw_id]["branch"][branch_id]["br_status"]
end

""
function branch_status(result, branch_id)
    return result["solution"]["branch"][branch_id]["br_status"]
end


""
function load_status(result, nw_id, load_id)
    return result["solution"]["nw"][nw_id]["load"][load_id]["status"]
end


""
function shunt_status(result, nw_id, shunt_id)
    return result["solution"]["nw"][nw_id]["shunt"][shunt_id]["status"]
end


""
function gen_power(result, nw_id::String, gen_id::String)
    value = result["solution"]["nw"][nw_id]["gen"][gen_id]["pg"]
    if isnan(value)
        return 0.0
    else
        return value
    end
end


""
function gen_power(result, nw_id::String, gen_ids::Array{String,1})
    return sum(gen_power(result, nw_id, gen_id) for gen_id in gen_ids)
end


""
function load_power(result, nw_id::String, load_id::String)
    net = get(result["solution"]["nw"],nw_id, 0)
    if net != 0
        load = get(net["load"],load_id, 0)
        if load != 0 && load["pd"] !==NaN
            return load["pd"]
        end
    end
    return 0
end


""
function load_power(result, nw_id::String, load_ids::Array{String,1})
    return sum(load_power(result, nw_id, load_id) for load_id in load_ids)
end


""
function storage_power(result, nw_id::String, storage_id::String)
    value = result["solution"]["nw"][nw_id]["storage"][storage_id]["ps"]
    if isnan(value)
        return 0.0
    else
        return value
    end
end


""
function storage_power(result, nw_id::String, storage_ids::Array{String,1})
    return sum(storage_power(result, nw_id, storage_id) for storage_id in storage_ids)
end
