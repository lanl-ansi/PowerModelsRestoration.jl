""
function constraint_model_voltage_damage(pm::_PM.AbstractACPModel, n::Int)
end

""
function variable_voltage_damage(pm::_PM.AbstractACPModel; kwargs...)
    _PM.variable_voltage_angle(pm; kwargs...)
    variable_voltage_magnitude_on_off(pm; kwargs...)
    variable_voltage_magnitude_violation(pm; kwargs...)
end

""
function constraint_bus_voltage_violation_damage(pm::_PM.AbstractACPModel, n::Int, i::Int, vm_min, vm_max)
    vm = _PM.var(pm, n, :vm, i)
    vm_vio = _PM.var(pm, n, :vm_vio, i)
    z = _PM.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, vm <= z*vm_max)
    JuMP.@constraint(pm.model, vm >= z*vm_min - vm_vio)
end

""
function constraint_bus_voltage_violation(pm::_PM.AbstractACPModel, n::Int, i::Int, vm_min, vm_max)
    vm = _PM.var(pm, n, :vm, i)
    vm_vio = _PM.var(pm, n, :vm_vio, i)

    JuMP.@constraint(pm.model, vm <= vm_max)
    JuMP.@constraint(pm.model, vm >= vm_min - vm_vio)
end

function variable_bus_voltage_on_off(pm::_PM.AbstractACPModel; kwargs...)
    _PM.variable_voltage_angle(pm; kwargs...)
    variable_voltage_magnitude_on_off(pm; kwargs...)
end

function constraint_bus_voltage_on_off(pm::_PM.AbstractACPModel; nw::Int=pm.cnw, kwargs...)
    for (i,bus) in _PM.ref(pm, nw, :bus)
        # TODO turn off voltage angle too?
        constraint_voltage_magnitude_on_off(pm, i; nw=nw)
    end
end


""
function constraint_power_balance_shed(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    vm   = _PM.var(pm, n, :vm, i)
    p    = get(_PM.var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q    = get(_PM.var(pm, n),    :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    pg   = get(_PM.var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg   = get(_PM.var(pm, n),   :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = get(_PM.var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = get(_PM.var(pm, n),   :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = get(_PM.var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = get(_PM.var(pm, n),  :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PM.var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")
    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor scale", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor scale", "shunt")


    _PM.con(pm, n, :kcl_p)[i] = JuMP.@NLconstraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd*z_demand[i] for (i,pd) in bus_pd)
        - sum(gs*vm^2*z_shunt[i] for (i,gs) in bus_gs)
    )
    _PM.con(pm, n, :kcl_q)[i] = JuMP.@NLconstraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd*z_demand[i] for (i,qd) in bus_qd)
        + sum(bs*vm^2*z_shunt[i] for (i,bs) in bus_bs)
    )
end

