""
function constraint_restoration_cardinality_upper(pm::_PMs.AbstractPowerModel, n::Int, cumulative_repairs::Int)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)
    z_bus = _PMs.var(pm, n, :z_bus)

    JuMP.@constraint(pm.model,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, n, :damaged_branch))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, n, :damaged_gen))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, n, :damaged_storage))
        + sum(z_branch[i] for (i,bus) in _PMs.ref(pm, n, :damaged_storage))
        <= cumulative_repairs
    )
end


""
function constraint_restoration_cardinality_lower(pm::_PMs.AbstractPowerModel, n::Int, cumulative_repairs::Int)
    z_storage = _PMs.var(pm, n, :z_storage)
    z_gen = _PMs.var(pm, n, :z_gen)
    z_branch = _PMs.var(pm, n, :z_branch)
    z_bus = _PMs.var(pm, n, :z_bus)

    JuMP.@constraint(pm.model,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, n, :damaged_branch))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, n, :damaged_gen))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, n, :damaged_storage))
        + sum(z_branch[i] for (i,bus) in _PMs.ref(pm, n, :damaged_storage))
        >= cumulative_repairs
    )
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
    if haskey(_PMs.ref(pm, nw_1, :damaged_branch), i)
        z_demand_1 = _PMs.var(pm, nw_1, :z_demand, i)
        z_demand_2 = _PMs.var(pm, nw_2, :z_demand, i)

        JuMP.@constraint(pm.model, z_demand_2 >= z_demand_1)
    end
end


"on/off constraint for generators connected to damaged buses"
function constraint_gen_bus_connection(pm::_PMs.AbstractPowerModel, n::Int, c::Int, gen_id::Int, bus_id::Int, pmin, pmax, qmin, qmax)
    pg = _PMs.var(pm, n, c, :pg, gen_id)
    qg = _PMs.var(pm, n, c, :qg, gen_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, pg <= pmax*z_bus)
    JuMP.@constraint(pm.model, pg >= pmin*z_bus)
    JuMP.@constraint(pm.model, qg <= qmax*z_bus)
    JuMP.@constraint(pm.model, qg >= qmin*z_bus)
end


"on/off constraint for generators"
function constraint_gen_bus_connection(pm::_PMs.AbstractDCPModel, n::Int, c::Int, gen_id::Int, bus_id::Int, pmin, pmax, qmin, qmax)
    pg = _PMs.var(pm, n, c, :pg, gen_id)
    z_bus = _PMs.var(pm, n, :z_bus, bus_id)

    JuMP.@constraint(pm.model, pg <= pmax*z_bus)
    JuMP.@constraint(pm.model, pg >= pmin*z_bus)
end

function constraint_voltage_magnitude_on_off(pm::_PMs.AbstractPowerModel, n::Int, c::Int, i::Int, vmin, vmax)
    vm = _PMs.var(pm, n, c, :vm, i)
    z_bus = _PMs.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, vm <= vmax*z_bus)
    JuMP.@constraint(pm.model, vm >= vmin*z_bus)
end

function constraint_voltage_magnitude_sqr_on_off(pm::_PMs.AbstractPowerModel, n::Int, c::Int, i::Int, vmin, vmax)
    w = _PMs.var(pm, n, c, :w, i)
    z_bus = _PMs.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, w <= vmax^2*z_bus)
    JuMP.@constraint(pm.model, w >= vmin^2*z_bus)
end


