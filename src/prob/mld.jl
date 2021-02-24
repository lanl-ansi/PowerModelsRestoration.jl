# Maximum loadability with generator and bus participation relaxed
function run_mld(file, model_constructor, solver; kwargs...)
    return _PM.run_model(file, model_constructor, solver, build_mld; kwargs...)
end

function build_mld(pm::_PM.AbstractPowerModel)
    variable_bus_voltage_indicator(pm, relax=true)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)


    objective_max_loadability(pm)


    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end
end


# this is the same as above, but variable_generation_indicator constraints are *not* relaxed

# Maximum loadability with flexible generator participation fixed
function run_mld_uc(file, model_constructor, solver; kwargs...)
    return _PM.run_model(file, model_constructor, solver, build_mld_uc; kwargs...)
end

function build_mld_uc(pm::_PM.AbstractPowerModel)
    variable_bus_voltage_indicator(pm)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)


    objective_max_loadability(pm)


    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end
end


# Maximum loadability with generator participation fixed
function run_mld_smpl(file, model_constructor, solver; kwargs...)
    return _PM.run_model(file, model_constructor, solver, run_mld_smpl; kwargs...)
end

function run_mld_smpl(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_gen_power(pm, bounded = false)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)

    _PM.var(pm)[:vm_vio] = JuMP.@variable(pm.model, vm_vio[i in _PM.ids(pm, :bus)] >= 0)
    _PM.var(pm)[:pg_vio] = JuMP.@variable(pm.model, pg_vio[i in _PM.ids(pm, :gen)] >= 0)
    vm = _PM.var(pm, :vm)
    pg = _PM.var(pm, :pg)
    qg = _PM.var(pm, :qg)

    z_demand = _PM.var(pm, nw_id_default, :z_demand)
    z_shunt = _PM.var(pm, nw_id_default, :z_shunt)

    load_weight = Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, :load))

    M = maximum(load_weight[i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, :load))
    JuMP.@objective(pm.model, Max,
        sum( -10*M*vm_vio[i] for (i, bus) in _PM.ref(pm, :bus)) +
        sum( -10*M*pg_vio[i] for i in _PM.ids(pm, :gen) ) +
        sum( M*z_shunt[i] for (i, shunt) in _PM.ref(pm, :shunt)) +
        sum( load_weight[i]*abs(load["pd"])*z_demand[i] for (i, load) in _PM.ref(pm, :load))
    )

    _PM.constraint_model_voltage(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for (i, bus) in _PM.ref(pm, :bus)
        constraint_power_balance_shed(pm, i)

        JuMP.@constraint(pm.model, vm[i] <= bus["vmax"] + vm_vio[i])
        JuMP.@constraint(pm.model, vm[i] >= bus["vmin"] - vm_vio[i])
    end

    for (i, gen) in _PM.ref(pm, :gen)
        JuMP.@constraint(pm.model, pg[i] <= gen["pmax"] + pg_vio[i])
        JuMP.@constraint(pm.model, pg[i] >= gen["pmin"] - pg_vio[i])

        JuMP.@constraint(pm.model, qg[i] <= gen["qmax"])
        JuMP.@constraint(pm.model, qg[i] >= gen["qmin"])
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
end


# Maximum loadability with storage, generator and bus participation relaxed
function run_mld_strg(file, model_constructor, solver; kwargs...)
    return _PM.run_model(file, model_constructor, solver, build_mld_strg; kwargs...)
end

function build_mld_strg(pm::_PM.AbstractPowerModel)
    variable_bus_voltage_indicator(pm, relax=true)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm, relax=true)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_storage_indicator(pm, relax = true)
    _PM.variable_storage_power_mi_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)


    objective_max_loadability_strg(pm)


    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :storage)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        _PM.constraint_storage_on_off(pm,i)
        _PM.constraint_storage_losses(pm, i)
        _PM.constraint_storage_thermal_limit(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end
end

# Maximum loadability with storage and generator participated fixed,  and bus participation relaxed
function run_mld_strg_uc(file, model_constructor, solver; kwargs...)
    return _PM.run_model(file, model_constructor, solver, build_mld_strg_uc; kwargs...)
end

function build_mld_strg_uc(pm::_PM.AbstractPowerModel)
    variable_bus_voltage_indicator(pm, relax=true)
    variable_bus_voltage_on_off(pm)

    _PM.variable_gen_indicator(pm)
    _PM.variable_gen_power_on_off(pm)

    _PM.variable_storage_indicator(pm)
    _PM.variable_storage_power_mi_on_off(pm)

    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)

    _PM.variable_load_power_factor(pm, relax=true)
    _PM.variable_shunt_admittance_factor(pm, relax=true)


    objective_max_loadability_strg(pm)


    constraint_bus_voltage_on_off(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        _PM.constraint_gen_power_on_off(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_shed(pm, i)
    end

    for i in _PM.ids(pm, :storage)
        _PM.constraint_storage_state(pm, i)
        _PM.constraint_storage_complementarity_mi(pm, i)
        _PM.constraint_storage_losses(pm, i)
        _PM.constraint_storage_thermal_limit(pm, i)
        _PM.constraint_storage_on_off(pm,i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end
end

