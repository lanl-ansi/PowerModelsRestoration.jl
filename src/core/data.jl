
"supported components for restoration"
const restoration_comps = ["bus" "gen" "storage" "branch"]


"""
    count_repairable_components(network::Dict{String, <:Any})

Return the number of repairable components in a network.
"""
function count_repairable_components(network::Dict{String, <:Any})
    pm_data = _PM.get_pm_data(network)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "count_repairable_components can only be used on single networks")
    else
        repairable_set = get_repairable_components(pm_data)
        return repairable_count = sum(length(comp_ids) for (comp_name,comp_ids) in repairable_set)
    end
end


"""
    get_repairable_components(network::Dict{String, <:Any})

Return a dictionary of the repairable component indices.
A component is repairable if `"damaged"==1` and `"status"=1`

```
    julia> get_repairable_components(network)
    Dict{String, Set{String}} with 4 entries:
        "gen"     => Set(["4", "1", "2"])
        "branch"  => Set(["4", "1", "5", "2", "6", "7", "3"])
        "storage" => Set(["1"])
        "bus"     => Set(["4"])
```
"""
function get_repairable_components(data::Dict{String, <:Any})
    pm_data = _PM.get_pm_data(data)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "get_repairable_components can only be used on single networks")
    else
        return repairs =  _get_repairable_components(pm_data)
    end
end


""
function _get_repairable_components(network::Dict{String,<:Any})
    repairs = Dict{String, Set{String}}()
    for comp_name in restoration_comps
        status_key = _PM.pm_component_status[comp_name]
        repairs[comp_name] = Set()

        for (comp_id, comp) in get(network, comp_name, Dict())
            if haskey(comp, status_key) && comp[status_key] != _PM.pm_component_status_inactive[comp_name] && haskey(comp, "damaged") && comp["damaged"] == 1
                push!(repairs[comp_name], comp_id)
            end
        end
    end
    return repairs
end


"""
    damage_components!(nw_data::Dict{String,<:Any}, comp_list::Dict{String, Set{String}})

Set the damage indicator to 1 for components in the comp_list.

```
    julia> damage_components!(network, Dict("bus"=>["1","3"]))
```
"""
function damage_components!(nw_data::Dict{String,<:Any}, comp_list::Dict{String, Set{String}})
    pm_data = _PM.get_pm_data(nw_data)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "damage_components! can only be used on single networks")
    end

    for (comp_name, comp_ids) in comp_list
        for comp_id in comp_ids
            pm_data[comp_name][comp_id]["damaged"] = 1
        end
    end
    return nw_data
end


"""
    count_damaged_components(network::Dict{String, <:Any})

Count the number of components with key `"damaged" == 1`.
"""
function count_damaged_components(network::Dict{String, <:Any})
    pm_data = _PM.get_pm_data(network)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "count_damaged_components can only be used on single networks")
    else
        damaged_set = get_damaged_components(pm_data)
        return damaged_count = sum(length(comp_ids) for (comp_name,comp_ids) in damaged_set)
    end
end


"""
    get_damaged_components(network::Dict{String, <:Any})

Return a dictionary of the damaged component indices.
A component is damaged if `"damaged"==1`.

```
    julia> get_damaged_components(network)
    Dict{String, Set{String}} with 4 entries:
        "gen"     => Set(["4", "1", "2"])
        "branch"  => Set(["4", "1", "5", "2", "6", "7", "3"])
        "storage" => Set(["1"])
        "bus"     => Set(["4"])
```
"""
function get_damaged_components(data::Dict{String,<:Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "get_damaged_components can only be used on single networks")
    else
        return comp_list = _get_damaged_components(pm_data)
    end
end


""
function _get_damaged_components(network::Dict{String,<:Any})
    comp_list = Dict{String, Set{String}}()
    for comp_name in restoration_comps
        status_key = _PM.pm_component_status[comp_name]
        comp_list[comp_name] = Set()

        for (comp_id, comp) in network[comp_name]
            if haskey(comp, "damaged") && comp["damaged"] == 1
                push!(comp_list[comp_name], comp_id)
            end
        end
    end
    return comp_list
end


"""
    get_isolated_load(data::Dict{String,<:Any})

Return a set of loads that are isolated (loads connected to an inactive bus).
"""
function get_isolated_load(data::Dict{String,<:Any})
    pm_data = _PM.get_pm_data(data)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "get_isolated_load can only be used on single networks")
    end

    return load_list = _get_isolated_load(pm_data)
end


""
function _get_isolated_load(network::Dict{String,<:Any})
    load_set = Set{String}()
    bus_status =  _PM.pm_component_status["bus"]
    bus_inactive = _PM.pm_component_status_inactive["bus"]

    for (load_id, load) in network["load"]
        if haskey(network["bus"]["$(load["load_bus"])"], bus_status) &&  network["bus"]["$(load["load_bus"])"][bus_status] == bus_inactive
            push!(load_set, load_id)
        end
    end

    return load_set
end



"""
    get_inactive_components(network::Dict{String, <:Any})

Return a dictionary of the inactive component indices.
A component is inactive if its status value is 0.

```
    julia> get_inactive_components(network)
    Dict{String, Set{String}} with 4 entries:
        "gen"     => Set(["4", "1", "2"])
        "branch"  => Set(["4", "1", "5", "2", "6", "7", "3"])
        "storage" => Set(["1"])
        "bus"     => Set(["4"])
```
"""
function get_inactive_components(data::Dict{String,<:Any})
    pm_data = _PM.get_pm_data(data)

    if _IM.ismultinetwork(pm_data)
        comp_list = Dict{String,Any}("nw" => Dict{String,Any}())

        for (i, nw_data) in pm_data["nw"]
            comp_list["nw"][i] = _get_inactive_components(nw_data)
        end
    else
        comp_list = _get_inactive_components(pm_data)
    end

    return comp_list
end


""
function _get_inactive_components(network::Dict{String,<:Any})
    comp_list = Dict{String, Array{String,1}}()

    for comp_type in restoration_comps
        status_key = _PM.pm_component_status[comp_type]
        comp_list[comp_type] = []

        for (comp_id, comp) in get(network,comp_type,Dict())
            if haskey(comp, status_key) && comp[status_key] == _PM.pm_component_status_inactive[comp_type]
                push!(comp_list[comp_type], comp_id)
            end
        end
    end

    return comp_list
end


"""
    count_inactive_components(network::Dict{String, <:Any})

Count the number of components with an inactive component status.
"""
function count_inactive_components(network::Dict{String, <:Any})
    pm_data = _PM.get_pm_data(network)

    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "count_inactive_components can only be used on single networks")
    else
        inactive_set = get_inactive_components(pm_data)
        return inactive_count = sum(length(comp_ids) for (comp_name,comp_ids) in inactive_set)
    end
end


"""
    get_active_components(network::Dict{String, <:Any})

Return a dictionary of the active component indices.
A component is inactive if its status value is 1.

```
    julia> get_active_components(network)
    Dict{String, Set{String}} with 4 entries:
        "gen"     => Set(["4", "1", "2"])
        "branch"  => Set(["4", "1", "5", "2", "6", "7", "3"])
        "storage" => Set(["1"])
        "bus"     => Set(["4"])
```
"""
function get_active_components(network::Dict{String, Any})
    pm_data = _PM.get_pm_data(network)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "get_active_components can only be used on single networks")
    else
        active_components = Dict{String, Set{String}}()
        for comp_type in restoration_comps
            status_key = _PM.pm_component_status[comp_type]
            active_components[comp_type] = Set()
            for (comp_id, comp) in get(network, comp_type, Dict())
                if haskey(comp, status_key) && comp[status_key] != PowerModels.pm_component_status_inactive[comp_type]
                    push!(active_components[comp_type], comp_id)
                end
            end
        end
        return active_components
    end
end


"""
    count_active_components(network::Dict{String, <:Any})

Count the number of components with an active component status.
"""
function count_active_components(network::Dict{String, Any})
    pm_data = _PM.get_pm_data(network)
    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "count_active_components can only be used on single networks")
    else
        active_set = get_active_components(pm_data)
        return sum(length(comp_ids) for (comp_name,comp_ids) in active_set)
    end
end


"""
    make_inactive!(nw_data::Dict{String,<:Any}, comp_list::Dict{String, Set{String}})

Set the status indicator to 0 for components in the comp_list.

```
    julia> make_inactive!(network, Dict("bus"=>["1","3"]))
```
"""
function make_inactive!(network::Dict{String,<:Any}, comp_list::Dict{String, Set{String}})
    pm_data = _PM.get_pm_data(network)

    if _IM.ismultinetwork(pm_data)
        Memento.error(_PM._LOGGER, "make_inactive! can only be used on single networks")
    else
        for (comp_name, comp_ids) in comp_list
            for comp_id in comp_ids
                pm_data[comp_name][comp_id][_PM.pm_component_status[comp_name]] = _PM.pm_component_status_inactive[comp_name]
            end
        end
    end
    return network
end


"""
    clear_damage_indicator!(network::Dict{String, <:Any})

Clear damage indicator and replace with `damage=0`.
"""
function clear_damage_indicator!(data::Dict{String, <:Any})
    pm_data = _PM.get_pm_data(data)
    if _IM.ismultinetwork(pm_data)
        for (nwid,nw) in pm_data["nw"]
            _clear_damage_indicator!(nw)
        end
    else
        _clear_damage_indicator!(pm_data)
    end
end


""
function _clear_damage_indicator!(network::Dict{String,<:Any})
    for comp_name in restoration_comps
        status_key = _PM.pm_component_status[comp_name]

        for (i, comp) in get(network, comp_name, Dict())
            if haskey(comp, "damaged")
                comp["damaged"] = 0
            end
        end
    end
end


"""
    update_status!(network_1::Dict{String, <:Any}, network_2::Dict{String, <:Any})

Update the status values in network1 with values from network2. Supports sparse networks.
"""
function update_status!(network_1::Dict{String, <:Any}, network_2::Dict{String, <:Any})
    pm_data1 = _PM.get_pm_data(network_1)
    pm_data2 = _PM.get_pm_data(network_2)

    if !(_IM.ismultinetwork(pm_data1) == _IM.ismultinetwork(pm_data2))
        Memento.error(_PM._LOGGER,  "Network_1 and Network_2 must both be single networks or both be multinetworks")
    end

    if _IM.ismultinetwork(pm_data2)
        for (i, nw2_data) in pm_data2["nw"]
            nw1_data = pm_data1["nw"][i]
            _update_status!(nw1_data, nw2_data)
        end
    else
        _update_status!(pm_data1, pm_data2)
    end
end

function _update_status!(network_1::Dict{String,<:Any}, network_2::Dict{String, <:Any})
    for (comp_name, status_key) in _PM.pm_component_status
        if !haskey(network_1, comp_name)
            Memento.warn(_PM._LOGGER,  "Network_1 does not have $(comp_name) dictionary. Skipping component dictionary.")
        elseif !haskey(network_2, comp_name)
            Memento.warn(_PM._LOGGER,  "Network_2 does not have $(comp_name) dictionary. Skipping component dictionary.")
        else
            nw1_comps = network_1[comp_name]

            for (i, nw2_comp) in network_2[comp_name]
                if haskey(nw1_comps, i)
                    nw1_comp = nw1_comps[i]
                    nw1_comp[status_key] = nw2_comp[status_key]
                else
                    Memento.warn(_PM._LOGGER, "Network_1 does not have $(comp_name) $(i) but Network_2 does. Value is not copied.")
                end
            end
        end
    end
end


"""
    clean_status!(data::Dict{String,<:Any})

Replace near integer status values with integers (tol=1e-4) and set bus_type according to the status value.

Non-integer statuses may occur for due to numerical tolerance, where a component status may be reported as 1e-9 by a solver.
"""
function clean_status!(data::Dict{String,<:Any})
    pm_data = _PM.get_pm_data(data)
    if _IM.ismultinetwork(pm_data)
        for (i, pm_nw_data) in pm_data["nw"]
            _clean_status!(pm_nw_data)
        end
    else
        _clean_status!(pm_data)
    end
    return data
end


""
function _clean_status!(network::Dict{String,<:Any})
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
                    # i.e. status= 1e-5, then set status=0
                    comp[status_key] = _PM.pm_component_status_inactive[comp_name]
                elseif isapprox(comp[status_key], 1, atol=1e-4)
                    comp[status_key] = 1
                end
            end
        end
    end
end


"""
    replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())

Transforms a single network into a multinetwork with several deepcopies of the original network.
Start with nwid "0" before repairs are conducted, then `count` number of preriods where repairs are performed.
Add network keys for `repairs`, the number of repairs that are allowed in each period, and `repaired_total`, the cumulative repairs in the network.
Also add `time_elapsed` based on the number of repairs that occur in the following period.
"""
function replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())
    return replicate_restoration_network(sn_data, count, union(global_keys, _PM._pm_global_keys))
end


"""
    replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())

Transforms a single network into a multinetwork with several deepcopies of the original network.
Start with nwid "0" before repairs are conducted, then `count` number of preriods where repairs are performed.
Add network keys for `repairs`, the number of repairs that are allowed in each period, and `repaired_total`, the cumulative repairs in the network.
Also add `time_elapsed` based on the number of repairs that occur in the following period.
"""
function replicate_restoration_network(sn_data::Dict{String,<:Any}, count::Int; global_keys::Set{String}=Set{String}())
    return replicate_restoration_network(sn_data, count, union(global_keys, _PM._pm_global_keys))
end


"""
    replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1, global_keys::Set{String}=Set{String}())

Transforms a single network into a multinetwork with several deepcopies of the original network.
Start with nwid "0" before repairs are conducted, then `count` number of preriods where repairs are performed.
Add network keys for `repairs`, the number of repairs that are allowed in each period, and `repaired_total`, the cumulative repairs in the network.
Also add `time_elapsed` based on the number of repairs that occur in the following period.
"""
function replicate_restoration_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String})
    pm_sn_data = _PM.get_pm_data(deepcopy(sn_data))

    @assert count > 0
    if _IM.ismultinetwork(pm_sn_data)
        Memento.error(_PM._LOGGER, "replicate_restoration_network can only be used on single networks")
    end

    clean_status!(pm_sn_data)
    propagate_damage_status!(pm_sn_data)
    total_repairs = count_repairable_components(pm_sn_data)

    if count > total_repairs
        Memento.warn(_PM._LOGGER, "More restoration steps than repairable components.  Reducing restoration steps to $(total_repairs).")
        count = trunc(Int,total_repairs)
    end

    mn_data = Dict{String,Any}(
        "nw" => Dict{String,Any}()
    )
    mn_data["multinetwork"] = true
    mn_data["name"] = "$(count) period restoration of $(get(pm_sn_data, "name", "anonymous"))"

    pm_sn_data_tmp = deepcopy(pm_sn_data)
    for k in global_keys
        if haskey(pm_sn_data_tmp, k)
            mn_data[k] = pm_sn_data_tmp[k]
        end
        # note this is robust to cases where k is not present in pm_sn_data_tmp
        delete!(pm_sn_data_tmp, k)
    end

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


"""
    propagate_damage_status!(data::Dict{String,<:Any})

Propagate the damaged indicator from buses to indicent branches, generators, and storage"
"""
function propagate_damage_status!(network::Dict{String,<:Any})
    pm_data = _PM.get_pm_data(network)
    if _IM.ismultinetwork(pm_data)
        for (i, pm_nw_data) in pm_data["nw"]
            _propagate_damage_status!(pm_nw_data)
        end
    else
        _propagate_damage_status!(pm_data)
    end
    return network
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
    print_summary_restoration(data::Dict{String,<:Any})

prints a summary of a restoration solution to the terminal
"""
function print_summary_restoration(data::Dict{String,<:Any})
    summary_restoration(stdout, data)
end


"""
    summary_restoration(io::IO, data::Dict{String,<:Any})

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


"""
    add_load_weights!(data::Dict{String,<:Any})

Add load weights to network data. Only supports pti files.
Takes the `load_ckt` key ('l', 'm', 'h') and assigns a load `weight` key (1.0, 10.0, 100.0).
"""
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

