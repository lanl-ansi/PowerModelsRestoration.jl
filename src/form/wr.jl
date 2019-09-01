"All functions neccessary because z is sometimes an integer instead of variable_ref"
function Base.isinteger(z::JuMP.VariableRef) return false end

"`p[arc_from]^2 + q[arc_from]^2 <= w[f_bus]/tm*ccm[i]`"
function _PMs.constraint_power_magnitude_sqr_on_off(pm::_PMs.GenericPowerModel{T}, n::Int, c::Int, i, f_bus, arc_from, tm) where T <: _PMs.QCWRForm
    w    = _PMs.var(pm, n, c, :w, f_bus)
    p_fr = _PMs.var(pm, n, c, :p, arc_from)
    q_fr = _PMs.var(pm, n, c, :q, arc_from)
    ccm  = _PMs.var(pm, n, c, :ccm, i)
    z    = _PMs.var(pm, n, c, :branch_z, i)

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
