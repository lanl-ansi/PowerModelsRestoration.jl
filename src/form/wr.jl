"All functions neccessary because z is sometimes an integer instead of variable_ref"
function Base.isinteger(z::JuMP.VariableRef) return false end


"""
On/Off variant of binlinear term (McCormick)
requires that all variables (x,y,z) go to zero with ind
"""
function InfrastructureModels.relaxation_product_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::JuMP.VariableRef, ind::Int)
    x_lb, x_ub = InfrastructureModels.variable_domain(x)
    y_lb, y_ub = InfrastructureModels.variable_domain(y)
    z_lb, z_ub = InfrastructureModels.variable_domain(y)

    @assert x_lb <= 0 && x_ub >= 0
    @assert y_lb <= 0 && y_ub >= 0
    @assert z_lb <= 0 && z_ub >= 0

    JuMP.@constraint(m, z >= x_lb*y + y_lb*x - ind*x_lb*y_lb)
    JuMP.@constraint(m, z >= x_ub*y + y_ub*x - ind*x_ub*y_ub)
    JuMP.@constraint(m, z <= x_lb*y + y_ub*x - ind*x_lb*y_ub)
    JuMP.@constraint(m, z <= x_ub*y + y_lb*x - ind*x_ub*y_lb)
end


"`x - JuMP.upper_bound(x)*(1-z) <= y <= x - JuMP.lower_bound(x)*(1-z)`"
function InfrastructureModels.relaxation_equality_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::Int)
    # assumes 0 is in the domain of y when z is 0
    x_lb, x_ub = InfrastructureModels.variable_domain(x)

    JuMP.@constraint(m, y >= x - x_ub*(1-z))
    JuMP.@constraint(m, y <= x - x_lb*(1-z))
end


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


"""
```
c^2 + d^2 <= a*b*JuMP.upper_bound(z)
c^2 + d^2 <= JuMP.upper_bound(a)*b*JuMP.upper_bound(z)
c^2 + d^2 <= a*JuMP.upper_bound(b)*z
```
"""
function InfrastructureModels.relaxation_complex_product_on_off(m::JuMP.Model, a::JuMP.VariableRef, b::JuMP.VariableRef, c::JuMP.VariableRef, d::JuMP.VariableRef, z::Real)
    a_lb, a_ub = InfrastructureModels.variable_domain(a)
    b_lb, b_ub = InfrastructureModels.variable_domain(b)
    c_lb, c_ub = InfrastructureModels.variable_domain(c)
    d_lb, d_ub = InfrastructureModels.variable_domain(d)
    z_lb = z_ub = z

    @assert c_lb <= 0 && c_ub >= 0
    @assert d_lb <= 0 && d_ub >= 0
    # assume c and d are already linked to z in other constraints
    # and will be forced to 0 when z is 0

    JuMP.@constraint(m, c^2 + d^2 <= a*b*z_ub)
    JuMP.@constraint(m, c^2 + d^2 <= a_ub*b*z)
    JuMP.@constraint(m, c^2 + d^2 <= a*b_ub*z)
end
