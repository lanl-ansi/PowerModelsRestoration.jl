""
function variable_bus_voltage_damage(pm::_PM.AbstractWRModel; kwargs...)
    variable_bus_voltage_magnitude_sqr_on_off(pm; kwargs...)
    variable_bus_voltage_magnitude_sqr_violation(pm; kwargs...)
    _PM.variable_branch_voltage_magnitude_fr_sqr_on_off(pm; kwargs...)
    _PM.variable_branch_voltage_magnitude_to_sqr_on_off(pm; kwargs...)

    _PM.variable_branch_voltage_product_on_off(pm; kwargs...)
end

"this is the same as non-damaged version becouse ccms includes zero"
function variable_storage_current_damage(pm::_PM.AbstractWRModel; nw::Int=nw_id_default)
    _PM.variable_storage_current(pm, nw=nw)
    # buses = _PM.ref(pm, nw, :bus)
    # ub = Dict()
    # for (i, storage) in _PM.ref(pm, nw, :storage)
    #     if haskey(storage, "thermal_rating")
    #         bus = buses[storage["storage_bus"]]
    #         ub[i] = (storage["thermal_rating"]/bus["vmin"])^2
    #     else
    #         ub[i] = Inf
    #     end
    # end

    # _PM.var(pm, nw)[:ccms] = JuMP.@variable(pm.model,
    #     [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_ccms",
    #     lower_bound = 0.0,
    #     upper_bound = ub[i],
    #     start = _PM.variable_current_storage_damagecomp_start_value(_PM.ref(pm, nw, :storage, i), "ccms_start")
    # )
end


""
function variable_bus_voltage_magnitude_sqr_violation(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)
    _PM.var(pm, nw)[:w_vio] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_w_vio",
        lower_bound = 0.0,
        upper_bound = _PM.ref(pm, nw, :bus, i, "vmin")^2,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "w_vio_start", 0.0)
    )
end


""
function constraint_model_voltage_damage(pm::_PM.AbstractWRModel, n::Int)
    w  = _PM.var(pm, n, :w)
    wr = _PM.var(pm, n, :wr)
    wi = _PM.var(pm, n, :wi)
    z  = _PM.var(pm, n, :z_branch)

    w_fr = _PM.var(pm, n, :w_fr)
    w_to = _PM.var(pm, n, :w_to)

    constraint_voltage_magnitude_sqr_from_damage(pm, n)
    constraint_voltage_magnitude_sqr_to_damage(pm, n)
    constraint_voltage_product_damage(pm, n)

    for (l,i,j) in _PM.ref(pm, n, :arcs_from)
        _IM.relaxation_complex_product_on_off(pm.model, w[i], w[j], wr[l], wi[l], z[l])
        _IM.relaxation_equality_on_off(pm.model, w[i], w_fr[l], z[l])
        _IM.relaxation_equality_on_off(pm.model, w[j], w_to[l], z[l])
    end
end


""
function constraint_voltage_magnitude_sqr_from_damage(pm::_PM.AbstractWRModel, n::Int)
    buses = _PM.ref(pm, n, :bus)
    branches = _PM.ref(pm, n, :branch)

    w_fr = _PM.var(pm, n, :w_fr)
    z = _PM.var(pm, n, :z_branch)

    for (i, branch) in _PM.ref(pm, n, :branch)
        JuMP.@constraint(pm.model, w_fr[i] <= z[i]*buses[branch["f_bus"]]["vmax"]^2)
    end
end

""
function constraint_voltage_magnitude_sqr_to_damage(pm::_PM.AbstractWRModel, n::Int)
    buses = _PM.ref(pm, n, :bus)
    branches = _PM.ref(pm, n, :branch)

    w_to = _PM.var(pm, n, :w_to)
    z = _PM.var(pm, n, :z_branch)

    for (i, branch) in _PM.ref(pm, n, :branch)
        JuMP.@constraint(pm.model, w_to[i] <= z[i]*buses[branch["t_bus"]]["vmax"]^2)
    end
end

""
function constraint_voltage_product_damage(pm::_PM.AbstractWRModel, n::Int)
    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, n, :buspairs))

    bi_bp = Dict((i, (b["f_bus"], b["t_bus"])) for (i,b) in _PM.ref(pm, n, :branch))

    wr = _PM.var(pm, n, :wr)
    wi = _PM.var(pm, n, :wi)
    z  = _PM.var(pm, n, :z_branch)

    for b in _PM.ids(pm, n, :branch)
        JuMP.@constraint(pm.model, wr[b] <= z[b]*wr_max[bi_bp[b]])
        JuMP.@constraint(pm.model, wi[b] <= z[b]*wi_max[bi_bp[b]])
    end
end


""
function constraint_bus_damage_soft(pm::_PM.AbstractWRModel, n::Int, i::Int, vm_min, vm_max)
    w = _PM.var(pm, n, :w, i)
    w_vio = _PM.var(pm, n, :w_vio, i)
    z = _PM.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, w <= z*vm_max^2)
    JuMP.@constraint(pm.model, w >= z*vm_min^2 - w_vio)
end

""
function constraint_voltage_magnitude_bounds_soft(pm::_PM.AbstractWRModel, n::Int, i::Int, vm_min, vm_max)
    w = _PM.var(pm, n, :w, i)
    w_vio = _PM.var(pm, n, :w_vio, i)

    JuMP.@constraint(pm.model, w <= vm_max^2)
    JuMP.@constraint(pm.model, w >= vm_min^2 - w_vio)
end


""
function constraint_ohms_yt_from_damage(pm::_PM.AbstractWRModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PM.calc_branch_y(branch)
    tr, ti = _PM.calc_branch_t(branch)
    g_fr = branch["g_fr"]
    b_fr = branch["b_fr"]
    tm = branch["tap"]

    # TODO make indexing of :wi,:wr standardized
    ## Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PM.ref(pm, nw, :branch_damage), i)
        vad_min = _PM.ref(pm, nw, :off_angmin)
        vad_max = _PM.ref(pm, nw, :off_angmax)
        _PM.constraint_ohms_yt_from_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm, vad_min, vad_max)
    else
        vad_min = _PM.ref(pm, nw, :off_angmin)
        vad_max = _PM.ref(pm, nw, :off_angmax)
        _PM.constraint_ohms_yt_from_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm, vad_min, vad_max)
        #_PM.constraint_ohms_yt_from(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, tr, ti, tm)
    end
end


""
function constraint_ohms_yt_to_damage(pm::_PM.AbstractWRModel, i::Int; nw::Int=nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PM.calc_branch_y(branch)
    tr, ti = _PM.calc_branch_t(branch)
    g_to = branch["g_to"]
    b_to = branch["b_to"]
    tm = branch["tap"]

    # TODO make indexing of :wi,:wr standardized
    ## Because :wi, :wr are indexed by bus_id or bus_pairs depending on if the value is on_off or
    # standard, there are indexing issues.  Temporary solution: always call *_on_off variant
    if haskey(_PM.ref(pm, nw, :branch_damage), i)
        vad_min = _PM.ref(pm, nw, :off_angmin)
        vad_max = _PM.ref(pm, nw, :off_angmax)

        _PM.constraint_ohms_yt_to_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm, vad_min, vad_max)
    else
        vad_min = _PM.ref(pm, nw, :off_angmin)
        vad_max = _PM.ref(pm, nw, :off_angmax)
        _PM.constraint_ohms_yt_to_on_off(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm, vad_min, vad_max)
        #_PM.constraint_ohms_yt_to(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, tr, ti, tm)
    end
end





function variable_bus_voltage_on_off(pm::_PM.AbstractWRModel; kwargs...)
    variable_bus_voltage_magnitude_sqr_on_off(pm; kwargs...)
    variable_bus_voltage_product_on_off(pm; kwargs...)
end


function variable_bus_voltage_product_on_off(pm::_PM.AbstractWRModel; nw::Int=nw_id_default)
    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, nw, :buspairs))

    _PM.var(pm, nw)[:wr] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs)], base_name="$(nw)_wr",
        lower_bound = min(0,wr_min[bp]),
        upper_bound = max(0,wr_max[bp]),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs, bp), "wr_start", 1.0)
    )
    _PM.var(pm, nw)[:wi] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs)], base_name="$(nw)_wi",
        lower_bound = min(0,wi_min[bp]),
        upper_bound = max(0,wi_max[bp]),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs, bp), "wi_start")
    )

end


function constraint_bus_voltage_product_on_off(pm::_PM.AbstractWRModels; nw::Int=nw_id_default)
    wr_min, wr_max, wi_min, wi_max = _PM.ref_calc_voltage_product_bounds(_PM.ref(pm, nw, :buspairs))

    wr = _PM.var(pm, nw, :wr)
    wi = _PM.var(pm, nw, :wi)
    z_voltage = _PM.var(pm, nw, :z_voltage)

    for bp in _PM.ids(pm, nw, :buspairs)
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


function constraint_bus_voltage_on_off(pm::_PM.AbstractWRModels, n::Int; kwargs...)
    for (i,bus) in _PM.ref(pm, n, :bus)
        constraint_voltage_magnitude_sqr_on_off(pm, i; nw=n)
    end

    constraint_bus_voltage_product_on_off(pm; nw=n)

    w = _PM.var(pm, n, :w)
    wr = _PM.var(pm, n, :wr)
    wi = _PM.var(pm, n, :wi)

    for (i,j) in _PM.ids(pm, n, :buspairs)
        InfrastructureModels.relaxation_complex_product(pm.model, w[i], w[j], wr[(i,j)], wi[(i,j)])
    end
end


