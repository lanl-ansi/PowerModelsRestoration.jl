""
function run_mrsp(file, model_constructor, optimizer; kwargs...)
    return _PM.run_model(file, model_constructor, optimizer, build_mrsp;
        ref_extensions=[_PM.ref_add_on_off_va_bounds!, ref_add_damaged_items!], kwargs...)
end


""
function build_mrsp(pm::_PM.AbstractPowerModel)
    variable_bus_damage_indicator(pm)
    variable_bus_voltage_damage(pm)

    variable_branch_damage_indicator(pm)
    _PM.variable_branch_power(pm)

    _PM.variable_dcline_power(pm)

    variable_storage_damage_indicator(pm)
    variable_storage_power_mi_damage(pm)

    variable_gen_damage_indicator(pm)
    variable_gen_power_damage(pm)

    _PM.constraint_model_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_bus_damage_soft(pm, i)
        _PM.constraint_power_balance(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        constraint_gen_damage(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        constraint_branch_damage(pm, i)
        constraint_ohms_yt_from_damage(pm, i)
        constraint_ohms_yt_to_damage(pm, i)

        constraint_voltage_angle_difference_damage(pm, i)

        constraint_thermal_limit_from_damage(pm, i)
        constraint_thermal_limit_to_damage(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    for i in _PM.ids(pm, :storage)
        constraint_storage_damage(pm, i)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        _PM.constraint_storage_losses(pm, i)
    end

    objective_min_restoration(pm)
end


""
function objective_min_restoration(pm::_PM.AbstractPowerModel)
    @assert !_IM.ismultinetwork(pm)
    z_storage = _PM.var(pm, pm.cnw, :z_storage)
    z_gen = _PM.var(pm, pm.cnw, :z_gen)
    z_branch = _PM.var(pm, pm.cnw, :z_branch)
    z_bus = _PM.var(pm, pm.cnw, :z_bus)

    JuMP.@objective(pm.model, Min,
        sum(z_branch[i] for (i,branch) in _PM.ref(pm, :branch_damage))
        + sum(z_gen[i] for (i,gen) in _PM.ref(pm, :gen_damage))
        + sum(z_storage[i] for (i,storage) in _PM.ref(pm, :storage_damage))
        + sum(z_bus[i] for (i,bus) in _PM.ref(pm, :bus_damage))
    )
end

