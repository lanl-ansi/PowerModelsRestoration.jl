""
function constraint_model_voltage_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    constraint_model_voltage_damage(pm, nw, cnd)
end

"Limit the maximum number of items restored in each time-step"
function constraint_restoration_cardinality_ub(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, cumulative_repairs=_PMs.ref(pm, nw, :repaired_total))
    constraint_restoration_cardinality_ub(pm, nw, cumulative_repairs)
end


"Limit the minimum number of items restored in each time-step"
function constraint_restoration_cardinality_lb(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, cumulative_repairs=_PMs.ref(pm, nw, :repaired_total))
    constraint_restoration_cardinality_lb(pm, nw, cumulative_repairs)
end

#
# "Require all items restored in final time-step"
# function constraint_restore_all_items(pm::_PMs.AbstractPowerModel; nw::Int=maximum(_PMs.nw_ids(pm)))
#     constraint_restore_all_items(pm, nw)
# end


""
function constraint_generation_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    gen = _PMs.ref(pm, nw, :gen, i)

    gen_damaged = haskey(_PMs.ref(pm, nw, :damaged_gen), i)
    bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), gen["gen_bus"])

    if gen_damaged
        _PMs.constraint_generation_on_off(pm, nw, cnd, i, gen["pmin"][cnd], gen["pmax"][cnd], gen["qmin"][cnd], gen["qmax"][cnd])
        if bus_damaged
            constraint_gen_bus_connection(pm, nw, i, gen["gen_bus"])
        end
    end
    if bus_damaged && !gen_damaged
        Memento.error(_PMs._LOGGER, "non-damaged generator $(i) connected to damaged bus $(gen["gen_bus"])")
    end
end


""
function constraint_load_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    if haskey(_PMs.ref(pm, nw, :load), i)
        load = _PMs.ref(pm, nw, :load, i)

        bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), load["load_bus"])

        if bus_damaged
            constraint_load_bus_connection(pm, nw, i, load["load_bus"])
        end
    end
end


""
function constraint_shunt_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    if haskey(_PMs.ref(pm, nw, :shunt), i)
        shunt = _PMs.ref(pm, nw, :shunt, i)
        bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), shunt["shunt_bus"])

        if bus_damaged
            constraint_shunt_bus_connection(pm, nw, i, shunt["shunt_bus"])
        end
    end
end


""
function constraint_branch_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)

    branch_damaged = haskey(_PMs.ref(pm, nw, :damaged_branch), i)
    bus_fr_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), branch["f_bus"])
    bus_to_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), branch["t_bus"])

    if branch_damaged
        if bus_fr_damaged
            constraint_branch_bus_connection(pm, nw, i, branch["f_bus"])
        end
        if bus_to_damaged
            constraint_branch_bus_connection(pm, nw, i, branch["t_bus"])
        end
    end
    if bus_fr_damaged && !branch_damaged
        Memento.error(_PMs._LOGGER, "non-damaged branch $(i) connected to damaged bus $(branch["f_bus"])")
    end
    if bus_to_damaged && !branch_damaged
        Memento.error(_PMs._LOGGER, "non-damaged branch $(i) connected to damaged bus $(branch["t_bus"])")
    end
end


""
function constraint_ohms_yt_from_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PMs.calc_branch_y(branch)
    tr, ti = _PMs.calc_branch_t(branch)
    g_fr = branch["g_fr"][cnd]
    b_fr = branch["b_fr"][cnd]
    tm = branch["tap"][cnd]

    # TODO make indexing of :wi,:wr standardized
    ## Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)
        _PMs.constraint_ohms_yt_from_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_fr, b_fr, tr[cnd], ti[cnd], tm, vad_min, vad_max)
    else
        #vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        #vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)
        #_PMs.constraint_ohms_yt_from_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_fr, b_fr, tr[cnd], ti[cnd], tm, vad_min, vad_max)
        _PMs.constraint_ohms_yt_from(pm, nw, cnd, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_fr, b_fr, tr[cnd], ti[cnd], tm)
    end
end


""
function constraint_ohms_yt_to_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PMs.calc_branch_y(branch)
    tr, ti = _PMs.calc_branch_t(branch)
    g_to = branch["g_to"][cnd]
    b_to = branch["b_to"][cnd]
    tm = branch["tap"][cnd]

    # TODO make indexing of :wi,:wr standardized
    ## Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)

        _PMs.constraint_ohms_yt_to_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_to, b_to, tr[cnd], ti[cnd], tm, vad_min, vad_max)
    else
        #vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        #vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)
        #_PMs.constraint_ohms_yt_to_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_to, b_to, tr[cnd], ti[cnd], tm, vad_min, vad_max)
        _PMs.constraint_ohms_yt_to(pm, nw, cnd, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_to, b_to, tr[cnd], ti[cnd], tm)
    end
end


""
function constraint_voltage_angle_difference_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_idx = (i, branch["f_bus"], branch["t_bus"])

    # TODO make indexing of :wi,:wr standardized
    # Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)

        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)

        _PMs.constraint_voltage_angle_difference_on_off(pm, nw, cnd, f_idx, branch["angmin"][cnd], branch["angmax"][cnd], vad_min, vad_max)
    else
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)

        _PMs.constraint_voltage_angle_difference_on_off(pm, nw, cnd, f_idx, branch["angmin"][cnd], branch["angmax"][cnd], vad_min, vad_max)
    end
end


"""

    constraint_thermal_limit_from(pm::AbstractPowerModel, n::Int, i::Int)

Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel.

"""
function constraint_thermal_limit_from_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)

    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        _PMs.constraint_thermal_limit_from_on_off(pm, nw, cnd, i, f_idx, branch["rate_a"][cnd])
    else
        if !haskey(_PMs.con(pm, nw, cnd), :sm_fr)
            _PMs.con(pm, nw, cnd)[:sm_fr] = Dict{Int,Any}() # note this can be a constraint or a variable bound
        end
        _PMs.constraint_thermal_limit_from(pm, nw, cnd, f_idx, branch["rate_a"][cnd])
    end
end


""
function constraint_thermal_limit_to_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    t_idx = (i, t_bus, f_bus)

    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        _PMs.constraint_thermal_limit_to_on_off(pm, nw, cnd, i, t_idx, branch["rate_a"][cnd])
    else
        if !haskey(_PMs.con(pm, nw, cnd), :sm_to)
            _PMs.con(pm, nw, cnd)[:sm_to] = Dict{Int,Any}() # note this can be a constraint or a variable bound
        end
        _PMs.constraint_thermal_limit_to(pm, nw, cnd, t_idx, branch["rate_a"][cnd])
    end
end


""
function constraint_storage_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    storage = _PMs.ref(pm, nw, :storage, i)

    storage_damaged = haskey(_PMs.ref(pm, nw, :damaged_storage), i)
    bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), storage["storage_bus"])

    for storage_id in _PMs.ref(pm, nw, :bus_storage, i)
        constraint_storage_bus_connection(pm, nw, storage_id, i)
    end

    if storage_damaged
        charge_ub = storage["charge_rating"]
        discharge_ub = storage["discharge_rating"]

        inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus), cnd)
        pmin = inj_lb[i]
        pmax = inj_ub[i]
        qmin = max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin", cnd))
        qmax = min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax", cnd))

        _PMs.constraint_storage_on_off(pm, nw, cnd, i, pmin, pmax, qmin, qmax, charge_ub, discharge_ub)
        if bus_damaged
            constraint_storage_bus_connection(pm, nw, i, storage["storage_bus"])
        end
    end
    if bus_damaged && !storage_damaged
        Memento.error(_PMs._LOGGER, "non-damaged storage $(i) connected to damaged bus $(gen["storage_bus"])")
    end
end

""
function constraint_bus_voltage_violation_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_bus_voltage_violation_damage(pm, nw, cnd, i, bus["vmin"], bus["vmax"])
end

""
function constraint_bus_voltage_violation(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_bus_voltage_violation(pm, nw, cnd, i, bus["vmin"], bus["vmax"])
end



""
function constraint_power_balance_shed(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    if !haskey(_PMs.con(pm, nw, cnd), :kcl_p)
        _PMs.con(pm, nw, cnd)[:kcl_p] = Dict{Int,JuMP.ConstraintRef}()
    end
    if !haskey(_PMs.con(pm, nw, cnd), :kcl_q)
        _PMs.con(pm, nw, cnd)[:kcl_q] = Dict{Int,JuMP.ConstraintRef}()
    end

    bus = _PMs.ref(pm, nw, :bus, i)
    bus_arcs = _PMs.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PMs.ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = _PMs.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PMs.ref(pm, nw, :bus_gens, i)
    bus_loads = _PMs.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PMs.ref(pm, nw, :bus_shunts, i)
    bus_storage = _PMs.ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => _PMs.ref(pm, nw, :load, k, "pd", cnd) for k in bus_loads)
    bus_qd = Dict(k => _PMs.ref(pm, nw, :load, k, "qd", cnd) for k in bus_loads)

    bus_gs = Dict(k => _PMs.ref(pm, nw, :shunt, k, "gs", cnd) for k in bus_shunts)
    bus_bs = Dict(k => _PMs.ref(pm, nw, :shunt, k, "bs", cnd) for k in bus_shunts)

    constraint_power_balance_shed(pm, nw, cnd, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
end


constraint_bus_voltage_on_off(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, kwargs...) = constraint_bus_voltage_on_off(pm, nw, cnd; kwargs...)


function constraint_voltage_magnitude_on_off(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_on_off(pm, nw, cnd, i, bus["vmin"][cnd], bus["vmax"][cnd])
end


function constraint_voltage_magnitude_sqr_on_off(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_sqr_on_off(pm, nw, cnd, i, bus["vmin"][cnd], bus["vmax"][cnd])
end

