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