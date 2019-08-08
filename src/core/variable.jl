"Need because of mix of vars/real in z_gen, z_branch, z_storage"
function JuMP.value(x::Real) return x end


"variable: `0 <= damage_gen[l] <= 1` for `l` in `gen`es"
function variable_generation_damage_indicator(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, relax=false)

    if relax == false
        z_gen_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :gen_damaged)],
            base_name="$(nw)_damage_gen",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, l), "gen_damage_start", 1, 0.0)
        )
    else
        z_gen_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :gen_damaged)],
            base_name="$(nw)_damage_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, l), "gen_damage_start", 1, 0.0)
        )
    end

    z_gen = Dict(i => haskey(gen, "damaged") && gen["damaged"] == 1 ? z_gen_vars[i] : gen["gen_status"]  for (i,gen) in _PMs.ref(pm, nw, :gen))
    _PMs.var(pm, nw)[:z_gen] = z_gen
end


"generates variables for both `active` and `reactive` generation"
function variable_generation_damage(pm::_PMs.GenericPowerModel; kwargs...)
    variable_active_generation_damage(pm; kwargs...)
    variable_reactive_generation_damage(pm; kwargs...)
end


"variable: `pg[j]` for `j` in `gen`"
function variable_active_generation_damage(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    for i in _PMs.ids(pm, nw, :gen)
        if bounded
            _PMs.var(pm, nw, cnd)[:pg] = JuMP.@variable(pm.model,
                [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_pg",
                lower_bound = _PMs.ref(pm, nw, :gen, i, "pmin", cnd),
                upper_bound = _PMs.ref(pm, nw, :gen, i, "pmax", cnd),
                start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "pg_start", cnd)
            )
            for i in _PMs.ids(pm, nw, :gen)
                if haskey(_PMs.ref(pm, nw, :gen, i), "damaged") && _PMs.ref(pm, nw, :gen,i)["damaged"] == 1
                    JuMP.set_upper_bound(_PMs.var(pm, nw, cnd, :pg, i), max(0, _PMs.ref(pm, nw, :gen, i, "pmax", cnd)))
                    JuMP.set_lower_bound(_PMs.var(pm, nw, cnd, :pg, i), min(0, _PMs.ref(pm, nw, :gen, i, "pmin", cnd)))
                end
            end
        else
            _PMs.var(pm, nw, cnd)[:pg] = JuMP.@variable(pm.model,
                [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_pg",
                start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "pg_start", cnd)
            )
        end
    end
end


"variable: `qq[j]` for `j` in `gen`"
function variable_reactive_generation_damage(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    if bounded
        _PMs.var(pm, nw, cnd)[:qg] = JuMP.@variable(pm.model,
            [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_qg",
            lower_bound = _PMs.ref(pm, nw, :gen, i, "qmin", cnd),
            upper_bound = _PMs.ref(pm, nw, :gen, i, "qmax", cnd),
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "qg_start", cnd)
        )
    else
        _PMs.var(pm, nw, cnd)[:qg] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_$(cnd)_qg",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, i), "qg_start", cnd)
    )
    end

    for i in _PMs.ids(pm, nw, :gen)
        if haskey(_PMs.ref(pm, nw, :gen, i), "damaged") && _PMs.ref(pm, nw, :gen,i)["damaged"] == 1
            JuMP.set_upper_bound(_PMs.var(pm, nw, cnd, :pg, i), max(0, _PMs.ref(pm, nw, :gen, i, "qmax", cnd)))
            JuMP.set_lower_bound(_PMs.var(pm, nw, cnd, :pg, i), min(0, _PMs.ref(pm, nw, :gen, i, "qmin", cnd)))
        end
    end
end


"variable: `0 <= damage_branch[l] <= 1` for `l` in `branch`es"
function variable_branch_damage_indicator(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, relax=false)

    if relax == false
        z_branch_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :branch_damaged)],
            base_name="$(nw)_damage_branch",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "branch_damage_start", 1, 0.0)
        )
    else
        z_branch_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :branch_damaged)],
            base_name="$(nw)_damage_branch",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "branch_damage_start", 1, 0.0)
        )
    end

    z_branch = Dict(i => haskey(branch, "damaged") && branch["damaged"] == 1 ? z_branch_vars[i] : branch["br_status"]  for (i,branch) in _PMs.ref(pm, nw, :branch))

    _PMs.var(pm, nw, cnd)[:branch_z] = z_branch

end


"variable: `0 <= damage_storage[l] <= 1` for `l` in `storage`es"
function variable_storage_damage_indicator(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, relax = false)
    if relax == false
        z_storage_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :storage_damaged)],
            base_name="$(nw)storage",
            binary = true,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, l), "storage_damage_start", 1, 0.0)
        )
    else
        z_storage_vars = JuMP.@variable(pm.model,
            [l in _PMs.ids(pm, nw, :storage_damaged)],
            base_name="$(nw)storage",
            lower_bound = 0,
            upper_bound = 1,
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, l), "storage_damage_start", 1, 0.0)
        )
    end

    z_storage = Dict(i => haskey(storage, "damaged") && storage["damaged"] == 1 ? z_storage_vars[i] : storage["status"]  for (i,storage) in _PMs.ref(pm, nw, :storage))
    _PMs.var(pm, nw)[:z_storage] = z_storage

end


""
function variable_storage_mi_damage(pm::_PMs.GenericPowerModel; kwargs...)
    variable_active_storage_damage(pm; kwargs...)
    variable_reactive_storage_damage(pm; kwargs...)
    _PMs.variable_storage_energy(pm; kwargs...)
    _PMs.variable_storage_charge(pm; kwargs...)
    _PMs.variable_storage_discharge(pm; kwargs...)
    _PMs.variable_storage_complementary_indicator(pm; kwargs...)
end


""
function variable_active_storage_damage(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus), cnd)

    _PMs.var(pm, nw, cnd)[:ps] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :storage)], base_name="$(nw)_$(cnd)_ps",
        lower_bound = inj_lb[i],
        upper_bound = inj_ub[i],
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, i), "ps_start", cnd)
    )

    for i in _PMs.ids(pm, nw, :storage)
        if haskey(_PMs.ref(pm, nw, :storage, i), "damaged") && _PMs.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PMs.var(pm, nw, cnd, :ps, i), max(0, inj_ub[i]))
            JuMP.set_lower_bound(_PMs.var(pm, nw, cnd, :ps, i), min(0, inj_lb[i]))
        end
    end
end


""
function variable_reactive_storage_damage(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd)
    inj_lb, inj_ub = _PMs.ref_calc_storage_injection_bounds(_PMs.ref(pm, nw, :storage), _PMs.ref(pm, nw, :bus), cnd)

    _PMs.var(pm, nw, cnd)[:qs] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :storage)], base_name="$(nw)_$(cnd)_qs",
        lower_bound = max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin", cnd)),
        upper_bound = min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax", cnd)),
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :storage, i), "qs_start", cnd)
    )
    for i in _PMs.ids(pm, nw, :storage)
        if haskey(_PMs.ref(pm, nw, :storage, i), "damaged") && _PMs.ref(pm, nw, :storage, i)["damaged"] == 1
            JuMP.set_upper_bound(_PMs.var(pm, nw, cnd, :ps, i), max(0, min(inj_ub[i], _PMs.ref(pm, nw, :storage, i, "qmax", cnd))))
            JuMP.set_lower_bound(_PMs.var(pm, nw, cnd, :ps, i), min(0, max(inj_lb[i], _PMs.ref(pm, nw, :storage, i, "qmin", cnd))))
        end
    end
end
