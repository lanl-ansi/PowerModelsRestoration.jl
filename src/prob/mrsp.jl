""
function run_mrsp(file, model_constructor, optimizer; kwargs...)
    return _PMs.run_model(file, model_constructor, optimizer, post_mrsp;
        ref_extensions=[_PMs.ref_add_on_off_va_bounds!, ref_add_damaged_items!],
        solution_builder = solution_mrsp, kwargs...)
end


""
function post_mrsp(pm::_PMs.AbstractPowerModel)
    variable_bus_damage_indicator(pm)
    variable_bus_damage(pm)

    variable_branch_damage_indicator(pm)
    _PMs.variable_branch_flow(pm)

    _PMs.variable_dcline_flow(pm)

    variable_storage_damage_indicator(pm)
    variable_storage_mi_damage(pm)

    variable_generation_damage_indicator(pm)
    variable_generation_damage(pm)

    #_MLD.constraint_bus_voltage_on_off(pm)
    _PMs.constraint_model_voltage_on_off(pm)

    for i in _PMs.ids(pm, :ref_buses)
        _PMs.constraint_theta_ref(pm, i)
        constraint_bus_damage(pm, i)
    end

    for i in _PMs.ids(pm, :bus)
        _PMs.constraint_power_balance(pm, i)
    end

    for i in _PMs.ids(pm, :damaged_gen)
        constraint_generation_damage(pm, i)
    end

    for i in _PMs.ids(pm, :branch)
        constraint_ohms_yt_from_damage(pm, i)
        constraint_ohms_yt_to_damage(pm, i)

        constraint_voltage_angle_difference_damage(pm, i)

        constraint_thermal_limit_from_damage(pm, i)
        constraint_thermal_limit_to_damage(pm, i)
    end

    for i in _PMs.ids(pm, :dcline)
        _PMs.constraint_dcline(pm, i)
    end

    for i in _PMs.ids(pm, :storage)
        constraint_storage_damage(pm, i)
        _PMs.constraint_storage_state(pm, i)
        _PMs.constraint_storage_complementarity_mi(pm, i)
        _PMs.constraint_storage_loss(pm, i)
    end

    objective_min_restoration(pm)
end


""
function objective_min_restoration(pm::_PMs.AbstractPowerModel)
    @assert !_PMs.ismultinetwork(pm)
    z_storage = _PMs.var(pm, pm.cnw, :z_storage)
    z_gen = _PMs.var(pm, pm.cnw, :z_gen)
    z_branch = _PMs.var(pm, pm.cnw, :z_branch)
    z_bus = _PMs.var(pm, pm.cnw, :z_bus)

    JuMP.@objective(pm.model, Min,
        sum(z_branch[i] for (i,branch) in _PMs.ref(pm, :damaged_branch))
        + sum(z_gen[i] for (i,gen) in _PMs.ref(pm, :damaged_gen))
        + sum(z_storage[i] for (i,storage) in _PMs.ref(pm, :damaged_storage))
    )
end


"report minimal restoration set solution"
function solution_mrsp(pm::_PMs.AbstractPowerModel, sol::Dict{String,Any})
    add_setpoint_bus_status!(sol,pm)
    _PMs.add_setpoint_bus_voltage!(sol, pm)
    _PMs.add_setpoint_generator_status!(sol, pm)
    _PMs.add_setpoint_generator_power!(sol, pm)
    _PMs.add_setpoint_branch_status!(sol, pm)
    _PMs.add_setpoint_branch_flow!(sol, pm)
    _PMs.add_setpoint_dcline_flow!(sol, pm)
    _PMs.add_setpoint_storage_status!(sol, pm)
    _PMs.add_setpoint_storage!(sol, pm)
end

