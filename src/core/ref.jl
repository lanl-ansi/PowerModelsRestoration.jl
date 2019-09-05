# tools for working with a PowerModels ref dict structures

""
function ref_add_damaged_items!(pm::_PMs.GenericPowerModel)
    ref_add_damaged_gens!(pm)
    ref_add_damaged_branches!(pm)
    ref_add_damaged_storage!(pm)
end


""
function ref_add_damaged_gens!(pm::_PMs.GenericPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        nw_ref[:gen_damaged] = Dict(x for x in nw_ref[:gen] if haskey(x.second, "damaged") && x.second["damaged"] == 1 in keys(nw_ref[:gen]))
    end
end


""
function ref_add_damaged_branches!(pm::_PMs.GenericPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        nw_ref[:branch_damaged] = Dict(x for x in nw_ref[:branch] if haskey(x.second, "damaged") && x.second["damaged"] == 1 in keys(nw_ref[:branch]))
    end
end


""
function ref_add_damaged_storage!(pm::_PMs.GenericPowerModel)
    for (nw, nw_ref) in pm.ref[:nw]
        nw_ref[:storage_damaged] = Dict(x for x in nw_ref[:storage] if haskey(x.second, "damaged") && x.second["damaged"] == 1 in keys(nw_ref[:storage]))
    end
end
