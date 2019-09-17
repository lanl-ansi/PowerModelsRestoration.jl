""
function run_rop(file, model_constructor, optimizer; kwargs...)
    return _PMs.run_model(file, model_constructor, optimizer, post_rop; multinetwork=true,
        ref_extensions=[_PMs.ref_add_on_off_va_bounds!, ref_add_damaged_items!],
        solution_builder = solution_rop, kwargs...)
end


""
function post_rop(pm::_PMs.AbstractPowerModel)
    for (n, network) in _PMs.nws(pm)
        variable_bus_damage_indicator(pm, nw=n)
        variable_bus_damage(pm, nw=n)

        variable_branch_damage_indicator(pm, nw=n)
        _PMs.variable_branch_flow(pm, nw=n)

        _PMs.variable_dcline_flow(pm, nw=n)

        variable_storage_damage_indicator(pm, nw=n)
        variable_storage_mi_damage(pm, nw=n)

        variable_generation_damage_indicator(pm, nw=n)
        variable_generation_damage(pm, nw=n)

        _MLD.variable_demand_factor(pm, nw=n, relax=true)
        _MLD.variable_shunt_factor(pm, nw=n, relax=true)

        constraint_restoration_cardinality_ub(pm, nw=n)

        ## TODO Apply on_off constraints on damaged buses only.  apply ordinary bus_voltage constraint to undamaged buses.
        _PMs.constraint_model_voltage_on_off(pm, nw=n)

        for i in _PMs.ids(pm, :ref_buses, nw=n)
            _PMs.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :bus, nw=n)
            constraint_bus_damage(pm, i, nw=n)
            _MLD.constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :gen, nw=n)
            constraint_generation_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :load, nw=n)
            constraint_load_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :shunt, nw=n)
            constraint_shunt_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :branch, nw=n)
            constraint_branch_damage(pm, i, nw=n)
            constraint_ohms_yt_from_damage(pm, i, nw=n)
            constraint_ohms_yt_to_damage(pm, i, nw=n)

            constraint_voltage_angle_difference_damage(pm, i, nw=n)

            constraint_thermal_limit_from_damage(pm, i, nw=n)
            constraint_thermal_limit_to_damage(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :dcline, nw=n)
            _PMs.constraint_dcline(pm, i, nw=n)
        end

        for i in _PMs.ids(pm, :storage, nw=n)
            constraint_storage_damage(pm, i, nw=n)
            _PMs.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PMs.constraint_storage_loss(pm, i, nw=n)
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
        for i in _PMs.ids(pm, :gen, nw=n_2)
            constraint_active_gen(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :bus, nw=n_2)
            constraint_active_bus(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :storage, nw=n_2)
            constraint_active_storage(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :branch, nw=n_2)
            constraint_active_branch(pm, i, n_1, n_2)
        end
        for i in _PMs.ids(pm, :load, nw=n_2)
            constraint_increasing_load(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    n_final = last(network_ids)
    constraint_restore_all_items(pm, n_final)

    objective_max_load_delivered(pm)
end


"report restoration solution"
function solution_rop(pm::_PMs.AbstractPowerModel, sol::Dict{String,Any})
    add_setpoint_bus_status!(sol,pm)
    _PMs.add_setpoint_bus_voltage!(sol, pm)
    _PMs.add_setpoint_generator_status!(sol, pm)
    _PMs.add_setpoint_generator_power!(sol, pm)
    _PMs.add_setpoint_branch_status!(sol, pm)
    _PMs.add_setpoint_branch_flow!(sol, pm)
    _PMs.add_setpoint_dcline_flow!(sol, pm)
    _PMs.add_setpoint_storage_status!(sol, pm)
    _PMs.add_setpoint_storage!(sol, pm)
    _MLD.add_setpoint_load!(sol,pm)
    _MLD.add_setpoint_shunt!(sol,pm)
end

function add_setpoint_bus_status!(sol, pm::_PMs.AbstractPowerModel)
    _PMs.add_setpoint!(sol, pm, "bus", "status", :z_bus, status_name="bus_type", inactive_status_value = 4, conductorless=true, default_value = (item) -> if item["bus_type"] == 4 0 else 1 end)
end
