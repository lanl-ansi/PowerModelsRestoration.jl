function constraint_model_voltage_damage(pm::_PMs.AbstractDCPModel, n::Int, c::Int)
end

""
function variable_voltage_damage(pm::_PMs.AbstractDCPModel; kwargs...)
    _PMs.variable_voltage_angle(pm; kwargs...)
end

"no vm values to turn off"
function constraint_bus_voltage_violation_damage(pm::_PMs.AbstractDCPModel, n::Int, c::Int, i::Int, vm_min, vm_max)
end

"no vm values to turn off"
function constraint_bus_voltage_violation(pm::_PMs.AbstractDCPModel, n::Int, c::Int, i::Int, vm_min, vm_max)
end
