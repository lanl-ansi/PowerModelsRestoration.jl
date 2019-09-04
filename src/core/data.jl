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


"Replace non-binary status codes for devices" #needed because PowerModels filters non-zero status items
function clean_status!(nw_data)
    for item_type in ["load", "shunt"]
        for (n, net) in nw_data["nw"]
            for (i,item) in get(net, item_type, Dict())
                item["status"] = ceil(item["status"])
            end
        end
    end
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function replicate_restoration_network(sn_data::Dict{String,<:Any}; count::Int=1)
    return replicate_restoration_network(sn_data, count, Set(["baseMVA", "per_unit"]))
end


"Transforms a single network into a multinetwork with several deepcopies of the original network. Indexed from 0."
function replicate_restoration_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String})
    @assert count > 0
    if _IMs.ismultinetwork(sn_data)
        Memento.error(_PMs._LOGGER, "replicate_restoration_network can only be used on single networks")
    end

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

    mn_data["name"] = "$(count) period restoration of $(name)"

    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(sn_data_tmp)
    end

    total_repairs = 0
    for j in ["gen","branch","storage"]
        for (i,item) in sn_data[j]
            total_repairs = total_repairs + (get(item,"damaged",0)==1 ? 1 : 0)
        end
    end

    repairs_per_period = ceil(Int, total_repairs/count)

    mn_data["nw"]["0"]["repairs"] = 0
    mn_data["nw"]["0"]["time_elapsed"] = repairs_per_period
    mn_data["nw"]["0"]["repaired_total"] = 0

    for n in 1:count
        if repairs_per_period*(n) < total_repairs 
            mn_data["nw"]["$n"]["repairs"] = repairs_per_period
        else
            mn_data["nw"]["$n"]["repairs"] = total_repairs - repairs_per_period*(n-1)
        end

        if haskey(mn_data["nw"]["$n"], "time_elapsed")
            mn_data["nw"]["$n"]["time_elapsed"] = mn_data["nw"]["$n"]["repairs"]*mn_data["nw"]["$n"]["time_elapsed"]
        else
            mn_data["nw"]["$n"]["time_elapsed"] = mn_data["nw"]["$n"]["repairs"]*1.0
        end

        mn_data["nw"]["$n"]["repaired_total"] = sum(mn_data["nw"]["$(nw)"]["repairs"] for nw=0:n)
    end    

    return mn_data
end


