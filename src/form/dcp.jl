function constraint_model_voltage_damage(pm::_PM.AbstractDCPModel, n::Int)
end

""
function variable_bus_voltage_damage(pm::_PM.AbstractDCPModel; kwargs...)
    _PM.variable_bus_voltage_angle(pm; kwargs...)
end

# "no vm values to turn off"
# function constraint_bus_damage(pm::_PM.AbstractDCPModel, n::Int, i::Int, vm_min, vm_max)
# end




function variable_bus_voltage_indicator(pm::_PM.AbstractDCPModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    report && _IM.sol_component_fixed(pm, nw, :bus, :status, _PM.ids(pm, nw, :bus), 1.0)
end

function variable_bus_voltage_on_off(pm::_PM.AbstractDCPModel; kwargs...)
    _PM.variable_bus_voltage_angle(pm; kwargs...)
    variable_bus_voltage_magnitude_on_off(pm; kwargs...)
end

function variable_bus_voltage_magnitude_on_off(pm::_PM.AbstractDCPModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    report && _IM.sol_component_fixed(pm, nw, :bus, :vm, _PM.ids(pm, nw, :bus), 1.0)
end


function constraint_bus_voltage_on_off(pm::_PM.AbstractDCPModel; nw::Int=pm.cnw, kwargs...)
end

""
function constraint_power_balance_shed(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    p    = get(_PM.var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = get(_PM.var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(_PM.var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = get(_PM.var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PM.var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    z_demand = get(_PM.var(pm, n), :z_demand, Dict()); _PM._check_var_keys(z_demand, keys(bus_pd), "power factor scale", "load")
    z_shunt = get(_PM.var(pm, n), :z_shunt, Dict()); _PM._check_var_keys(z_shunt, keys(bus_gs), "power factor scale", "shunt")


    _PM.con(pm, n, :kcl_p)[i] = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd*z_demand[i] for (i,pd) in bus_pd)
        - sum(gs*1.0^2*z_shunt[i] for (i,gs) in bus_gs)
    )
end


# Needed becouse DC models do not have the z_voltage variable
function objective_max_loadability(pm::_PM.AbstractDCPModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    M = Dict(n => 10*maximum([load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]) for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum(
            (
                time_elapsed[n]*(
                 sum(M[n]*z_gen[n][i] for (i,gen) in _PM.ref(pm, n, :gen)) +
                 sum(M[n]*z_shunt[n][i] for (i,shunt) in _PM.ref(pm, n, :shunt)) +
                 sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
             )
            )
        for n in nws)
    )
end

# can we just add storage to the regular max_loadability objective? #
function objective_max_loadability_strg(pm::_PM.AbstractDCPModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    z_storage = Dict(n => _PM.var(pm, n, :z_storage) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    M = Dict(n => 10*maximum([load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]) for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum(
            (
                time_elapsed[n]*(
                 sum(M[n]*z_gen[n][i] for (i,gen) in _PM.ref(pm, n, :gen)) +
                 sum(M[n]*z_storage[n][i] for (i,storage) in _PM.ref(pm, n, :storage)) +
                 sum(M[n]*z_shunt[n][i] for (i,shunt) in _PM.ref(pm, n, :shunt)) +
                 sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
             )
            )
        for n in nws)
    )
end


### These are needed to overload the default behavior for reactive power ###
"no vm values to turn off"
function constraint_voltage_violation_damage(pm::_PM.AbstractDCPModel, n::Int, i::Int, vm_min, vm_max)
end

"no vm values to turn off"
function constraint_bus_voltage_violation(pm::_PM.AbstractDCPModel, n::Int, i::Int, vm_min, vm_max)
end
