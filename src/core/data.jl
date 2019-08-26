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
function clean_solution(solution)
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


""
function set_repair_time_elapsed(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw)
    if haskey(_PMs.ref(pm,nw), "time_elapsed")
        time_elapsed = _PMs.ref(pm,nw,"time_elapsed")
    else
        Memento.warn(_PMs._LOGGER, "network data should specify time_elapsed, using 1.0 as a default")
        time_elapsed = 1.0
        pm.data["nw"]["$(nw)"]["time_elapsed"] = time_elapsed
    end

    if nw != 1
        time_elapsed = time_elapsed*calc_equal_repairs_per_period(pm)
    end

    pm.data["nw"]["$(nw)"]["time_elapsed"]=time_elapsed
end

