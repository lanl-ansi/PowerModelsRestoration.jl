""
function constraint_model_voltage_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw)
    constraint_model_voltage_damage(pm, nw)
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
function constraint_generation_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    gen = _PMs.ref(pm, nw, :gen, i)

    gen_damaged = haskey(_PMs.ref(pm, nw, :damaged_gen), i)
    bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), gen["gen_bus"])

    if gen_damaged
        _PMs.constraint_generation_on_off(pm, nw, i, gen["pmin"], gen["pmax"], gen["qmin"], gen["qmax"])
        if bus_damaged
            constraint_gen_bus_connection(pm, nw, i, gen["gen_bus"])
        end
    end
    if bus_damaged && !gen_damaged
        Memento.error(_PMs._LOGGER, "non-damaged generator $(i) connected to damaged bus $(gen["gen_bus"])")
    end
end


""
function constraint_load_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if haskey(_PMs.ref(pm, nw, :load), i)
        load = _PMs.ref(pm, nw, :load, i)

        bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), load["load_bus"])

        if bus_damaged
            constraint_load_bus_connection(pm, nw, i, load["load_bus"])
        end
    end
end


""
function constraint_shunt_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if haskey(_PMs.ref(pm, nw, :shunt), i)
        shunt = _PMs.ref(pm, nw, :shunt, i)
        bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), shunt["shunt_bus"])

        if bus_damaged
            constraint_shunt_bus_connection(pm, nw, i, shunt["shunt_bus"])
        end
    end
end


""
function constraint_branch_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
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
function constraint_ohms_yt_from_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PMs.calc_branch_y(branch)
    tr, ti = _PMs.calc_branch_t(branch)
    g_fr = branch["g_fr"]
    b_fr = branch["b_fr"]
    tm = branch["tap"]

    # TODO make indexing of :wi,:wr standardized
    ## Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        vad_min = _PMs.ref(pm, nw, :off_angmin)
        vad_max = _PMs.ref(pm, nw, :off_angmax)
        _PMs.constraint_ohms_yt_from_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm, vad_min, vad_max)
    else
        #vad_min = _PMs.ref(pm, nw, :off_angmin)
        #vad_max = _PMs.ref(pm, nw, :off_angmax)
        #_PMs.constraint_ohms_yt_from_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm, vad_min, vad_max)
        _PMs.constraint_ohms_yt_from(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm)
    end
end


""
function constraint_ohms_yt_to_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PMs.calc_branch_y(branch)
    tr, ti = _PMs.calc_branch_t(branch)
    g_to = branch["g_to"]
    b_to = branch["b_to"]
    tm = branch["tap"]

    # TODO make indexing of :wi,:wr standardized
    ## Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        vad_min = _PMs.ref(pm, nw, :off_angmin)
        vad_max = _PMs.ref(pm, nw, :off_angmax)

        _PMs.constraint_ohms_yt_to_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm, vad_min, vad_max)
    else
        #vad_min = _PMs.ref(pm, nw, :off_angmin)
        #vad_max = _PMs.ref(pm, nw, :off_angmax)
        #_PMs.constraint_ohms_yt_to_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm, vad_min, vad_max)
        _PMs.constraint_ohms_yt_to(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm)
    end
end


""
function constraint_voltage_angle_difference_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_idx = (i, branch["f_bus"], branch["t_bus"])

    # TODO make indexing of :wi,:wr standardized
    # Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)

        vad_min = _PMs.ref(pm, nw, :off_angmin)
        vad_max = _PMs.ref(pm, nw, :off_angmax)

        _PMs.constraint_voltage_angle_difference_on_off(pm, nw, f_idx, branch["angmin"], branch["angmax"], vad_min, vad_max)
    else
        vad_min = _PMs.ref(pm, nw, :off_angmin)
        vad_max = _PMs.ref(pm, nw, :off_angmax)

        _PMs.constraint_voltage_angle_difference_on_off(pm, nw, f_idx, branch["angmin"], branch["angmax"], vad_min, vad_max)
    end
end


"""

    constraint_thermal_limit_from(pm::AbstractPowerModel, n::Int, i::Int)

Adds the (upper and lower) thermal limit constraints for the desired branch to the PowerModel.

"""
function constraint_thermal_limit_from_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PMs.ref(pm, nw, :branch, i)

    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        _PMs.constraint_thermal_limit_from_on_off(pm, nw, i, f_idx, branch["rate_a"])
    else
        if !haskey(_PMs.con(pm, nw), :sm_fr)
            _PMs.con(pm, nw)[:sm_fr] = Dict{Int,Any}() # note this can be a constraint or a variable bound
        end
        _PMs.constraint_thermal_limit_from(pm, nw, f_idx, branch["rate_a"])
    end
end


""
function constraint_thermal_limit_to_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    branch = _PMs.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    t_idx = (i, t_bus, f_bus)

    if haskey(_PMs.ref(pm, nw, :damaged_branch), i)
        _PMs.constraint_thermal_limit_to_on_off(pm, nw, i, t_idx, branch["rate_a"])
    else
        if !haskey(_PMs.con(pm, nw), :sm_to)
            _PMs.con(pm, nw)[:sm_to] = Dict{Int,Any}() # note this can be a constraint or a variable bound
        end
        _PMs.constraint_thermal_limit_to(pm, nw, t_idx, branch["rate_a"])
    end
end


""
function constraint_storage_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    storage = _PMs.ref(pm, nw, :storage, i)

    storage_damaged = haskey(_PMs.ref(pm, nw, :damaged_storage), i)
    bus_damaged = haskey(_PMs.ref(pm, nw, :damaged_bus), storage["storage_bus"])


    if storage_damaged
        charge_ub = storage["charge_rating"]
        discharge_ub = storage["discharge_rating"]

        inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus))
        pmin = inj_lb[i]
        pmax = inj_ub[i]
        qmin = max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin"))
        qmax = min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax"))

        _PMs.constraint_storage_on_off(pm, nw, i, pmin, pmax, qmin, qmax, charge_ub, discharge_ub)
        if bus_damaged
            constraint_storage_bus_connection(pm, nw, i, storage["storage_bus"])
        end
    end
    if bus_damaged && !storage_damaged
        Memento.error(_PMs._LOGGER, "non-damaged storage $(i) connected to damaged bus $(storage["storage_bus"])")
    end
end

""
function constraint_bus_voltage_violation_damage(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_bus_voltage_violation_damage(pm, nw, i, bus["vmin"], bus["vmax"])
end


""
function constraint_bus_voltage_violation(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_bus_voltage_violation(pm, nw, i, bus["vmin"], bus["vmax"])
end


""
function constraint_power_balance_shed(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(_PMs.con(pm, nw), :kcl_p)
        _PMs.con(pm, nw)[:kcl_p] = Dict{Int,JuMP.ConstraintRef}()
    end
    if !haskey(_PMs.con(pm, nw), :kcl_q)
        _PMs.con(pm, nw)[:kcl_q] = Dict{Int,JuMP.ConstraintRef}()
    end

    bus = _PMs.ref(pm, nw, :bus, i)
    bus_arcs = _PMs.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PMs.ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = _PMs.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PMs.ref(pm, nw, :bus_gens, i)
    bus_loads = _PMs.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PMs.ref(pm, nw, :bus_shunts, i)
    bus_storage = _PMs.ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => _PMs.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PMs.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PMs.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PMs.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_shed(pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
end


constraint_bus_voltage_on_off(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, kwargs...) = constraint_bus_voltage_on_off(pm, nw; kwargs...)


function constraint_voltage_magnitude_on_off(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_on_off(pm, nw, i, bus["vmin"], bus["vmax"])
end


function constraint_voltage_magnitude_sqr_on_off(pm::_PMs.AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    bus = _PMs.ref(pm, nw, :bus, i)

    constraint_voltage_magnitude_sqr_on_off(pm, nw, i, bus["vmin"], bus["vmax"])
end

