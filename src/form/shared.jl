
""
function constraint_power_balance_shed(pm::_PM.AbstractWModels, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    w   = _PM.var(pm, n, :w, i)
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
    wz_shunt = get(_PM.var(pm, n), :wz_shunt, Dict()); _PM._check_var_keys(wz_shunt, keys(bus_gs), "voltage square power factor scale", "shunt")


    _PM.con(pm, n, :kcl_p)[i] = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd*z_demand[i] for (i,pd) in bus_pd)
        - sum(gs*wz_shunt[i] for (i,gs) in bus_gs)
    )
    _PM.con(pm, n, :kcl_q)[i] = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd*z_demand[i] for (i,qd) in bus_qd)
        + sum(bs*wz_shunt[i] for (i,bs) in bus_bs)
    )

    for s in keys(bus_gs)
        InfrastructureModels.relaxation_product(pm.model, w, z_shunt[s], wz_shunt[s])
    end
end
