"Need because of mix of vars/real in z_gen, z_branch, z_storage"
function JuMP.value(x::Real) return x end

"variable: `v[i]` for `i` in `bus`es"
function variable_voltage_magnitude_on_off(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, report::Bool=true)
    vm = _PMs.var(pm, nw)[:vm] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_vm",
        lower_bound = 0.0,
        upper_bound = _PMs.ref(pm, nw, :bus, i, "vmax"),
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "vm_start", 1.0)
    )

    report && _PMs.sol_component_value(pm, nw, :bus, :vm, _PMs.ids(pm, nw, :bus), vm)
end

"variable: `v[i]` for `i` in `bus`es"
function variable_voltage_magnitude_violation(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, report::Bool=true)
    vm_vio = _PMs.var(pm, nw)[:vm_vio] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_vm_vio",
        lower_bound = 0.0,
        upper_bound = _PMs.ref(pm, nw, :bus, i, "vmin"),
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "vm_vio_start")
    )

    report && _PMs.sol_component_value(pm, nw, :bus, :vm_vio, _PMs.ids(pm, nw, :bus), vm_vio)
end


"variable: `0 <= damage_gen[l] <= 1` for `l` in `gen`es"
function variable_generation_damage_indicator(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)

    if relax == false
        z_gen_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_gen)],
            base_name="$(nw)_active_gen",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, l), "gen_damage_start")
        )
    else
        z_gen_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_gen)],
            base_name="$(nw)_active_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, l), "gen_damage_start")
        )
    end
    z_gen = Dict(i => haskey(gen, "damaged") && gen["damaged"] == 1 && gen["gen_status"]==1 ? z_gen_vars[i] : gen["gen_status"] for (i,gen) in _PMs.ref(pm, nw, :gen))
    _PMs.var(pm, nw)[:z_gen] = z_gen

    report && _PMs.sol_component_value(pm, nw, :gen, :gen_status, _PMs.ids(pm, nw, :gen), z_gen)
end


"generates variables for both `active` and `reactive` generation"
function variable_generation_damage(pm::_PMs.AbstractPowerModel; kwargs...)
    variable_active_generation_damage(pm; kwargs...)
    variable_reactive_generation_damage(pm; kwargs...)
end


"variable: `pg[j]` for `j` in `gen`"
function variable_active_generation_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    if bounded
        pg = _PMs.var(pm, nw)[:pg] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_pg_dmg",
            lower_bound = _PMs.ref(pm, nw, :gen, i, "pmin"),
            upper_bound = _PMs.ref(pm, nw, :gen, i, "pmax"),
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "pg_start")
        )
        for i in _PMs.ids(pm, nw, :gen)
            if haskey(_PMs.ref(pm, nw, :gen, i), "damaged") && _PMs.ref(pm, nw, :gen,i)["damaged"] == 1
                JuMP.set_upper_bound(_PMs.var(pm, nw, :pg, i), max(0, _PMs.ref(pm, nw, :gen, i, "pmax")))
                JuMP.set_lower_bound(_PMs.var(pm, nw, :pg, i), min(0, _PMs.ref(pm, nw, :gen, i, "pmin")))
            end
        end
    else
        pg = _PMs.var(pm, nw)[:pg] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_pg_dmg",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "pg_start")
        )
    end

    report && _PMs.sol_component_value(pm, nw, :gen, :pg, _PMs.ids(pm, nw, :gen), pg)
end


"variable: `qq[j]` for `j` in `gen`"
function variable_reactive_generation_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool=true, report::Bool=true)
    if bounded
        qg = _PMs.var(pm, nw)[:qg] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_qg_dmg",
            lower_bound = _PMs.ref(pm, nw, :gen, i, "qmin"),
            upper_bound = _PMs.ref(pm, nw, :gen, i, "qmax"),
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "qg_start")
        )
    else
        qg = _PMs.var(pm, nw)[:qg] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_qg_dmg",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "qg_start")
    )
    end

    for i in _PMs.ids(pm, nw, :gen)
        if haskey(_PMs.ref(pm, nw, :gen, i), "damaged") && _PMs.ref(pm, nw, :gen,i)["damaged"] == 1
            JuMP.set_upper_bound(_PMs.var(pm, nw, :qg, i), max(0, _PMs.ref(pm, nw, :gen, i, "qmax")))
            JuMP.set_lower_bound(_PMs.var(pm, nw, :qg, i), min(0, _PMs.ref(pm, nw, :gen, i, "qmin")))
        end
    end

    report && _PMs.sol_component_value(pm, nw, :gen, :qg, _PMs.ids(pm, nw, :gen), qg)
end


"variable: `0 <= damage_branch[l] <= 1` for `l` in `branch`es"
function variable_branch_damage_indicator(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if relax == false
        z_branch_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_branch)],
            base_name="$(nw)_active_branch",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "branch_damage_start")
        )
    else
        z_branch_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_branch)],
            base_name="$(nw)_active_branch",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "branch_damage_start")
        )
    end

    z_branch = Dict(i => haskey(branch, "damaged") && branch["damaged"] == 1 ? z_branch_vars[i] : branch["br_status"]  for (i,branch) in _PMs.ref(pm, nw, :branch))
    _PMs.var(pm, nw)[:z_branch] = z_branch

    report && _PMs.sol_component_value(pm, nw, :branch, :br_status, _PMs.ids(pm, nw, :branch), z_branch)
end


"variable: `0 <= damage_storage[l] <= 1` for `l` in `storage`es"
function variable_storage_damage_indicator(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if relax == false
        z_storage_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_storage)],
            base_name="$(nw)_active_storage",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, l), "storage_damage_start")
        )
    else
        z_storage_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_storage)],
            base_name="$(nw)_active_storage",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, l), "storage_damage_start")
        )
    end

    z_storage = Dict(i => haskey(storage, "damaged") && storage["damaged"] == 1 ? z_storage_vars[i] : storage["status"]  for (i,storage) in _PMs.ref(pm, nw, :storage))
    _PMs.var(pm, nw)[:z_storage] = z_storage

    report && _PMs.sol_component_value(pm, nw, :storage, :status, _PMs.ids(pm, nw, :storage), z_storage)
end


""
function variable_storage_mi_damage(pm::_PMs.AbstractPowerModel; kwargs...)
    variable_active_storage_damage(pm; kwargs...)
    variable_reactive_storage_damage(pm; kwargs...)
    variable_current_storage_damage(pm; kwargs...)
    _PMs.variable_storage_energy(pm; kwargs...)
    _PMs.variable_storage_charge(pm; kwargs...)
    _PMs.variable_storage_discharge(pm; kwargs...)
    _PMs.variable_storage_complementary_indicator(pm; kwargs...)
end


"do nothing by default but some formulations require this"
function variable_current_storage_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, report::Bool=true)
end

""
function variable_active_storage_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, report::Bool=true)
    inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus))

    ps = _PMs.var(pm, nw)[:ps] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :storage)], base_name="$(nw)_ps_dmg",
        lower_bound = inj_lb[i],
        upper_bound = inj_ub[i],
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, i), "ps_start")
    )

    for i in _PMs.ids(pm, nw, :storage)
        if haskey(_PMs.ref(pm, nw, :storage, i), "damaged") && _PMs.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PMs.var(pm, nw, :ps, i), max(0, inj_ub[i]))
            JuMP.set_lower_bound(_PMs.var(pm, nw, :ps, i), min(0, inj_lb[i]))
        end
    end

    report && _PMs.sol_component_value(pm, nw, :storage, :ps, _PMs.ids(pm, nw, :storage), ps)
end


""
function variable_reactive_storage_damage(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, report::Bool=true)
    inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus))

    qs = _PMs.var(pm, nw)[:qs] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :storage)], base_name="$(nw)_qs_dmg",
        lower_bound = max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin")),
        upper_bound = min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax")),
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, i), "qs_start")
    )
    for i in _PMs.ids(pm, nw, :storage)
        if haskey(_PMs.ref(pm, nw, :storage, i), "damaged") && _PMs.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PMs.var(pm, nw, :ps, i), max(0, min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax"))))
            JuMP.set_lower_bound(_PMs.var(pm, nw, :ps, i), min(0, max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin"))))
        end
    end

    report && _PMs.sol_component_value(pm, nw, :storage, :qs, _PMs.ids(pm, nw, :storage), qs)
end


"variable: `0 <= damage_bus[l] <= 1` for `l` in `bus`es"
function variable_bus_damage_indicator(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if relax == false
        z_bus_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_bus)],
            base_name="$(nw)_active_bus",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, l), "bus_damage_start")
        )
    else
        z_bus_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :damaged_bus)],
            base_name="$(nw)_active_bus",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, l), "bus_damage_start")
        )
    end

    z_bus = Dict(i => haskey(bus, "damaged") && bus["damaged"] == 1 ? z_bus_vars[i] : bus["bus_type"]==4 ? 0 : 1  for (i,bus) in _PMs.ref(pm, nw, :bus))
    _PMs.var(pm, nw)[:z_bus] = z_bus

    report && _PMs.sol_component_value(pm, nw, :bus, :status, _PMs.ids(pm, nw, :bus), z_bus)
end





# ""
# function variable_demand_factor(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax = false)
#     if relax == true
#         _PMs.var(pm, nw)[:z_demand] = JuMP.@variable(pm.model,
#             [i in _PMs.ids(pm, nw, :load)], base_name="$(nw)_z_demand",
#             upper_bound = 1,
#             lower_bound = 0,
#             start = _PMs.comp_start_value(_PMs.ref(pm, nw, :load, i), "z_demand_on_start", 1.0)
#         )
#     else
#         _PMs.var(pm, nw)[:z_demand] = JuMP.@variable(pm.model,
#         [i in _PMs.ids(pm, nw, :load)], base_name="$(nw)_z_demand",
#         binary = true,
#         start = _PMs.comp_start_value(_PMs.ref(pm, nw, :load, i), "z_demand_on_start", 1.0)
#     )
#     end
# end


# ""
# function variable_shunt_factor(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax = false)
#     if relax == true
#         _PMs.var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
#             [i in _PMs.ids(pm, nw, :shunt)], base_name="$(nw)_z_shunt",
#             upper_bound = 1,
#             lower_bound = 0,
#             start = _PMs.comp_start_value(_PMs.ref(pm, nw, :shunt, i), "z_shunt_on_start", 1.0)
#         )
#     else
#         _PMs.var(pm, nw)[:z_shunt] = JuMP.@variable(pm.model,
#             [i in _PMs.ids(pm, nw, :shunt)], base_name="$(nw)_z_shunt",
#             binary = true,
#             start = _PMs.comp_start_value(_PMs.ref(pm, nw, :shunt, i), "z_shunt_on_start", 1.0)
#         )
#     end
# end

function variable_bus_voltage_indicator(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if !relax
        z_voltage = _PMs.var(pm, nw)[:z_voltage] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_z_voltage",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "z_voltage_start")
        )
    else
        z_voltage = _PMs.var(pm, nw)[:z_voltage] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_z_voltage",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "z_voltage_start")
        )
    end

    report && _PMs.sol_component_value(pm, nw, :bus, :status, _PMs.ids(pm, nw, :bus), z_voltage)
end


""
function variable_voltage_magnitude_sqr_on_off(pm::_PMs.AbstractPowerModel; nw::Int=pm.cnw, report::Bool=true)
    w = _PMs.var(pm, nw)[:w] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_w",
        lower_bound = 0,
        upper_bound = _PMs.ref(pm, nw, :bus, i, "vmax")^2,
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "w_start", 1.001)
    )

    report && _PMs.sol_component_value(pm, nw, :bus, :w, _PMs.ids(pm, nw, :bus), w)
end

