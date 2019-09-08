""
function constraint_restoration_cardinality_upper(pm::_PMs.AbstractPowerModel, n::Int, cumulative_repairs::Int)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)

    JuMP.@constraint(pm.model,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, n, :branch_damaged))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, n, :gen_damaged))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, n, :storage_damaged))
        <= cumulative_repairs
    )
end


""
function constraint_restoration_cardinality_lower(pm::_PMs.AbstractPowerModel, n::Int, cumulative_repairs::Int)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)

    JuMP.@constraint(pm.model,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, n, :branch_damaged))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, n, :gen_damaged))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, n, :storage_damaged))
        >= cumulative_repairs
    )
end


""
function constraint_active_gen(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :gen_damaged), i)
        z_gen_1 = _PMs.var(pm, nw_1, :z_gen, i)
        z_gen_2 = _PMs.var(pm, nw_2, :z_gen, i)

        JuMP.@constraint(pm.model, z_gen_2 >= z_gen_1)
    end
end


""
function constraint_active_storage(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :storage_damaged), i)
        z_storage_1 = _PMs.var(pm, nw_1, :z_storage, i)
        z_storage_2 = _PMs.var(pm, nw_2, :z_storage, i)

        JuMP.@constraint(pm.model, z_storage_2 >= z_storage_1)
    end
end


""
function constraint_active_branch(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :branch_damaged), i)
        z_branch_1 = _PMs.var(pm, nw_1, :z_branch, i)
        z_branch_2 = _PMs.var(pm, nw_2, :z_branch, i)

        JuMP.@constraint(pm.model, z_branch_2 >= z_branch_1)
    end
end

"Load delivered at each node must be greater than or equal the previous time period"
function constraint_increasing_load(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :branch_damaged), i)
        z_demand_1 = _PMs.var(pm, nw_1, :z_demand, i)
        z_demand_2 = _PMs.var(pm, nw_2, :z_demand, i)

        JuMP.@constraint(pm.model, z_demand_2 >= z_demand_1)
    end
end

