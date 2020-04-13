# tools for working with a PowerModels ref dict structures

""
function ref_add_damaged_items!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    ref_add_damaged_gens!(ref, data)
    ref_add_damaged_branches!(ref, data)
    ref_add_damaged_storage!(ref, data)
    ref_add_damaged_buses!(ref, data)
end


""
function ref_add_damaged_gens!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:nw]
        damaged_gen = Dict{Int,Any}()
        for (i,gen) in nw_ref[:gen]
            if haskey(gen, "damaged") && gen["damaged"] == 1
                damaged_gen[i]=gen
            end
        end
        nw_ref[:damaged_gen] = damaged_gen
    end
    #_PM.ref(pm,:damaged_gen)
end

""
function ref_add_damaged_buses!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:nw]
        damaged_bus = Dict{Int,Any}()
        for (i,bus) in nw_ref[:bus]
            if haskey(bus, "damaged") && bus["damaged"] == 1
                damaged_bus[i]=bus
            end
        end
        nw_ref[:damaged_bus] = damaged_bus
    end
end


""
function ref_add_damaged_branches!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:nw]
        damaged_branch = Dict{Int,Any}()
        for (i,branch) in nw_ref[:branch]
            if haskey(branch, "damaged") && branch["damaged"] == 1
                damaged_branch[i]=branch
            end
        end
        nw_ref[:damaged_branch] = damaged_branch
    end
end


""
function ref_add_damaged_storage!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:nw]
        damaged_storage = Dict{Int,Any}()
        for (i,storage) in nw_ref[:storage]
            if haskey(storage, "damaged") && storage["damaged"] == 1
                damaged_storage[i]=storage
            end
        end
        nw_ref[:damaged_storage] = damaged_storage
    end
end
