# Maximum loadability with flexible generator participation fixed
function _run_mld_discrete_load(file, model_constructor, solver; kwargs...)
    return _PMs.run_model(file, model_constructor, solver, _build_mld_discrete_load; solution_builder = solution_mld, kwargs...)
end

function _build_mld_discrete_load(pm::_PMs.AbstractPowerModel)
    variable_bus_voltage_indicator(pm)
    variable_bus_voltage_on_off(pm)

    _PMs.variable_generation_indicator(pm)
    _PMs.variable_generation_on_off(pm)

    _PMs.variable_storage(pm)

    _PMs.variable_branch_flow(pm)
    _PMs.variable_dcline_flow(pm)

    variable_demand_factor(pm)
    variable_shunt_factor(pm)


    objective_max_loadability(pm)


    for i in _PMs.ids(pm, :ref_buses)
        _PMs.constraint_theta_ref(pm, i)
    end
    constraint_bus_voltage_on_off(pm)

    for i in _PMs.ids(pm, :gen)
        _PMs.constraint_generation_on_off(pm, i)
    end

    for i in _PMs.ids(pm, :bus)
        constraint_power_balance_shed(pm, i)
    end

    for i in _PMs.ids(pm, :branch)
        _PMs.constraint_ohms_yt_from(pm, i)
        _PMs.constraint_ohms_yt_to(pm, i)

        _PMs.constraint_voltage_angle_difference(pm, i)

        _PMs.constraint_thermal_limit_from(pm, i)
        _PMs.constraint_thermal_limit_to(pm, i)
    end

    for i in _PMs.ids(pm, :dcline)
        _PMs.constraint_dcline(pm, i)
    end
end
