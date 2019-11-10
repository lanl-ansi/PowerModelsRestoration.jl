""
function constraint_restoration_cardinality_ub(pm::_PMs.AbstractPowerModel, n::Int, cumulative_repairs::Int)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)
    z_bus = _PMs.var(pm, n, :z_bus)

    JuMP.@constraint(pm.model,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, n, :damaged_branch))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, n, :damaged_gen))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, n, :damaged_storage))
        + sum(z_bus[i] for (i,bus) in _PMs.ref(pm, n, :damaged_bus))
        <= cumulative_repairs
    )
end


""
function constraint_restoration_cardinality_lb(pm::_PMs.AbstractPowerModel, n::Int, cumulative_repairs::Int)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)
    z_bus = _PMs.var(pm, n, :z_bus)

    JuMP.@constraint(pm.model,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, n, :damaged_branch))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, n, :damaged_gen))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, n, :damaged_storage))
        + sum(z_bus[i] for (i,bus) in _PMs.ref(pm, n, :damaged_bus))
        >= cumulative_repairs
    )
end


function constraint_restore_all_items(pm, n)
    z_demand = _PMs.var(pm, n, :z_demand)
    z_shunt = _PMs.var(pm, n, :z_shunt)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)
    z_bus = _PMs.var(pm, n, :z_bus)

    for (i,load) in  _PMs.ref(pm, n, :load)
        JuMP.@constraint(pm.model, z_demand[i] == 1)
    end
    for (i,shunt) in  _PMs.ref(pm, n, :shunt)
        JuMP.@constraint(pm.model, z_shunt[i] == 1)
    end

    for (i,storage) in  _PMs.ref(pm, n, :damaged_storage)
        JuMP.@constraint(pm.model, z_storage[i] == 1)
    end
    for (i,gen) in  _PMs.ref(pm, n, :damaged_gen)
        JuMP.@constraint(pm.model, z_gen[i] == 1)
    end
    for (i,branch) in  _PMs.ref(pm, n, :damaged_branch)
        JuMP.@constraint(pm.model, z_branch[i] == 1)
    end
    for (i,bus) in  _PMs.ref(pm, n, :damaged_bus)
        JuMP.@constraint(pm.model, z_bus[i] == 1)
    end
end


""
function constraint_active_gen(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :damaged_gen), i)
        z_gen_1 = _PMs.var(pm, nw_1, :z_gen, i)
        z_gen_2 = _PMs.var(pm, nw_2, :z_gen, i)

        JuMP.@constraint(pm.model, z_gen_2 >= z_gen_1)
    end
end

""
function constraint_active_bus(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :damaged_gen), i)
        z_bus_1 = _PMs.var(pm, nw_1, :z_bus, i)
        z_bus_2 = _PMs.var(pm, nw_2, :z_bus, i)

        JuMP.@constraint(pm.model, z_bus_2 >= z_bus_1)
    end
end


""
function constraint_active_storage(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :damaged_storage), i)
        z_storage_1 = _PMs.var(pm, nw_1, :z_storage, i)
        z_storage_2 = _PMs.var(pm, nw_2, :z_storage, i)

        JuMP.@constraint(pm.model, z_storage_2 >= z_storage_1)
    end
end


""
function constraint_active_branch(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if haskey(_PMs.ref(pm, nw_1, :damaged_branch), i)
        z_branch_1 = _PMs.var(pm, nw_1, :z_branch, i)
        z_branch_2 = _PMs.var(pm, nw_2, :z_branch, i)

        JuMP.@constraint(pm.model, z_branch_2 >= z_branch_1)
    end
end


"Load delivered at each node must be greater than or equal the previous time period"
function constraint_increasing_load(pm::_PMs.AbstractPowerModel,  i::Int, nw_1::Int, nw_2::Int)
    if i in  _PMs.var(pm, nw_1, :z_demand)
        z_demand_1 = _PMs.var(pm, nw_1, :z_demand, i)
        z_demand_2 = _PMs.var(pm, nw_2, :z_demand, i)

        JuMP.@constraint(pm.model, z_demand_2 >= z_demand_1)
    end
end


"on/off constraint for storage connected to damaged buses"
function constraint_storage_bus_connection(pm::_PMs.AbstractPowerModel, n::Int, storage_id::Int, bus_id::Int)
    z_storage = _PMs.var(pm, n, :z_storage, storage_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, z_storage <= z_bus)
end


"on/off constraint for generators connected to damaged buses"
function constraint_gen_bus_connection(pm::_PMs.AbstractPowerModel, n::Int, gen_id::Int, bus_id::Int)
    z_gen = _PMs.var(pm, n, :z_gen, gen_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, z_gen <= z_bus)
end


"on/off constraint for loads connected to damaged buses"
function constraint_load_bus_connection(pm::_PMs.AbstractPowerModel, n::Int, load_id::Int, bus_id::Int)
    z_demand = _PMs.var(pm, n, :z_demand, load_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, z_demand <= z_bus)
end

"on/off constraint for shunts connected to damaged buses"
function constraint_shunt_bus_connection(pm::_PMs.AbstractPowerModel, n::Int, shunt_id::Int, bus_id::Int)
    z_shunt = _PMs.var(pm, n, :z_shunt, shunt_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, z_shunt <= z_bus)
end

"on/off constraint for branches connected to damaged buses"
function constraint_branch_bus_connection(pm::_PMs.AbstractPowerModel, n::Int, branch_id::Int, bus_id::Int)
    z_branch = _PMs.var(pm, n, :z_branch, branch_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, z_branch <= z_bus)
end


