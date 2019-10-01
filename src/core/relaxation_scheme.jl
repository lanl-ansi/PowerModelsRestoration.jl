"All functions neccessary because z is sometimes an integer instead of variable_ref"
function Base.isinteger(z::JuMP.VariableRef) return false end

#=
function InfrastructureModels.relaxation_equality_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::Int)
    # assumes 0 is in the domain of y when z is 0
    x_lb, x_ub = InfrastructureModels.variable_domain(x)

    JuMP.@constraint(m, y >= x - x_ub*(1-z))
    JuMP.@constraint(m, y <= x - x_lb*(1-z))
end
=#

#=
function InfrastructureModels.relaxation_equality_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::JuMP.VariableRef)
    x_lb, x_ub = InfrastructureModels.variable_domain(x)
    y_lb, y_ub = InfrastructureModels.variable_domain(y)

    delta_max = max(abs(x_ub - y_lb), abs(y_ub - x_lb))

    JuMP.@constraint(m, y >= x - (delta_max)*(1-z))
    JuMP.@constraint(m, y <= x + (delta_max)*(1-z))
end
=#