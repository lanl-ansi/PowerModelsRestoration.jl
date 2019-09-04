"Limit the number of items restored in each time-step"
function constraint_restoration_cardinality(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, cumulative_repairs=_PMs.ref(pm, nw, :repaired_total))
    constraint_restoration_cardinality(pm, nw, cumulative_repairs)
end


""
function constraint_generation_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    if haskey(_PMs.ref(pm, nw, :gen_damaged), i)
        gen = _PMs.ref(pm, nw, :gen, i)
        _PMs.constraint_generation_on_off(pm, nw, cnd, i, gen["pmin"][cnd], gen["pmax"][cnd], gen["qmin"][cnd], gen["qmax"][cnd])
    end
end


""
function constraint_ohms_yt_from_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
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
    if haskey(_PMs.ref(pm, nw, :branch_damaged), i)
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)
        _PMs.constraint_ohms_yt_from_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_fr, b_fr, tr[cnd], ti[cnd], tm, vad_min, vad_max)
    else
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)
        _PMs.constraint_ohms_yt_from_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_fr, b_fr, tr[cnd], ti[cnd], tm, vad_min, vad_max)
    end
end


""
function constraint_ohms_yt_to_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
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
    if haskey(_PMs.ref(pm, nw, :branch_damaged), i)
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)

        _PMs.constraint_ohms_yt_to_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_to, b_to, tr[cnd], ti[cnd], tm, vad_min, vad_max)
    else
        vad_min = _PMs.ref(pm, nw, :off_angmin, cnd)
        vad_max = _PMs.ref(pm, nw, :off_angmax, cnd)

        _PMs.constraint_ohms_yt_to_on_off(pm, nw, cnd, i, f_bus, t_bus, f_idx, t_idx, g[cnd,cnd], b[cnd,cnd], g_to, b_to, tr[cnd], ti[cnd], tm, vad_min, vad_max)
    end
end


""
function constraint_voltage_angle_difference_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_idx = (i, branch["f_bus"], branch["t_bus"])

    # TODO make indexing of :wi,:wr standardized
    # Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :branch_damaged), i)

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

    constraint_thermal_limit_from(pm::GenericPowerModel, n::Int, i::Int)

Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel.

"""
function constraint_thermal_limit_from_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)

    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if haskey(_PMs.ref(pm, nw, :branch_damaged), i)
        _PMs.constraint_thermal_limit_from_on_off(pm, nw, cnd, i, f_idx, branch["rate_a"][cnd])
    else
        if !haskey(_PMs.con(pm, nw, cnd), :sm_fr)
            _PMs.con(pm, nw, cnd)[:sm_fr] = Dict{Int,Any}() # note this can be a constraint or a variable bound
        end
        _PMs.constraint_thermal_limit_from(pm, nw, cnd, f_idx, branch["rate_a"][cnd])
    end
end


""
function constraint_thermal_limit_to_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    t_idx = (i, t_bus, f_bus)

    if haskey(_PMs.ref(pm, nw, :branch_damaged), i)
        _PMs.constraint_thermal_limit_to_on_off(pm, nw, cnd, i, t_idx, branch["rate_a"][cnd])
    else
        if !haskey(_PMs.con(pm, nw, cnd), :sm_to)
            _PMs.con(pm, nw, cnd)[:sm_to] = Dict{Int,Any}() # note this can be a constraint or a variable bound
        end
        _PMs.constraint_thermal_limit_to(pm, nw, cnd, t_idx, branch["rate_a"][cnd])
    end
end


""
function constraint_storage_damage(pm::_PMs.GenericPowerModel, i::Int; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    if haskey(_PMs.ref(pm, nw, :storage_damaged), i)
        storage = _PMs.ref(pm, nw, :storage, i)
        charge_ub = storage["charge_rating"]
        discharge_ub = storage["discharge_rating"]

        inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus), cnd)
        pmin = inj_lb[i]
        pmax = inj_ub[i]
        qmin = max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin", cnd))
        qmax = min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax", cnd))

        _PMs.constraint_storage_on_off(pm, nw, cnd, i, pmin, pmax, qmin, qmax, charge_ub, discharge_ub)
    end
end



