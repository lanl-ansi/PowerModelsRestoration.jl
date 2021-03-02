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
    _PM.apply_pm!(_ref_add_damaged_gens!, ref, data; apply_to_subnetworks = true)
end


function _ref_add_damaged_gens!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    damaged_gen = Dict{Int,Any}()

    for (i,gen) in ref[:gen]
        if haskey(gen, "damaged") && gen["damaged"] == 1
            damaged_gen[i] = gen
        end
    end

    ref[:gen_damage] = damaged_gen
end


function ref_add_damaged_buses!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    _PM.apply_pm!(_ref_add_damaged_buses!, ref, data; apply_to_subnetworks = true)
end


""
function _ref_add_damaged_buses!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    damaged_bus = Dict{Int,Any}()

    for (i, bus) in ref[:bus]
        if haskey(bus, "damaged") && bus["damaged"] == 1
            damaged_bus[i] = bus
        end
    end

    ref[:bus_damage] = damaged_bus
end


""
function ref_add_damaged_branches!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    _PM.apply_pm!(_ref_add_damaged_branches!, ref, data; apply_to_subnetworks = true)
end


function _ref_add_damaged_branches!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    damaged_branch = Dict{Int,Any}()

    for (i, branch) in ref[:branch]
        if haskey(branch, "damaged") && branch["damaged"] == 1
            damaged_branch[i] = branch
        end
    end

    ref[:branch_damage] = damaged_branch
end


""
function ref_add_damaged_storage!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    _PM.apply_pm!(_ref_add_damaged_storage!, ref, data; apply_to_subnetworks = true)
end


function _ref_add_damaged_storage!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    damaged_storage = Dict{Int,Any}()

    for (i, storage) in ref[:storage]
        if haskey(storage, "damaged") && storage["damaged"] == 1
            damaged_storage[i] = storage
        end
    end

    ref[:storage_damage] = damaged_storage
end
