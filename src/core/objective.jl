function objective_max_load_delivered(pm::_PMs.AbstractPowerModel)
    nws = _PMs.nw_ids(pm)

    @assert all(!_PMs.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PMs.var(pm, n, :z_demand) for n in nws)
    time_elapsed = Dict(n => get(_PMs.ref(pm, n), :time_elapsed, 1.0) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PMs.ref(pm, n, :load))
    for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum(
            time_elapsed[n]*(
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PMs.ref(pm, n, :load))
            )
        for n in nws)
    )
end
