function objective_max_loadability(pm::_PMs.GenericPowerModel)
    nws = _PMs.nw_ids(pm)

    @assert all(!_PMs.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PMs.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PMs.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PMs.var(pm, n, :z_gen) for n in nws)
    z_storage = Dict(n => _PMs.var(pm, n, :z_storage) for n in nws)
    z_voltage = Dict(n => _PMs.var(pm, n, :z_voltage) for n in nws)
    time_elapsed = Dict(n => pm.data["nw"]["$(n)"]["time_elapsed"] for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PMs.ref(pm, n, :load)) 
    for n in nws)

    M = Dict(n => maximum([load_weight[n][i]*abs(load["pd"]) for (i,load) in _PMs.ref(pm, n, :load)]) for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum( 
            ( 
            time_elapsed[n]*(
                sum(M[n]*10*z_voltage[n][i] for (i,bus) in _PMs.ref(pm, n, :bus)) +
                sum(M[n]*z_gen[n][i] for (i,gen) in _PMs.ref(pm, n, :gen)) +
                sum(M[n]*z_storage[n][i] for (i,storage) in _PMs.ref(pm, n, :storage)) +
                sum(M[n]*z_shunt[n][i] for (i,shunt) in _PMs.ref(pm, n, :shunt)) +
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PMs.ref(pm, n, :load))
                ) 
            )
            for n in nws)
        )
end
