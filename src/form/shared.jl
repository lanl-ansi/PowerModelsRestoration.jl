
# # same as AbstractWRForm
""
function variable_shunt_factor(pm::_PMs.AbstractWModels; nw::Int=pm.cnw, cnd::Int=pm.ccnd, relax = false)
    if relax == true
        _PMs.var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :shunt)], base_name="$(nw)_z_shunt", 
            upper_bound = 1, 
            lower_bound = 0,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :shunt, i), "z_shunt_on_start", cnd, 1.0)
        )
    else
        _PMs.var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :shunt)], base_name="$(nw)_z_shunt", 
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :shunt, i), "z_shunt_on_start", cnd, 1.0)
        )
    end
    _PMs.var(pm, nw)[:wz_shunt] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :shunt)], base_name="$(nw)_wz_shunt",
            lower_bound = 0,
            upper_bound = _PMs.ref(pm, nw, :bus)[_PMs.ref(pm, nw, :shunt, i)["shunt_bus"]]["vmax"]^2,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :shunt, i), "wz_shunt_start", cnd, 1.001)
        )
end


""
function constraint_power_balance_shed(pm::_PMs.AbstractWModels, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    w   = _PMs.var(pm, n, c, :w, i)
    p    = get(_PMs.var(pm, n, c),    :p, Dict()); _PMs._check_var_keys(p, bus_arcs, "active power", "branch")
    q    = get(_PMs.var(pm, n, c),    :q, Dict()); _PMs._check_var_keys(q, bus_arcs, "reactive power", "branch")
    pg   = get(_PMs.var(pm, n, c),   :pg, Dict()); _PMs._check_var_keys(pg, bus_gens, "active power", "generator")
    qg   = get(_PMs.var(pm, n, c),   :qg, Dict()); _PMs._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = get(_PMs.var(pm, n, c),   :ps, Dict()); _PMs._check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = get(_PMs.var(pm, n, c),   :qs, Dict()); _PMs._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = get(_PMs.var(pm, n, c),  :psw, Dict()); _PMs._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = get(_PMs.var(pm, n, c),  :qsw, Dict()); _PMs._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(_PMs.var(pm, n, c), :p_dc, Dict()); _PMs._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(_PMs.var(pm, n, c), :q_dc, Dict()); _PMs._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")
    z_demand = get(_PMs.var(pm, n), :z_demand, Dict()); _PMs._check_var_keys(z_demand, keys(bus_pd), "power factor scale", "load")
    z_shunt = get(_PMs.var(pm, n), :z_shunt, Dict()); _PMs._check_var_keys(z_shunt, keys(bus_gs), "power factor scale", "shunt")
    wz_shunt = get(_PMs.var(pm, n), :wz_shunt, Dict()); _PMs._check_var_keys(wz_shunt, keys(bus_gs), "voltage square power factor scale", "shunt")


    _PMs.con(pm, n, c, :kcl_p)[i] = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd*z_demand[i] for (i,pd) in bus_pd)
        - sum(gs*wz_shunt[i] for (i,gs) in bus_gs)
    )
    _PMs.con(pm, n, c, :kcl_q)[i] = JuMP.@constraint(pm.model,
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
