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

"Clear damage indicator and replace with status=0"
function clear_damage_indicator!(data::Dict{String, Any})
    if InfrastructureModels.ismultinetwork(data)
        for (i, nw_data) in data["nw"]
            _clear_damage_indicator!(nw_data)
        end
    else
        _clear_damage_indicator!(data)
    end
end

function _clear_damage_indicator!(network::Dict{String,Any})
    for (comp_name, status_key) in _PMs.pm_component_status
        for (i, comp) in get(network, comp_name, Dict())
            if haskey(comp, "damaged")
                comp["damaged"] = 0
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


"updates status in the data model with values from a sparse solution dict"
function update_status!(data::Dict{String, Any}, solution::Dict{String, Any})
    @assert InfrastructureModels.ismultinetwork(data) == InfrastructureModels.ismultinetwork(solution)

    if InfrastructureModels.ismultinetwork(solution)
        for (i, nw_sol) in solution["nw"]
            nw_data = data["nw"][i]
            _update_status!(nw_data, nw_sol)
        end
    else
        _update_status!(data, solution)
    end
end

function _update_status!(network::Dict{String,Any}, solution::Dict{String, Any})
    for (comp_name, status_key) in _PMs.pm_component_status
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
                bt = get(bus, "bus_type", 5)
                if bt == 4
                    Memento.warn(_PMs._LOGGER, "bus $(i) given status 1 but the bus_type is 4")
                else
                    bus["bus_type"] = bt
                end
            else
                @assert false
            end
        end
    end

    for (comp_name, status_key) in _PMs.pm_component_status
        for (i, comp) in get(network, comp_name, Dict())
            if haskey(comp, status_key)
                if isapprox(comp[status_key], _PMs.pm_component_status_inactive[comp_name], atol=1e-4)
                    # i.e. status= 1.05e-9, then set status=0
                    # instead of rounding, which would cause a load with status "0.2" (80% of load shed)
                    # to be set to status 0 instead.
                    comp[status_key] = _PMs.pm_component_status_inactive[comp_name]
                end
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

    clean_status!(sn_data)
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

    damage_comps = ["gen", "branch", "storage", "bus"]
    total_repairs = 0
    for comp_type in damage_comps
        comp_status_name = _PMs.pm_component_status[comp_type]
        comp_status_inactive_value = _PMs.pm_component_status_inactive[comp_type]

        for (i,comp) in sn_data[comp_type]
            if comp[comp_status_name] != comp_status_inactive_value
                total_repairs += get(comp, "damaged", 0)
            end
        end
    end

    if count >= total_repairs
        Memento.warn(_PMs._LOGGER, "More restoration steps than damaged components.  Reducing restoration steps to $(total_repairs).")
        count = trunc(Int,total_repairs)
    end

    mn_data["name"] = "$(count) period restoration of $(name)"

    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(sn_data_tmp)
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
        Memento.error(_PMs._LOGGER, "summary_restoration requires multinetwork data")
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

        load_pd = sum(isnan(load["pd"]) ? 0.0 : load["pd"] for (i,load) in network["load"] )
        load_qd = sum(isnan(load["qd"]) ? 0.0 : load["qd"] for (i,load) in network["load"])
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