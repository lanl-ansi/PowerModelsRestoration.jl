""
function variable_bus_voltage_on_off(pm::AbstractACRQModel; kwargs...)
    _PM.variable_bus_voltage(pm; kwargs...)
    variable_bus_voltage_magnitude_sqr_on_off(pm; kwargs...)
end


""
function constraint_voltage_real_on_off(pm::AbstractACRQModel, n::Int, i::Int, vrmin::Float64, vrmax::Float64)
    vr, z_voltage = _PM.var(pm, n, :vr, i), _PM.var(pm, n, :z_voltage, i)
    JuMP.@constraint(pm.model, vr <= vrmax * z_voltage)
    JuMP.@constraint(pm.model, vr >= vrmin * z_voltage)
end


""
function constraint_voltage_imaginary_on_off(pm::AbstractACRQModel, n::Int, i::Int, vimin::Float64, vimax::Float64)
    vi, z_voltage = _PM.var(pm, n, :vi, i), _PM.var(pm, n, :z_voltage, i)
    JuMP.@constraint(pm.model, vi <= vimax * z_voltage)
    JuMP.@constraint(pm.model, vi >= vimin * z_voltage)
end


""
function constraint_power_balance_shed(pm::AbstractACRQModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    _PM.constraint_power_balance_ls(pm, n, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
end


""
function _PM.constraint_power_balance_ls(pm::AbstractACRQModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    vr, vi, w = _PM.var(pm, n, :vr, i), _PM.var(pm, n, :vi, i), _PM.var(pm, n, :w, i)
    JuMP.@constraint(pm.model, vr^2 + vi^2 == w) # Constraint for magnitude squared.

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

    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor", "shunt")

    # this is required for improved performance in NLP models
    if length(z_shunt) <= 0
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd*z_demand[i] for (i,pd) in bus_pd)
            - sum(gs*z_shunt[i] for (i,gs) in bus_gs) * w
        )

        cstr_q =  JuMP.@constraint(pm.model,
            sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd*z_demand[i] for (i,qd) in bus_qd)
            + sum(bs*z_shunt[i] for (i,bs) in bus_bs) * w
        )
    else
        cstr_p = JuMP.@constraint(pm.model,
            sum(p[a] for a in bus_arcs)
            + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(psw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(pg[g] for g in bus_gens)
            - sum(ps[s] for s in bus_storage)
            - sum(pd*z_demand[i] for (i,pd) in bus_pd)
            - sum(gs*z_shunt[i] for (i,gs) in bus_gs) * w
        )

        cstr_q = JuMP.@constraint(pm.model,
            sum(q[a] for a in bus_arcs)
            + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
            + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
            ==
            sum(qg[g] for g in bus_gens)
            - sum(qs[s] for s in bus_storage)
            - sum(qd*z_demand[i] for (i,qd) in bus_qd)
            + sum(bs*z_shunt[i] for (i,bs) in bus_bs) * w
        )
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end


""
function constraint_bus_voltage_on_off(pm::AbstractACRQModel; nw::Int = nw_id_default, kwargs...)
    for (i, bus) in _PM.ref(pm, nw, :bus)
        constraint_voltage_real_on_off(pm, nw, i, -bus["vmax"], bus["vmax"])
        constraint_voltage_imaginary_on_off(pm, nw, i, -bus["vmax"], bus["vmax"])
    end
end