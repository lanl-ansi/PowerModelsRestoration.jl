

"Return repair order where all repairs occur in final time period."
function final_period_restoration(network::Dict{String,<:Any})
    if _IM.ismultinetwork(network)
        Memento.error(_PM._LOGGER, "final_period_restoration requires a single network.")
    end
    dmg_count = count_damaged_items(network)
    dmg_items = get_damaged_items(network)

    restoration_order = Dict("$nw_id" => Dict(comp_type=>String[] for comp_type in restoration_comps) for nw_id in 1:dmg_count)
    restoration_order["$dmg_count"] = dmg_items
    return restoration_order

end
