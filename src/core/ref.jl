# tools for working with a PowerModels ref dict structures

""
function ref_add_damaged_items!(pm::_PMs.AbstractPowerModel)
    ref_add_damaged_gens!(pm)
    ref_add_damaged_branches!(pm)
    ref_add_damaged_storage!(pm)
end


""
function ref_add_damaged_gens!(pm::_PMs.AbstractPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        nw_ref[:damaged_gen] = Dict(x for x in nw_ref[:gen] if haskey(x.second, "damaged") && x.second["damaged"] == 1 in keys(nw_ref[:gen]))
    end
end


""
function ref_add_damaged_branches!(pm::_PMs.AbstractPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        nw_ref[:damaged_branch] = Dict(x for x in nw_ref[:branch] if haskey(x.second, "damaged") && x.second["damaged"] == 1 in keys(nw_ref[:branch]))
    end
end


""
function ref_add_damaged_storage!(pm::_PMs.AbstractPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        nw_ref[:damaged_storage] = Dict(x for x in nw_ref[:storage] if haskey(x.second, "damaged") && x.second["damaged"] == 1 in keys(nw_ref[:storage]))
    end
end
