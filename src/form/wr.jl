"All functions neccessary because z is sometimes an integer instead of variable_ref"
function Base.isinteger(z::JuMP.VariableRef) return false end

""
function variable_voltage_damage(pm::_PMs.AbstractWRModel; kwargs...)
    variable_voltage_magnitude_sqr_on_off(pm; kwargs...)
    _PMs.variable_voltage_magnitude_sqr_from_on_off(pm; kwargs...)
    _PMs.variable_voltage_magnitude_sqr_to_on_off(pm; kwargs...)

    _PMs.variable_voltage_product_on_off(pm; kwargs...)
end

""
function variable_voltage_magnitude_sqr_on_off(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        _PMs.var(pm, nw, cnd)[:w] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_$(cnd)_w",
            lower_bound = 0.0,
            upper_bound = _PMs.ref(pm, nw, :bus, i, "vmax", cnd)^2,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "w_start", cnd, 1.001)
        )
    else
        _PMs.var(pm, nw, cnd)[:w] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_$(cnd)_w",
            lower_bound = 0.0,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "w_start", cnd, 1.001)
        )
    end
end

#=
""
function constraint_model_voltage_damage(pm::_PMs.AbstractWRModel, n::Int, c::Int)
    w  = var(pm, n, c, :w)
    wr = var(pm, n, c, :wr)
    wi = var(pm, n, c, :wi)
    z  = var(pm, n, :z_branch)

    w_fr = var(pm, n, c, :w_fr)
    w_to = var(pm, n, c, :w_to)

    _PMs.constraint_voltage_magnitude_sqr_from_on_off(pm, n, c)
    _PMs.constraint_voltage_magnitude_sqr_to_on_off(pm, n, c)
    _PMs.constraint_voltage_product_on_off(pm, n, c)

    for (l,i,j) in ref(pm, n, :arcs_from)
        _IMs.relaxation_complex_product_on_off(pm.model, w[i], w[j], wr[l], wi[l], z[l])
        _IMs.relaxation_equality_on_off(pm.model, w[i], w_fr[l], z[l])
        _IMs.relaxation_equality_on_off(pm.model, w[j], w_to[l], z[l])
    end
end
=#

""
function constraint_bus_damage(pm::_PMs.AbstractWRModel, n::Int, c::Int, i::Int, vm_min, vm_max)
    w = _PMs.var(pm, n, c, :w, i)
    z = _PMs.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, w <= z*vm_max^2)
    JuMP.@constraint(pm.model, w >= z*vm_min^2)
end


"`p[arc_from]^2 + q[arc_from]^2 <= w[f_bus]/tm*ccm[i]`"
function _PMs.constraint_power_magnitude_sqr_on_off(pm::_PMs.AbstractQCWRModel, n::Int, c::Int, i, f_bus, arc_from, tm)
    w    = _PMs.var(pm, n, c, :w, f_bus)
    p_fr = _PMs.var(pm, n, c, :p, arc_from)
    q_fr = _PMs.var(pm, n, c, :q, arc_from)
    ccm  = _PMs.var(pm, n, c, :ccm, i)
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
