"Set damage status for damaged_items in nw_data"
function damaged_items!(nw_data::Dict{String, Any}, damaged_items::Dict{String, Any})

    for id in keys(damaged_items)
        if haskey(nw_data, "nw")
            for network in nw_data["nw"]
                for i in damaged_items[id]
                    nw_data[id][i]["damaged"] = 1
                end
            end
        else
            for i in damaged_items[id]
                nw_data[id][i]["damaged"] = 1
            end
        end
    end
end


"Replace NaN and Nothing with 0 in multinetwork solutions"
function clean_solution!(solution)
    for item_type in ["gen", "storage", "branch","load","shunt"]
        if haskey(solution["solution"], "nw")
            for (n, net) in solution["solution"]["nw"]
                for (i,item) in get(net, item_type, Dict())
                    for k in keys(item)
                        if item[k] === nothing
                            item[k] = 0
                        elseif isnan(item[k])
                            item[k] = 0
                        end
                    end
                end
            end
        else
            for (i,item) in get(solution["solution"], item_type, Dict())
                for k in keys(item)
                    if item[k] === nothing
                        item[k] = 0
                    elseif isnan(item[k])
                        item[k] = 0
                    end
                end
            end
        end
    end
end


# Required because PowerModels assumes integral status values
"Replace non-integer status codes for devices, maps bus status to bus_type"
function clean_status!(data)
    if InfrastructureModels.ismultinetwork(data)
        for (i, nw_data) in data["nw"]
            _clean_status!(nw_data)
        end
    else
        _clean_status!(data)
    end
end

function _clean_status!(network)
    for (i, bus) in get(network, "bus", Dict())
        if haskey(bus, "status")
            status = bus["status"] = round(Int, bus["status"])
            if status == 0
                bus["bus_type"] = 4
            elseif status == 1
                if get(bus, "bus_type", -1) == 4
                    Memento.warn(_PMs._LOGGER, "bus $(i) given status 1 but the bus_type is 4")
                end
            else
                @assert false
            end
        end
    end

    for (comp_name, status_key) in _PMs.pm_component_status
        for (i, comp) in get(network, comp_name, Dict())
            if haskey(comp, status_key)
                comp[status_key] = round(Int, comp[status_key])
            end
        end
    end
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())
    return replicate_restoration_network(sn_data, count, union(global_keys, _PMs._pm_global_keys))
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function replicate_restoration_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String})
    @assert count > 0
    if _IMs.ismultinetwork(sn_data)
        Memento.error(_PMs._LOGGER, "replicate_restoration_network can only be used on single networks")
    end

    propagate_damage_status!(sn_data)

    name = get(sn_data, "name", "anonymous")

    mn_data = Dict{String,Any}(
        "nw" => Dict{String,Any}()
    )

    mn_data["multinetwork"] = true

    sn_data_tmp = deepcopy(sn_data)
    for k in global_keys
        if haskey(sn_data_tmp, k)
            mn_data[k] = sn_data_tmp[k]
        end

        # note this is robust to cases where k is not present in sn_data_tmp
        delete!(sn_data_tmp, k)
    end

    item_dict = Dict("gen"=>"gen_status", "branch"=>"br_status", "storage"=>"status", "bus"=>"bus_type")
    total_repairs = 0
    for (j, st) in item_dict
        for (i,item) in sn_data[j]
            if j=="bus"
                total_repairs += (get(item,"damaged",0)==1 && get(item,st,1 )!= 4) ? 1 : 0
            else
                total_repairs += get(item,"damaged",0)*get(item,st,0)
            end
        end
    end

    if count >= total_repairs
        Memento.warn(_PMs._LOGGER, "More restoration steps than damaged components.  Reducing restoration steps to $(total_repairs).")
<<<<<<< HEAD
        count = trunc(Int,total_repairs)
=======
        count = round(Int,total_repairs)
>>>>>>> Save changes for rebaseing.
    end

    mn_data["name"] = "$(count) period restoration of $(name)"

    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(sn_data_tmp)
    end

    repairs_per_period = total_repairs/count

    mn_data["nw"]["0"]["repairs"] = 0
    mn_data["nw"]["0"]["repaired_total"] = 0

    for n in 1:count
<<<<<<< HEAD
        if repairs_per_period*(n) < total_repairs 
            mn_data["nw"]["$n"]["repairs"] = round(Int, repairs_per_period*n - mn_data["nw"]["$(n-1)"]["repaired_total"])
=======
        if repairs_per_period*(n) < total_repairs
            mn_data["nw"]["$n"]["repairs"] = trunc(Int,round(repairs_per_period*n - mn_data["nw"]["$(n-1)"]["repaired_total"]))
>>>>>>> Save changes for rebaseing.
        else
            mn_data["nw"]["$n"]["repairs"] = round(Int, total_repairs - mn_data["nw"]["$(n-1)"]["repaired_total"])
        end

        mn_data["nw"]["$(n-1)"]["time_elapsed"] = mn_data["nw"]["$n"]["repairs"] * get(mn_data["nw"]["$(n-1)"], "time_elapsed", 1.0)
        mn_data["nw"]["$n"]["repaired_total"] = sum(mn_data["nw"]["$(nw)"]["repairs"] for nw=0:n)
    end
    mn_data["nw"]["$(count)"]["time_elapsed"] = get(mn_data["nw"]["$(count)"], "time_elapsed", 1.0)

    return mn_data
end

""
function propagate_damage_status!(data::Dict{String,<:Any})
    if InfrastructureModels.ismultinetwork(data)
        for (i,nw_data) in data["nw"]
            _propagate_damage_status!(nw_data)
        end
    else
        _propagate_damage_status!(data)
    end
end


""
function _propagate_damage_status!(data::Dict{String,<:Any})
    buses = Dict(bus["bus_i"] => bus for (i,bus) in data["bus"])

    incident_gen = _PMs.bus_gen_lookup(data["gen"], data["bus"])
    incident_storage = _PMs.bus_storage_lookup(data["storage"], data["bus"])

    incident_branch = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,branch) in data["branch"]
        push!(incident_branch[branch["f_bus"]], branch)
        push!(incident_branch[branch["t_bus"]], branch)
    end

    for (i,bus) in buses
        if haskey(bus, "damaged") && bus["damaged"] == 1
            for gen in incident_gen[i]
                Memento.info(_PMs._LOGGER, "damaging generator $(gen["index"]) due to damaged bus $(i)")
                gen["damaged"] = 1
            end
            for storage in incident_storage[i]
                Memento.info(_PMs._LOGGER, "damaging storage $(storage["index"]) due to damaged bus $(i)")
                storage["damaged"] = 1
            end
            for branch in incident_branch[i]
                Memento.info(_PMs._LOGGER, "damaging branch $(branch["index"]) due to damaged bus $(i)")
                branch["damaged"] = 1
            end
        end
    end

end


"""
prints a summary of a restoration solution to the terminal
"""
function print_summary_restoration(data::Dict{String,<:Any})
    summary_restoration(stdout, data)
end

"""
prints a summary of a restoration solution
"""
function summary_restoration(io::IO, data::Dict{String,<:Any})
    if !_IMs.ismultinetwork(data)
        Memento.error(_LOGGER, "summary_restoration requires multinetwork data")
    end

    networks = sort(collect(keys(data["nw"])), by=x -> parse(Int, x))
    component_names = sort(collect(keys(_PMs.pm_component_status)))

    network = data["nw"][networks[1]]
    header = ["step", "pd", "qd"]
    for comp_name in component_names
        if haskey(network, comp_name)
            components = network[comp_name]
            comp_ids = sort(collect(keys(components)), by=x -> parse(Int, x))
            for comp_id in comp_ids
                push!(header, "$(comp_name)_$(comp_id)")
            end
        end
    end
    println(io, join(header, ", "))

    for nw in networks
        network = data["nw"][nw]

        summary_data = Any[nw]

        load_pd = sum(load["pd"] for (i,load) in network["load"])
        load_qd = sum(load["qd"] for (i,load) in network["load"])
        push!(summary_data, trunc(load_pd, sigdigits=5))
        push!(summary_data, trunc(load_qd, sigdigits=5))

        for comp_name in component_names
            comp_status_name = _PMs.pm_component_status[comp_name]
            if haskey(network, comp_name)
                components = network[comp_name]
                comp_ids = sort(collect(keys(components)), by=x -> parse(Int, x))
                for comp_id in comp_ids
                    comp = components[comp_id]
                    status_value = -1
                    if haskey(comp, comp_status_name)
                        status_value = comp[comp_status_name]
                    elseif haskey(comp, "status")
                        status_value = comp["status"]
                    end
                    push!(summary_data, status_value)
                end
            end
        end

        println(io, join([string(v) for v in summary_data], ", "))
    end
end