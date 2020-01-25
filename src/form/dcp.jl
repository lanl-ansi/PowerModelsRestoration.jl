function constraint_model_voltage_damage(pm::_PMs.AbstractDCPModel, n::Int, c::Int)
end

""
function variable_voltage_damage(pm::_PMs.AbstractDCPModel; kwargs...)
    _PMs.variable_voltage_angle(pm; kwargs...)
end

"no vm values to turn off"
function constraint_bus_damage(pm::_PMs.AbstractDCPModel, n::Int, c::Int, i::Int, vm_min, vm_max)
end




function variable_bus_voltage_indicator(pm::_PMs.AbstractDCPModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, kwargs...)
end

variable_bus_voltage_on_off(pm::_PMs.AbstractDCPModel; kwargs...) = _PMs.variable_voltage_angle(pm; kwargs...)

function constraint_bus_voltage_on_off(pm::_PMs.AbstractDCPModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, kwargs...)
end

""
function constraint_power_balance_shed(pm::_PMs.AbstractDCPModel, n::Int, c::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    p    = get(_PMs.var(pm, n, c),    :p, Dict()); _PMs._check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = get(_PMs.var(pm, n, c),   :pg, Dict()); _PMs._check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(_PMs.var(pm, n, c),   :ps, Dict()); _PMs._check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = get(_PMs.var(pm, n, c),  :psw, Dict()); _PMs._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(_PMs.var(pm, n, c), :p_dc, Dict()); _PMs._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    z_demand = get(_PMs.var(pm, n), :z_demand, Dict()); _PMs._check_var_keys(z_demand, keys(bus_pd), "power factor scale", "load")
    z_shunt = get(_PMs.var(pm, n), :z_shunt, Dict()); _PMs._check_var_keys(z_shunt, keys(bus_gs), "power factor scale", "shunt")


    _PMs.con(pm, n, c, :kcl_p)[i] = JuMP.@constraint(pm.model,
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
function objective_max_loadability(pm::_PMs.AbstractDCPModel)
    nws = _PMs.nw_ids(pm)

    @assert all(!_PMs.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PMs.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PMs.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PMs.var(pm, n, :z_gen) for n in nws)
    time_elapsed = Dict(n => get(_PMs.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PMs.ref(pm, n, :load)) 
    for n in nws)
	
    M = Dict(n => 10*maximum([load_weight[n][i]*abs(load["pd"]) for (i,load) in _PMs.ref(pm, n, :load)]) for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum( 
            ( 
                time_elapsed[n]*(
                 sum(M[n]*z_gen[n][i] for (i,gen) in _PMs.ref(pm, n, :gen)) +
                 sum(M[n]*z_shunt[n][i] for (i,shunt) in _PMs.ref(pm, n, :shunt)) +
                 sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PMs.ref(pm, n, :load))
             ) 
            )
        for n in nws)
    )
end

# can we just add storage to the regular max_loadability objective? #
function objective_max_loadability_strg(pm::_PMs.AbstractDCPModel)
    nws = _PMs.nw_ids(pm)

    @assert all(!_PMs.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PMs.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PMs.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PMs.var(pm, n, :z_gen) for n in nws)
    z_storage = Dict(n => _PMs.var(pm, n, :z_storage) for n in nws)
    time_elapsed = Dict(n => get(_PMs.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PMs.ref(pm, n, :load)) 
    for n in nws)
	
    M = Dict(n => 10*maximum([load_weight[n][i]*abs(load["pd"]) for (i,load) in _PMs.ref(pm, n, :load)]) for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum( 
            ( 
                time_elapsed[n]*(
                 sum(M[n]*z_gen[n][i] for (i,gen) in _PMs.ref(pm, n, :gen)) +
                 sum(M[n]*z_storage[n][i] for (i,storage) in _PMs.ref(pm, n, :storage)) +
                 sum(M[n]*z_shunt[n][i] for (i,shunt) in _PMs.ref(pm, n, :shunt)) +
                 sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PMs.ref(pm, n, :load))
             ) 
            )
        for n in nws)
    )
end


### These are needed to overload the default behavior for reactive power ###

function add_setpoint_load!(sol, pm::_PMs.AbstractDCPModel)
    _PMs.add_setpoint!(sol, pm, "load", "pd", :z_demand; conductorless=true, scale = (x,item,i) -> x*item["pd"][i])
    _PMs.add_setpoint_fixed!(sol, pm, "load", "qd")
    _PMs.add_setpoint!(sol, pm, "load", "status", :z_demand; conductorless=true, default_value = (item) -> if (item["status"] == 0) 0 else 1 end)
end

function add_setpoint_shunt!(sol, pm::_PMs.AbstractDCPModel)
    _PMs.add_setpoint!(sol, pm, "shunt", "gs", :z_shunt; conductorless=true, scale = (x,item,i) -> x*item["gs"][i])
    _PMs.add_setpoint_fixed!(sol, pm, "shunt", "bs")
    _PMs.add_setpoint!(sol, pm, "shunt", "status", :z_shunt; conductorless=true, default_value = (item) -> if (item["status"] == 0) 0 else 1 end)
end

#=
function add_setpoint_bus_status!(sol, pm::_PMs.AbstractDCPModel)
    _PMs.add_setpoint_fixed!(sol, pm, "bus", "status")
end
=#

