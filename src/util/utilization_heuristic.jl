

"Take a sn powermodels dict and constrcut a utilization based restoration utilizatio based
heuristic repair ordering"
function utilization_heuristic_restoration(data::Dict{String,<:Any})
    if _IM.ismultinetwork(data)
        Memento.error(_PM._LOGGER, "utilization_heuristic_restoration requires a single network.")
    end

    d_comp_vec = vcat([[(comp_type,comp_id) for comp_id in comp_ids] for (comp_type,comp_ids) in get_repairable_items(data)]...)
    d_comp_cost = [util_value(data,comp_type,comp_id) for (comp_type,comp_id) in d_comp_vec]
    d_comp_vec = [d_comp_vec[i] for i in sortperm(d_comp_cost)] # reordered damaged component vector


    restoration_period = Dict{Tuple{String, String},Any}(
        (d_comp_vec[id])=>id for id in 1:length(d_comp_vec)
    )

    # Create precedent repair requirements
    repair_constraints = calculate_repair_precedance(data)
    # apply precendet repair requirments
    updated = true
    while updated
        updated = false
        for (r_comp, precedance_comps) in repair_constraints
            if r_comp in d_comp_vec
                precendent_repair_periods = [get(restoration_period,pr_comp,0) for pr_comp in precedance_comps]
                if !isempty(precendent_repair_periods)
                    final_precedent_repair = maximum(precendent_repair_periods)
                else
                    final_precedent_repair = 0
                end
                if restoration_period[r_comp] < final_precedent_repair
                    println("Changing $r_comp repair from $(restoration_period[r_comp]) to $final_precedent_repair")
                    updated = true
                    restoration_period[r_comp] = final_precedent_repair
                end
            end
        end
    end

    # create repair order structure
    restoration_order = Dict{String,Any}("$nwid"=>Dict{String,Any}(comp_type=>String[] for comp_type in restoration_comps) for nwid in 1:length(d_comp_vec))
    for ((comp_type,comp_id),nwid) in restoration_period
        push!(restoration_order["$(nwid)"][comp_type], comp_id)
    end

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


function calculate_repair_precedance(data)
    repair_constraints = Dict{Tuple{String, String},Any}()
    for (comp_type, comp_status_key) in _PM.pm_component_status
        if haskey(data,comp_type)
            for (comp_id,comp) in data[comp_type]
                if get(data[comp_type][comp_id],"damaged",0) == 1
                    if comp_type=="branch"
                        repair_constraints[(comp_type,comp_id)] = [("bus","$(comp["f_bus"])"),("bus","$(comp["t_bus"])")]
                    elseif comp_type=="dcline"
                        repair_constraints[(comp_type,comp_id)] = [("bus","$(comp["f_bus"])"),("bus","$(comp["t_bus"])")]
                    elseif comp_type=="gen"
                        repair_constraints[(comp_type,comp_id)] = [("bus","$(comp["gen_bus"])")]
                    elseif comp_type=="storage"
                        repair_constraints[(comp_type,comp_id)] = [("bus","$(comp["gen_bus"])")]
                    elseif comp_type=="bus"
                        repair_constraints[(comp_type,comp_id)] = Tuple{String,String}[]
                    else
                        Memento.error(_PM._LOGGER, "Component $comp_type does not have a supported repair precedance. Setting no precedance")
                        repair_constraints[(comp_type,comp_id)] = Tuple{String,String}[]
                    end
                end
            end
        end
    end
    return repair_constraints
end
