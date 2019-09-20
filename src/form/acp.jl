#function constraint_model_voltage_damage(pm::_PMs.AbstractACPModel, n::Int, c::Int)
#end

""
function constraint_bus_damage(pm::_PMs.AbstractACPModel, n::Int, c::Int, i::Int, vm_min, vm_max)
    vm = _PMs.var(pm, n, c, :vm, i)
    z = _PMs.var(pm, n, :z_bus, i)

    JuMP.@constraint(pm.model, vm <= z*vm_max)
    JuMP.@constraint(pm.model, vm >= z*vm_min)
end