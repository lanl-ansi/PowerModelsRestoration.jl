
"Simulate a restoration sequence power flow"
function run_restoration_redispatch(file::String, model_type::Type, optimizer; kwargs...)
    data = _PM.parse_file(file)
    return run_restoration_redispatch(data, model_type, optimizer; kwargs...)
end

"Simulate a restoration sequence power flow"
function run_restoration_redispatch(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    clear_damage_indicator!(data)
    return _PM.run_model(data, model_type, optimizer, build_restoration_redispatch; multinetwork=true,
    ref_extensions=[_PM.ref_add_on_off_va_bounds!, ref_add_damaged_items!], kwargs...)
end

""
function build_restoration_redispatch(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)
        _PM.variable_bus_voltage(pm, nw=n)
        variable_bus_voltage_magnitude_violation(pm; nw=n)

        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_storage_power(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        _PM.constraint_model_voltage(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_voltage_magnitude_bounds_soft(pm, i, nw=n)
            constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm, i, nw=n)
            _PM.constraint_storage_losses(pm, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            _PM.constraint_ohms_yt_from(pm, i, nw=n)
            _PM.constraint_ohms_yt_to(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm, i, nw=n)

            _PM.constraint_thermal_limit_from(pm, i, nw=n)
            _PM.constraint_thermal_limit_to(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

    end

    network_ids = sort(collect(_PM.nw_ids(pm)))

    n_1 = network_ids[1]
    for i in _PM.ids(pm, :storage, nw=n_1)
        _PM.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage, nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end
        # for i in _PM.ids(pm, :load, nw=n_2)
        #     constraint_load_increasing(pm, i, n_1, n_2)
        # end
        n_1 = n_2
    end

    # n_final = last(network_ids)  # Should this be true? Might cause infeasabilities...
    # constraint_restore_all_items(pm, n_final)

    objective_max_load_delivered(pm)

end


"Simulate a restoration sequence power flow"
function run_restoration_redispatch_load_up(file::String, model_type::Type, optimizer; kwargs...)
    data = _PM.parse_file(file)
    return run_restoration_redispatch_load_up(data, model_type, optimizer; kwargs...)
end

"Simulate a restoration sequence power flow"
function run_restoration_redispatch_load_up(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    clear_damage_indicator!(data)
    return _PM.run_model(data, model_type, optimizer, build_restoration_redispatch_load_up; multinetwork=true,
    ref_extensions=[_PM.ref_add_on_off_va_bounds!, ref_add_damaged_items!], kwargs...)
end

""
function build_restoration_redispatch_load_up(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)
        _PM.variable_bus_voltage(pm, nw=n)
        variable_bus_voltage_magnitude_violation(pm; nw=n)

        _PM.variable_gen_power(pm, nw=n)
        _PM.variable_storage_power(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)
        _PM.variable_dcline_power(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        _PM.constraint_model_voltage(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_voltage_magnitude_bounds_soft(pm, i, nw=n)
            constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            _PM.constraint_storage_complementarity_nl(pm, i, nw=n)
            _PM.constraint_storage_losses(pm, i, nw=n)
            _PM.constraint_storage_thermal_limit(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            _PM.constraint_ohms_yt_from(pm, i, nw=n)
            _PM.constraint_ohms_yt_to(pm, i, nw=n)

            _PM.constraint_voltage_angle_difference(pm, i, nw=n)

            _PM.constraint_thermal_limit_from(pm, i, nw=n)
            _PM.constraint_thermal_limit_to(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

    end

    network_ids = sort(collect(_PM.nw_ids(pm)))

    n_1 = network_ids[1]
    for i in _PM.ids(pm, :storage, nw=n_1)
        _PM.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage, nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :load, nw=n_2)
            constraint_load_increasing(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    # n_final = last(network_ids)  # Should this be true? Might cause infeasabilities...
    # constraint_restore_all_items(pm, n_final)

    objective_max_load_delivered(pm)

end