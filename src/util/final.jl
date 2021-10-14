

"Return repair order where all repairs occur in final time period."
function run_FINAL(network::Dict{String,<:Any})
    if _IM.ismultinetwork(network)
        Memento.error(_PM._LOGGER, "run_FINAL requires a single network.")
    end
    dmg_count = count_repairable_items(network)
    dmg_items = get_repairable_items(network)

    restoration_order = Dict("$nw_id" => Dict(comp_type=>String[] for comp_type in restoration_comps) for nw_id in 1:dmg_count)
    restoration_order["$dmg_count"] = dmg_items
    return restoration_order

end