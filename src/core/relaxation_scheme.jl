"All functions neccessary because z is sometimes an integer instead of variable_ref"
function Base.isinteger(z::JuMP.VariableRef) return false end

function InfrastructureModels.relaxation_equality_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::Int)
    # assumes 0 is in the domain of y when z is 0
    x_lb, x_ub = InfrastructureModels.variable_domain(x)

    JuMP.@constraint(m, y >= x - x_ub*(1-z))
    JuMP.@constraint(m, y <= x - x_lb*(1-z))
end
