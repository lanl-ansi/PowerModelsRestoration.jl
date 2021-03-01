""
function variable_bus_voltage_on_off(pm::_PM.AbstractACRModel; kwargs...)
    _PM.variable_bus_voltage(pm; kwargs...)
end


""
function constraint_voltage_real_on_off(pm::_PM.AbstractACRModel, n::Int, i::Int, vrmin::Float64, vrmax::Float64)
    vr, z_voltage = _PM.var(pm, n, :vr, i), _PM.var(pm, n, :z_voltage, i)
    JuMP.@constraint(pm.model, vr <= vrmax * z_voltage)
    JuMP.@constraint(pm.model, vr >= vrmin * z_voltage)
end


""
function constraint_voltage_imaginary_on_off(pm::_PM.AbstractACRModel, n::Int, i::Int, vimin::Float64, vimax::Float64)
    vi, z_voltage = _PM.var(pm, n, :vi, i), _PM.var(pm, n, :z_voltage, i)
    JuMP.@constraint(pm.model, vi <= vimax * z_voltage)
    JuMP.@constraint(pm.model, vi >= vimin * z_voltage)
end


""
function constraint_power_balance_shed(pm::_PM.AbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    _PM.constraint_power_balance_ls(pm, n, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
end


""
function constraint_bus_voltage_on_off(pm::_PM.AbstractACRModel; nw::Int = nw_id_default, kwargs...)
    for (i, bus) in _PM.ref(pm, nw, :bus)
        constraint_voltage_real_on_off(pm, nw, i, -bus["vmax"], bus["vmax"])
        constraint_voltage_imaginary_on_off(pm, nw, i, -bus["vmax"], bus["vmax"])
    end
end