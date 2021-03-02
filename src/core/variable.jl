"Need because of mix of vars/real in z_gen, z_branch, z_storage"
function JuMP.value(x::Real) return x end

"variable: `v[i]` for `i` in `bus`es"
function variable_bus_voltage_magnitude_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    vm = _PM.var(pm, nw)[:vm] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_vm",
        lower_bound = 0.0,
        upper_bound = _PM.ref(pm, nw, :bus, i, "vmax"),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "vm_start", 1.0)
    )

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :vm, _PM.ids(pm, nw, :bus), vm)
end

"variable: `v[i]` for `i` in `bus`es"
function variable_bus_voltage_magnitude_violation(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    vm_vio = _PM.var(pm, nw)[:vm_vio] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_vm_vio",
        lower_bound = 0.0,
        upper_bound = _PM.ref(pm, nw, :bus, i, "vmin"),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "vm_vio_start")
    )

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :vm_vio, _PM.ids(pm, nw, :bus), vm_vio)
end


"variable: `0 <= damage_gen[l] <= 1` for `l` in `gen`es"
function variable_gen_damage_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if relax == false
        z_gen_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :gen_damage)],
            base_name="$(nw)_active_gen",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, l), "gen_damage_start")
        )
    else
        z_gen_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :gen_damage)],
            base_name="$(nw)_active_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, l), "gen_damage_start")
        )
    end
    z_gen = Dict(i => haskey(gen, "damaged") && gen["damaged"] == 1 && gen["gen_status"]==1 ? z_gen_vars[i] : gen["gen_status"] for (i,gen) in _PM.ref(pm, nw, :gen))
    _PM.var(pm, nw)[:z_gen] = z_gen

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :gen, :gen_status, _PM.ids(pm, nw, :gen), z_gen)
end


"generates variables for both `active` and `reactive` generation"
function variable_gen_power_damage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_gen_power_real_damage(pm; kwargs...)
    variable_gen_power_imaginary_damage(pm; kwargs...)
end


"variable: `pg[j]` for `j` in `gen`"
function variable_gen_power_real_damage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    if bounded
        pg = _PM.var(pm, nw)[:pg] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_dmg",
            lower_bound = _PM.ref(pm, nw, :gen, i, "pmin"),
            upper_bound = _PM.ref(pm, nw, :gen, i, "pmax"),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_start")
        )
        for i in _PM.ids(pm, nw, :gen)
            if haskey(_PM.ref(pm, nw, :gen, i), "damaged") && _PM.ref(pm, nw, :gen,i)["damaged"] == 1
                JuMP.set_upper_bound(_PM.var(pm, nw, :pg, i), max(0, _PM.ref(pm, nw, :gen, i, "pmax")))
                JuMP.set_lower_bound(_PM.var(pm, nw, :pg, i), min(0, _PM.ref(pm, nw, :gen, i, "pmin")))
            end
        end
    else
        pg = _PM.var(pm, nw)[:pg] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_dmg",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "pg_start")
        )
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :gen, :pg, _PM.ids(pm, nw, :gen), pg)
end


"variable: `qq[j]` for `j` in `gen`"
function variable_gen_power_imaginary_damage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    if bounded
        qg = _PM.var(pm, nw)[:qg] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_qg_dmg",
            lower_bound = _PM.ref(pm, nw, :gen, i, "qmin"),
            upper_bound = _PM.ref(pm, nw, :gen, i, "qmax"),
            start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "qg_start")
        )
    else
        qg = _PM.var(pm, nw)[:qg] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_qg_dmg",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :gen, i), "qg_start")
    )
    end

    for i in _PM.ids(pm, nw, :gen)
        if haskey(_PM.ref(pm, nw, :gen, i), "damaged") && _PM.ref(pm, nw, :gen,i)["damaged"] == 1
            JuMP.set_upper_bound(_PM.var(pm, nw, :qg, i), max(0, _PM.ref(pm, nw, :gen, i, "qmax")))
            JuMP.set_lower_bound(_PM.var(pm, nw, :qg, i), min(0, _PM.ref(pm, nw, :gen, i, "qmin")))
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :gen, :qg, _PM.ids(pm, nw, :gen), qg)
end


"variable: `0 <= damage_branch[l] <= 1` for `l` in `branch`es"
function variable_branch_damage_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if relax == false
        z_branch_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :branch_damage)],
            base_name="$(nw)_active_branch",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "branch_damage_start")
        )
    else
        z_branch_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :branch_damage)],
            base_name="$(nw)_active_branch",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :branch, l), "branch_damage_start")
        )
    end

    z_branch = Dict(i => haskey(branch, "damaged") && branch["damaged"] == 1 ? z_branch_vars[i] : branch["br_status"]  for (i,branch) in _PM.ref(pm, nw, :branch))
    _PM.var(pm, nw)[:z_branch] = z_branch

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :branch, :br_status, _PM.ids(pm, nw, :branch), z_branch)
end


"variable: `0 <= damage_storage[l] <= 1` for `l` in `storage`es"
function variable_storage_damage_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if relax == false
        z_storage_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :storage_damage)],
            base_name="$(nw)_active_storage",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, l), "storage_damage_start")
        )
    else
        z_storage_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :storage_damage)],
            base_name="$(nw)_active_storage",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, l), "storage_damage_start")
        )
    end

    z_storage = Dict(i => haskey(storage, "damaged") && storage["damaged"] == 1 ? z_storage_vars[i] : storage["status"]  for (i,storage) in _PM.ref(pm, nw, :storage))
    _PM.var(pm, nw)[:z_storage] = z_storage

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :storage, :status, _PM.ids(pm, nw, :storage), z_storage)
end


""
function variable_storage_power_mi_damage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_storage_power_real_damage(pm; kwargs...)
    variable_storage_power_imaginary_damage(pm; kwargs...)
    variable_storage_power_control_imaginary_damage(pm; kwargs...)
    variable_storage_current_damage(pm; kwargs...)
    _PM.variable_storage_energy(pm; kwargs...)
    _PM.variable_storage_charge(pm; kwargs...)
    _PM.variable_storage_discharge(pm; kwargs...)
    _PM.variable_storage_complementary_indicator(pm; kwargs...)
end


"do nothing by default but some formulations require this"
function variable_storage_current_damage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
end

""
function variable_storage_power_real_damage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    inj_lb, inj_ub = _PM.ref_calc_storage_injection_bounds(_PM.ref(pm, nw, :storage), _PM.ref(pm, nw, :bus))

    ps = _PM.var(pm, nw)[:ps] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_ps_dmg",
        lower_bound = inj_lb[i],
        upper_bound = inj_ub[i],
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "ps_start")
    )

    for i in _PM.ids(pm, nw, :storage)
        if haskey(_PM.ref(pm, nw, :storage, i), "damaged") && _PM.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PM.var(pm, nw, :ps, i), max(0, inj_ub[i]))
            JuMP.set_lower_bound(_PM.var(pm, nw, :ps, i), min(0, inj_lb[i]))
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :storage, :ps, _PM.ids(pm, nw, :storage), ps)
end


""
function variable_storage_power_imaginary_damage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    inj_lb, inj_ub = _PM.ref_calc_storage_injection_bounds(_PM.ref(pm, nw, :storage), _PM.ref(pm, nw, :bus))

    qs = _PM.var(pm, nw)[:qs] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_qs_dmg",
        lower_bound = max(inj_lb[i], _PM.ref(pm, nw, :storage, i, "qmin")),
        upper_bound = min(inj_ub[i], _PM.ref(pm, nw, :storage, i, "qmax")),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "qs_start")
    )
    for i in _PM.ids(pm, nw, :storage)
        if haskey(_PM.ref(pm, nw, :storage, i), "damaged") && _PM.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PM.var(pm, nw, :ps, i), max(0, min(inj_ub[i], _PM.ref(pm, nw, :storage, i, "qmax"))))
            JuMP.set_lower_bound(_PM.var(pm, nw, :ps, i), min(0, max(inj_lb[i], _PM.ref(pm, nw, :storage, i, "qmin"))))
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :storage, :qs, _PM.ids(pm, nw, :storage), qs)
end

""
function variable_storage_power_control_imaginary_damage(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    inj_lb, inj_ub = _PM.ref_calc_storage_injection_bounds(_PM.ref(pm, nw, :storage), _PM.ref(pm, nw, :bus))

    qsc = _PM.var(pm, nw)[:qsc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_qsc",
        lower_bound = max(inj_lb[i], _PM.ref(pm, nw, :storage, i, "qmin")),
        upper_bound = min(inj_ub[i], _PM.ref(pm, nw, :storage, i, "qmax")),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :storage, i), "qsc_start")
    )

    for i in _PM.ids(pm, nw, :storage)
        if haskey(_PM.ref(pm, nw, :storage, i), "damaged") && _PM.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PM.var(pm, nw, :qsc, i), max(0, min(inj_ub[i], _PM.ref(pm, nw, :storage, i, "qmax"))))
            JuMP.set_lower_bound(_PM.var(pm, nw, :qsc, i), min(0, max(inj_lb[i], _PM.ref(pm, nw, :storage, i, "qmin"))))
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :storage, :qsc, _PM.ids(pm, nw, :storage), qsc)
end


"variable: `0 <= damage_bus[l] <= 1` for `l` in `bus`es"
function variable_bus_damage_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if relax == false
        z_bus_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :bus_damage)],
            base_name="$(nw)_active_bus",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, l), "bus_damage_start")
        )
    else
        z_bus_vars = JuMP.@variable(pm.model,
            [l in _PM.ids(pm, nw, :bus_damage)],
            base_name="$(nw)_active_bus",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, l), "bus_damage_start")
        )
    end

    z_bus = Dict(i => haskey(bus, "damaged") && bus["damaged"] == 1 ? z_bus_vars[i] : bus["bus_type"]==4 ? 0 : 1  for (i,bus) in _PM.ref(pm, nw, :bus))
    _PM.var(pm, nw)[:z_bus] = z_bus

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :status, _PM.ids(pm, nw, :bus), z_bus)
end


function variable_bus_voltage_indicator(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, relax::Bool=false, report::Bool=true)
    if !relax
        z_voltage = _PM.var(pm, nw)[:z_voltage] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_z_voltage",
            binary = true,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_voltage_start")
        )
    else
        z_voltage = _PM.var(pm, nw)[:z_voltage] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_z_voltage",
            lower_bound = 0,
            upper_bound = 1,
            start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "z_voltage_start")
        )
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :status, _PM.ids(pm, nw, :bus), z_voltage)
end


""
function variable_bus_voltage_magnitude_sqr_on_off(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    w = _PM.var(pm, nw)[:w] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :bus)], base_name="$(nw)_w",
        lower_bound = 0,
        upper_bound = _PM.ref(pm, nw, :bus, i, "vmax")^2,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :bus, i), "w_start", 1.001)
    )

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :bus, :w, _PM.ids(pm, nw, :bus), w)
end

