
"Simulate a restoration sequence power flow"
function run_restoration_simulation(file::String, model_type::Type, optimizer; kwargs...)
    data = _PMs.parse_file(file)
    return run_restoration_simulation(data, model_type, optimizer; kwargs...)
end

"Simulate a restoration sequence power flow"
function run_restoration_simulation(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    clear_damage_indicator!(data)
    return _PMs.run_model(data, model_type, optimizer, build_restoration_simulation; multinetwork=true,
    ref_extensions=[_PMs.ref_add_on_off_va_bounds!, ref_add_damaged_items!],
    solution_builder = solution_rop!, kwargs...)
end

""
function build_restoration_simulation(pm::_PMs.AbstractPowerModel)
    for (n, network) in _PMs.nws(pm)
        _PMs.variable_voltage(pm, nw=n)
        variable_voltage_magnitude_violation(pm; nw=n)

        _PMs.variable_generation(pm, nw=n)
        _PMs.variable_storage(pm, nw=n)
        _PMs.variable_branch_flow(pm, nw=n)
        _PMs.variable_dcline_flow(pm, nw=n)

        variable_demand_factor(pm, nw=n, relax=true)
        variable_shunt_factor(pm, nw=n, relax=true)

        _PMs.constraint_model_voltage(pm, nw=n)

        for i in _PMs.ids(pm, :ref_buses, nw=n)
            _PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :bus, nw=n)
            constraint_bus_voltage_violation(pm, i, nw=n)
            constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :storage, nw=n)
            _PMs.constraint_storage_complementarity_nl(pm, i, nw=n)
            _PMs.constraint_storage_loss(pm, i, nw=n)
            _PMs.constraint_storage_thermal_limit(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :branch, nw=n)
            _PMs.constraint_ohms_yt_from(pm, i, nw=n)
            _PMs.constraint_ohms_yt_to(pm, i, nw=n)

            _PMs.constraint_voltage_angle_difference(pm, i, nw=n)

            _PMs.constraint_thermal_limit_from(pm, i, nw=n)
            _PMs.constraint_thermal_limit_to(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :dcline, nw=n)
            _PMs.constraint_dcline(pm, i, nw=n)
        end

    end

    network_ids = sort(collect(_PMs.nw_ids(pm)))

    n_1 = network_ids[1]
    for i in _PMs.ids(pm, :storage, nw=n_1)
        _PMs.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PMs.ids(pm, :storage, nw=n_2)
            _PMs.constraint_storage_state(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    objective_max_load_delivered(pm)

end

