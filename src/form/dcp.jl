#function constraint_model_voltage_damage(pm::_PMs.AbstractDCPModel, n::Int, c::Int)
#end

"no vm values to turn off"
function constraint_bus_damage(pm::_PMs.AbstractDCPModel, n::Int, c::Int, i::Int, vm_min, vm_max)
end