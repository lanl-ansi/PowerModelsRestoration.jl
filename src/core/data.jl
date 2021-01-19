function count_repairable_items(data::Dict{String, Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        repairable_count = Dict{String,Any}("nw" => Dict{String,Any}())
        repairable_set = get_repairable_items(pm_data)
        repairable_count["nw"] = Dict{String,Any}(nw => sum(length(comp_ids) for (comp_type,comp_ids) in repariable_network) for (nw, repariable_network) in repairable_set["nw"] )
    else
        repairable_set = get_repairable_items(pm_data)
        return repairable_count = sum(length(comp_ids) for (comp_type,comp_ids) in repairable_set)
    end
    return repairable_count
end


""
function get_repairable_items(data::Dict{String, Any})
    pm_data = _PM.get_pm_data(data)

    if haskey(pm_data, "multinetwork") && pm_data["multinetwork"] == true
        repairs = Dict{String,Any}("nw"=>Dict{String,Any}())
        for (nw, net) in pm_data["nw"]
            repairs["nw"][nw] = _get_repairable_items(net)
        end
    else
        repairs =  _get_repairable_items(pm_data)
    end

    return repairs
end


""
function _get_repairable_items(network::Dict{String,Any})
    repairs = Dict{String, Vector{String}}()

    for (comp_name, status_key) in _PM.pm_component_status
        repairs[comp_name] = []
        for (comp_id, comp) in get(network, comp_name, Dict())
            if haskey(comp, status_key) && comp[status_key] != _PM.pm_component_status_inactive[comp_name] && haskey(comp, "damaged") && comp["damaged"] == 1
                push!(repairs[comp_name], comp_id)
            end
        end
    end

    return repairs
end


"Set damage status for damaged_items in nw_data"
function damage_items!(nw_data::Dict{String,<:Any}, comp_list::Dict{String, Array{String,1}})
    for (comp_name, comp_ids) in comp_list
        for comp_id in comp_ids
            if haskey(nw_data, "multinetwork") && nw_data["multinetwork"] == true
                for (nw, network) in nw_data["nw"]
                    network[comp_name][comp_id]["damaged"] = 1
                end
            else
                nw_data[comp_name][comp_id]["damaged"] = 1
            end
        end
    end
end


"Count the number of items with a key \"damaged\" == 1 in a network"
function count_damaged_items(data::Dict{String, Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        damaged_count = Dict{String,Any}("nw" => Dict{String,Any}())
        damaged_set = get_damaged_items(pm_data)
        damaged_count["nw"] = Dict{String,Any}(nw => sum(length(comp_ids) for (comp_type,comp_ids) in damage_network) for (nw, damage_network) in damaged_set["nw"] )
    else
        damaged_set = get_damaged_items(pm_data)
        damaged_count = sum(length(comp_ids) for (comp_type,comp_ids) in damaged_set)
    end

    return damaged_count
end


""
function get_damaged_items(data::Dict{String,Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        comp_list = Dict{String,Any}("nw" => Dict{String,Any}())
        for (i, nw_data) in pm_data["nw"]
            comp_list["nw"][i] = _get_damaged_items(nw_data)
        end
    else
        comp_list = _get_damaged_items(pm_data)
    end
    
    return comp_list
end


""
function _get_damaged_items(network::Dict{String,Any})
    comp_list = Dict{String, Array{String,1}}()
    for (comp_type, comp_status) in _PM.pm_component_status
        comp_list[comp_type] = []
        for (comp_id, comp) in network[comp_type]
            if haskey(comp, "damaged") && comp["damaged"] == 1
                push!(comp_list[comp_type], comp_id)
            end
        end
    end
    return comp_list
end


""
function get_isolated_load(data::Dict{String,Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        load_list = Dict{String,Any}("nw" => Dict{String,Any}())
        for (i, nw_data) in pm_data["nw"]
            load_list["nw"][i] = _get_isolated_load(nw_data)
        end
    else
        load_list = _get_isolated_load(pm_data)
    end

    return load_list
end


""
function _get_isolated_load(network::Dict{String,Any})
    load_list =  Dict{String, Array{String,1}}()
    load_list["load"] = []

    bus_status =  _PM.pm_component_status["bus"]
    bus_inactive = _PM.pm_component_status_inactive["bus"]

    load_status = _PM.pm_component_status["load"]
    load_inactive = _PM.pm_component_status_inactive["load"]

    for (load_id, load) in network["load"]
        if haskey(network["bus"]["$(load["load_bus"])"], bus_status) &&  network["bus"]["$(load["load_bus"])"][bus_status] == bus_inactive
            push!(load_list["load"], load_id)
        end
    end
    return load_list
end


""
function set_component_inactive!(data::Dict{String,Any}, comp_list::Dict{String, Array{String,1}})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        items = Dict{String,Any}("nw" => Dict{String,Any}())
        for (i, nw_data) in pm_data["nw"]
            _set_component_inactive!(nw_data, comp_list)
        end
    else
        _set_component_inactive!(pm_data, comp_list)
    end

    return comp_list
end


""
function _set_component_inactive!(network::Dict{String,Any}, comp_list::Dict{String, Array{String,1}})
    for (comp_type, comp_ids) in comp_list
        for comp_id in comp_ids
            network[comp_type][comp_id][_PM.pm_component_status[comp_type]] = _PM.pm_component_status_inactive[comp_type]
        end
    end
end


"Clear damage indicator and replace with status=0"
function clear_damage_indicator!(data::Dict{String, Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        for (i, nw_data) in pm_data["nw"]
            _clear_damage_indicator!(nw_data)
        end
    else
        _clear_damage_indicator!(pm_data)
    end
end


function _clear_damage_indicator!(network::Dict{String,Any})
    for (comp_name, status_key) in _PM.pm_component_status
        for (i, comp) in get(network, comp_name, Dict())
            if haskey(comp, "damaged")
                comp["damaged"] = 0
            end
        end
    end
end


"Replace NaN and Nothing with 0 in multinetwork solutions"
function clean_solution!(solution::Dict{String,Any})
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


"updates status in the data model with values from a sparse solution dict"
function update_status!(data::Dict{String, Any}, solution::Dict{String, Any})
    pm_data = _PM.get_pm_data(data)

    @assert _IM.ismultinetwork(pm_data) == _IM.ismultinetwork(solution)

    if _IM.ismultinetwork(solution)
        for (i, nw_sol) in solution["nw"]
            nw_data = pm_data["nw"][i]
            _update_status!(nw_data, nw_sol)
        end
    else
        _update_status!(pm_data, solution)
    end
end

function _update_status!(network::Dict{String,Any}, solution::Dict{String, Any})
    for (comp_name, status_key) in _PM.pm_component_status
        if haskey(solution, comp_name) && haskey(network, comp_name)
            nw_comps = network[comp_name]
            for (i, sol_comp) in solution[comp_name]
                nw_comp = nw_comps[i]
                nw_comp[status_key] = sol_comp[status_key]
            end
        else
            #TODO throw warning
        end
    end
end


#=
"updates load and shunt demands, assumes these are continuous control parameters"
function update_demand!(data::Dict{String, Any}, solution::Dict{String, Any})
    @assert InfrastructureModels.ismultinetwork(data) == InfrastructureModels.ismultinetwork(solution)

    if InfrastructureModels.ismultinetwork(solution)
        for (i, nw_sol) in solution["nw"]
            nw_data = data["nw"][i]
            _update_demand!(nw_data, nw_sol)
        end
    else
        _update_demand!(data, solution)
    end
end

function _update_demand!(network::Dict{String,Any}, solution::Dict{String, Any})
    if haskey(solution, "load") && haskey(network, "load")
        nw_loads = network["load"]
        for (i, sol_load) in solution["load"]
            nw_load = nw_loads[i]
            if !isnan(sol_load["pd"])
                nw_load["pd"] = sol_load["pd"]
            end
            if !isnan(sol_load["qd"])
                nw_load["qd"] = sol_load["qd"]
            end
        end
    else
        #TODO throw warning
    end

    if haskey(solution, "shunt") && haskey(network, "shunt")
        nw_shunts = network["shunt"]
        for (i, sol_shunt) in solution["shunt"]
            nw_shunt = nw_shunts[i]
            if !isnan(sol_shunt["gs"])
                nw_shunt["gs"] = sol_shunt["gs"]
            end
            if !isnan(sol_shunt["bs"])
                nw_shunt["bs"] = sol_shunt["bs"]
            end
        end
    else
        #TODO throw warning
    end
end
=#


# Required because PowerModels assumes integral status values
"Replace non-integer status codes for devices, maps bus status to bus_type"
function clean_status!(data::Dict{String,Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        for (i, pm_nw_data) in pm_data["nw"]
            _clean_status!(pm_nw_data)
        end
    else
        _clean_status!(pm_data)
    end
end

function _clean_status!(network::Dict{String,Any})
    for (i, bus) in get(network, "bus", Dict())
        if haskey(bus, "status")
            status = bus["status"] = round(Int, bus["status"])
            if status == 0
                bus["bus_type"] = 4
            elseif status == 1
                bt = get(bus, "bus_type", 5)
                if bt == 4
                    Memento.warn(_PM._LOGGER, "bus $(i) given status 1 but the bus_type is 4")
                else
                    bus["bus_type"] = bt
                end
            else
                @assert false
            end
        end
    end

    for (comp_name, status_key) in _PM.pm_component_status
        for (i, comp) in get(network, comp_name, Dict())
            if haskey(comp, status_key)
                if isapprox(comp[status_key], _PM.pm_component_status_inactive[comp_name], atol=1e-4)
                    # i.e. status= 1.05e-9, then set status=0
                    # instead of rounding, which would cause a load with status "0.2" (80% of load shed)
                    # to be set to status 0 instead.
                    comp[status_key] = _PM.pm_component_status_inactive[comp_name]
                elseif isapprox(comp[status_key], 1, atol=1e-4)
                    comp[status_key] = 1
                end
            end
        end
    end
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())
    return replicate_restoration_network(sn_data, count, union(global_keys, _PM._pm_global_keys))
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function replicate_restoration_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String})
    pm_sn_data = _PM.get_pm_data(sn_data)

    @assert count > 0
    if _IM.ismultinetwork(pm_sn_data)
        Memento.error(_PM._LOGGER, "replicate_restoration_network can only be used on single networks")
    end

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

    if count > total_repairs
        Memento.warn(_PM._LOGGER, "More restoration steps than repairable components.  Reducing restoration steps to $(total_repairs).")
        count = trunc(Int,total_repairs)
    end

    mn_data["name"] = "$(count) period restoration of $(name)"

    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(pm_sn_data_tmp)
    end

    repairs_per_period = total_repairs/count

    mn_data["nw"]["0"]["repairs"] = 0
    mn_data["nw"]["0"]["repaired_total"] = 0

    for n in 1:count
        if repairs_per_period*(n) < total_repairs
            mn_data["nw"]["$n"]["repairs"] = round(Int, repairs_per_period*n - mn_data["nw"]["$(n-1)"]["repaired_total"])
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
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        for (i, pm_nw_data) in pm_data["nw"]
            _propagate_damage_status!(pm_nw_data)
        end
    else
        _propagate_damage_status!(pm_data)
    end
end


""
function _propagate_damage_status!(data::Dict{String,<:Any})
    buses = Dict(bus["bus_i"] => bus for (i,bus) in data["bus"])

    incident_gen = _PM.bus_gen_lookup(data["gen"], data["bus"])
    incident_storage = _PM.bus_storage_lookup(data["storage"], data["bus"])

    incident_branch = Dict(bus["bus_i"] => [] for (i,bus) in data["bus"])
    for (i,branch) in data["branch"]
        push!(incident_branch[branch["f_bus"]], branch)
        push!(incident_branch[branch["t_bus"]], branch)
    end

    for (i,bus) in buses
        if haskey(bus, "damaged") && bus["damaged"] == 1
            for gen in incident_gen[i]
                if !(haskey(gen, "damaged") && gen["damaged"] == 1)
                    Memento.info(_PM._LOGGER, "damaging generator $(gen["index"]) due to damaged bus $(i)")
                    gen["damaged"] = 1
                end
            end
            for storage in incident_storage[i]
                if !(haskey(storage, "damaged") && storage["damaged"] == 1)
                    Memento.info(_PM._LOGGER, "damaging storage $(storage["index"]) due to damaged bus $(i)")
                    storage["damaged"] = 1
                end
            end
            for branch in incident_branch[i]
                if !(haskey(branch, "damaged") && branch["damaged"] == 1)
                    Memento.info(_PM._LOGGER, "damaging branch $(branch["index"]) due to damaged bus $(i)")
                    branch["damaged"] = 1
                end
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
    pm_data = _PM.get_pm_data(data)

    if !_IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "summary_restoration requires multinetwork data")
    end

    networks = sort(collect(keys(pm_data["nw"])), by=x -> parse(Int, x))
    component_names = sort(collect(keys(_PM.pm_component_status)))

    network = pm_data["nw"][networks[1]]
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
        network = pm_data["nw"][nw]

        summary_data = Any[nw]

        load_pd = sum(isnan(load["pd"]) ? 0.0 : load["pd"] for (i,load) in network["load"] )
        load_qd = sum(isnan(load["qd"]) ? 0.0 : load["qd"] for (i,load) in network["load"])
        push!(summary_data, trunc(load_pd, sigdigits=5))
        push!(summary_data, trunc(load_qd, sigdigits=5))

        for comp_name in component_names
            comp_status_name = _PM.pm_component_status[comp_name]
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


function add_load_weights!(data::Dict{String,<:Any})
    pm_data = _PM.get_pm_data(data)

    if !haskey(pm_data, "source_type") || pm_data["source_type"] != "pti"
        Memento.warn(_PM._LOGGER, "add_load_weights! currently only supports networks from pti files")
        return
    end

    for (i,load) in pm_data["load"]
        @assert(haskey(load, "source_id") && length(load["source_id"]) == 3)
        load_ckt = lowercase(load["source_id"][3])
        if startswith(load_ckt, 'l')
            Memento.info(_PM._LOGGER, "setting load $(i) to low priority")
            load["weight"] = 1.0
        elseif startswith(load_ckt, 'm')
            Memento.info(_PM._LOGGER, "setting load $(i) to medium priority")
            load["weight"] = 10.0
        elseif startswith(load_ckt, 'h')
            Memento.info(_PM._LOGGER, "setting load $(i) to high priority")
            load["weight"] = 100.0
        end
    end
end

