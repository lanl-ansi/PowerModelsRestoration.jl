""
function constraint_model_voltage_damage(pm::_PMs.AbstractACPModel, n::Int, c::Int)
end

""
function variable_voltage_damage(pm::_PMs.AbstractACPModel; kwargs...)
    _PMs.variable_voltage_angle(pm; kwargs...)
    variable_voltage_magnitude_on_off(pm; kwargs...)
    variable_voltage_magnitude_violation(pm; kwargs...)
end

""
function constraint_bus_damage(pm::_PMs.AbstractACPModel, n::Int, c::Int, i::Int, vm_min, vm_max)
    vm = _PMs.var(pm, n, c, :vm, i)
    vm_vio = _PMs.var(pm, n, c, :vm_vio, i)
    z = _PMs.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, vm <= z*vm_max)
    JuMP.@constraint(pm.model, vm >= z*vm_min - vm_vio)
end