""
function variable_voltage_damage(pm::_PMs.AbstractWRModel; kwargs...)
    variable_voltage_magnitude_sqr_on_off(pm; kwargs...)
    variable_voltage_magnitude_sqr_violation(pm; kwargs...)
    _PMs.variable_voltage_magnitude_sqr_from_on_off(pm; kwargs...)
    _PMs.variable_voltage_magnitude_sqr_to_on_off(pm; kwargs...)

    _PMs.variable_voltage_product_on_off(pm; kwargs...)
end

"this is the same as non-damaged version becouse ccms includes zero"
function variable_current_storage_damage(pm::_PMs.AbstractWRModel; nw::Int=pm.cnw)
    _PMs.variable_current_storage(pm, nw=nw)
    # buses = _PMs.ref(pm, nw, :bus)
    # ub = Dict()
    # for (i, storage) in _PMs.ref(pm, nw, :storage)
    #     if haskey(storage, "thermal_rating")
    #         bus = buses[storage["storage_bus"]]
    #         ub[i] = (storage["thermal_rating"]/bus["vmin"])^2
    #     else
    #         ub[i] = Inf
    #     end
    # end

    # _PMs.var(pm, nw)[:ccms] = JuMP.@variable(pm.model,
    #     [i in _PMs.ids(pm, nw, :storage)], base_name="$(nw)_ccms",
    #     lower_bound = 0.0,
    #     upper_bound = ub[i],
    #     start = _PMs.variable_current_storage_damagecomp_start_value(_PMs.ref(pm, nw, :storage, i), "ccms_start")
    # )
end


""
function variable_voltage_magnitude_sqr_violation(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw)
    _PMs.var(pm, nw)[:w_vio] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_w_vio",
        lower_bound = 0.0,
        upper_bound = _PMs.ref(pm, nw, :bus, i, "vmin")^2,
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "w_vio_start", 0.0)
    )
end


""
function constraint_model_voltage_damage(pm::_PMs.AbstractWRModel, n::Int)
    w  = _PMs.var(pm, n, :w)
    wr = _PMs.var(pm, n, :wr)
    wi = _PMs.var(pm, n, :wi)
    z  = _PMs.var(pm, n, :z_branch)

    w_fr = _PMs.var(pm, n, :w_fr)
    w_to = _PMs.var(pm, n, :w_to)

    constraint_voltage_magnitude_sqr_from_damage(pm, n)
    constraint_voltage_magnitude_sqr_to_damage(pm, n)
    constraint_voltage_product_damage(pm, n)

    for (l,i,j) in _PMs.ref(pm, n, :arcs_from)
        _IMs.relaxation_complex_product_on_off(pm.model, w[i], w[j], wr[l], wi[l], z[l])
        _IMs.relaxation_equality_on_off(pm.model, w[i], w_fr[l], z[l])
        _IMs.relaxation_equality_on_off(pm.model, w[j], w_to[l], z[l])
    end
end


""
function constraint_voltage_magnitude_sqr_from_damage(pm::_PMs.AbstractWRModel, n::Int)
    buses = _PMs.ref(pm, n, :bus)
    branches = _PMs.ref(pm, n, :branch)

    w_fr = _PMs.var(pm, n, :w_fr)
    z = _PMs.var(pm, n, :z_branch)

    for (i, branch) in _PMs.ref(pm, n, :branch)
        JuMP.@constraint(pm.model, w_fr[i] <= z[i]*buses[branch["f_bus"]]["vmax"]^2)
    end
end

""
function constraint_voltage_magnitude_sqr_to_damage(pm::_PMs.AbstractWRModel, n::Int)
    buses = _PMs.ref(pm, n, :bus)
    branches = _PMs.ref(pm, n, :branch)

    w_to = _PMs.var(pm, n, :w_to)
    z = _PMs.var(pm, n, :z_branch)

    for (i, branch) in _PMs.ref(pm, n, :branch)
        JuMP.@constraint(pm.model, w_to[i] <= z[i]*buses[branch["t_bus"]]["vmax"]^2)
    end
end

""
function constraint_voltage_product_damage(pm::_PMs.AbstractWRModel, n::Int)
    wr_min, wr_max, wi_min, wi_max = _PMs.ref_calc_voltage_product_bounds(_PMs.ref(pm, n, :buspairs))

    bi_bp = Dict((i, (b["f_bus"], b["t_bus"])) for (i,b) in _PMs.ref(pm, n, :branch))

    wr = _PMs.var(pm, n, :wr)
    wi = _PMs.var(pm, n, :wi)
    z  = _PMs.var(pm, n, :z_branch)

    for b in _PMs.ids(pm, n, :branch)
        JuMP.@constraint(pm.model, wr[b] <= z[b]*wr_max[bi_bp[b]])
        JuMP.@constraint(pm.model, wi[b] <= z[b]*wi_max[bi_bp[b]])
    end
end


""
function constraint_bus_voltage_violation_damage(pm::_PMs.AbstractWRModel, n::Int, i::Int, vm_min, vm_max)
    w = _PMs.var(pm, n, :w, i)
    w_vio = _PMs.var(pm, n, :w_vio, i)
    z = _PMs.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, w <= z*vm_max^2)
    JuMP.@constraint(pm.model, w >= z*vm_min^2 - w_vio)
end

""
function constraint_bus_voltage_violation(pm::_PMs.AbstractWRModel, n::Int, i::Int, vm_min, vm_max)
    w = _PMs.var(pm, n, :w, i)
    w_vio = _PMs.var(pm, n, :w_vio, i)

    JuMP.@constraint(pm.model, w <= vm_max^2)
    JuMP.@constraint(pm.model, w >= vm_min^2 - w_vio)
end

"`p[arc_from]^2 + q[arc_from]^2 <= w[f_bus]/tm*ccm[i]`"
function _PMs.constraint_power_magnitude_sqr_on_off(pm::_PMs.AbstractQCWRModel, n::Int, i, f_bus, arc_from, tm)
    w    = _PMs.var(pm, n, :w, f_bus)
    p_fr = _PMs.var(pm, n, :p, arc_from)
    q_fr = _PMs.var(pm, n, :q, arc_from)
    ccm  = _PMs.var(pm, n, :ccm, i)
    z    = _PMs.var(pm, n, :z_branch, i)

    # TODO see if there is a way to leverage relaxation_complex_product_on_off here
    w_lb, w_ub = InfrastructureModels.variable_domain(w)
    ccm_lb, ccm_ub = InfrastructureModels.variable_domain(ccm)
    if isinteger(z)
        z_lb = z_ub = z
    else
        z_lb, z_ub = InfrastructureModels.variable_domain(z)
    end

    JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= w*ccm*z_ub/tm^2)
    JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= w_ub*ccm*z/tm^2)
    JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= w*ccm_ub*z/tm^2)
end



""
function constraint_ohms_yt_from_damage(pm::_PMs.AbstractWRModel, i::Int; nw::Int=pm.cnw)
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
        vad_min = _PMs.ref(pm, nw, :off_angmin)
        vad_max = _PMs.ref(pm, nw, :off_angmax)
        _PMs.constraint_ohms_yt_from_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm, vad_min, vad_max)
        #_PMs.constraint_ohms_yt_from(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm)
    end
end


""
function constraint_ohms_yt_to_damage(pm::_PMs.AbstractWRModel, i::Int; nw::Int=pm.cnw)
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
        vad_min = _PMs.ref(pm, nw, :off_angmin)
        vad_max = _PMs.ref(pm, nw, :off_angmax)
        _PMs.constraint_ohms_yt_to_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm, vad_min, vad_max)
        #_PMs.constraint_ohms_yt_to(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm)
    end
end





function variable_bus_voltage_on_off(pm::_PMs.AbstractWRModel; kwargs...)
    variable_voltage_magnitude_sqr_on_off(pm; kwargs...)
    variable_bus_voltage_product_on_off(pm; kwargs...)
end


function variable_bus_voltage_product_on_off(pm::_PMs.AbstractWRModel; nw::Int=pm.cnw)
    wr_min, wr_max, wi_min, wi_max = _PMs.ref_calc_voltage_product_bounds(_PMs.ref(pm, nw, :buspairs))

    _PMs.var(pm, nw)[:wr] = JuMP.@variable(pm.model,
        [bp in _PMs.ids(pm, nw, :buspairs)], base_name="$(nw)_wr",
        lower_bound = min(0,wr_min[bp]),
        upper_bound = max(0,wr_max[bp]),
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :buspairs, bp), "wr_start", 1.0)
    )
    _PMs.var(pm, nw)[:wi] = JuMP.@variable(pm.model,
        [bp in _PMs.ids(pm, nw, :buspairs)], base_name="$(nw)_wi",
        lower_bound = min(0,wi_min[bp]),
        upper_bound = max(0,wi_max[bp]),
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :buspairs, bp), "wi_start")
    )

end


function constraint_bus_voltage_product_on_off(pm::_PMs.AbstractWRModels; nw::Int=pm.cnw)
    wr_min, wr_max, wi_min, wi_max = _PMs.ref_calc_voltage_product_bounds(_PMs.ref(pm, nw, :buspairs))

    wr = _PMs.var(pm, nw, :wr)
    wi = _PMs.var(pm, nw, :wi)
    z_voltage = _PMs.var(pm, nw, :z_voltage)

    for bp in _PMs.ids(pm, nw, :buspairs)
        (i,j) = bp
        z_fr = z_voltage[i]
        z_to = z_voltage[j]

        JuMP.@constraint(pm.model, wr[bp] <= z_fr*wr_max[bp])
        JuMP.@constraint(pm.model, wr[bp] >= z_fr*wr_min[bp])
        JuMP.@constraint(pm.model, wi[bp] <= z_fr*wi_max[bp])
        JuMP.@constraint(pm.model, wi[bp] >= z_fr*wi_min[bp])

        JuMP.@constraint(pm.model, wr[bp] <= z_to*wr_max[bp])
        JuMP.@constraint(pm.model, wr[bp] >= z_to*wr_min[bp])
        JuMP.@constraint(pm.model, wi[bp] <= z_to*wi_max[bp])
        JuMP.@constraint(pm.model, wi[bp] >= z_to*wi_min[bp])
    end
end


function constraint_bus_voltage_on_off(pm::_PMs.AbstractWRModels, n::Int; kwargs...)
    for (i,bus) in _PMs.ref(pm, n, :bus)
        constraint_voltage_magnitude_sqr_on_off(pm, i; nw=n)
    end

    constraint_bus_voltage_product_on_off(pm; nw=n)

    w = _PMs.var(pm, n, :w)
    wr = _PMs.var(pm, n, :wr)
    wi = _PMs.var(pm, n, :wi)

    for (i,j) in _PMs.ids(pm, n, :buspairs)
        InfrastructureModels.relaxation_complex_product(pm.model, w[i], w[j], wr[(i,j)], wi[(i,j)])
    end
end


