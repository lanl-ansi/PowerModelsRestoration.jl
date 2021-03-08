function objective_max_load_delivered(pm::_PM.AbstractPowerModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1.0) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    return JuMP.@objective(pm.model, Max,
        sum(
            time_elapsed[n]*(
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
            )
        for n in nws)
    )
end


function objective_max_load_delivered(pm::_PM.AbstractACPModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    vm_vio = Dict(n => _PM.var(pm, :vm_vio, nw=n) for n in nws)
    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1.0) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    M = Dict()
    for n in nws
        if !isempty(load_weight[n])
            M[n] = 10*maximum(abs.(values(load_weight[n])))
        else
            M[n]= 10
        end
    end

    return JuMP.@objective(pm.model, Max,
        sum(
            time_elapsed[n]*(
                sum(-M[n]*vm_vio[n][i] for (i,bus) in _PM.ref(pm, n, :bus)) +
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
            )
        for n in nws)
    )
end

function objective_max_load_delivered(pm::_PM.AbstractWRModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    w_vio = Dict(n => _PM.var(pm, :w_vio, nw=n) for n in nws)
    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1.0) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

        M = Dict()
        for n in nws
            if !isempty(load_weight[n])
                M[n] = 10*maximum(abs.(values(load_weight[n])))
            else
                M[n]= 10
            end
        end

    return JuMP.@objective(pm.model, Max,
        sum(
            time_elapsed[n]*(
                sum(-M[n]*w_vio[n][i] for (i,bus) in _PM.ref(pm, n, :bus)) +
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
            )
        for n in nws)
    )
end



function objective_max_loadability(pm::_PM.AbstractPowerModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    z_voltage = Dict(n => _PM.var(pm, n, :z_voltage) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    #println(load_weight)

    M = Dict()
    for n in nws
        scaled_weight = [load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]
        if isempty(scaled_weight)
            scaled_weight = [1.0]
        end
        M[n] = 10*maximum(scaled_weight)
    end

    return JuMP.@objective(pm.model, Max,
        sum(
            (
            time_elapsed[n]*(
                sum(M[n]*10*z_voltage[n][i] for (i,bus) in _PM.ref(pm, n, :bus)) +
                sum(M[n]*z_gen[n][i] for (i,gen) in _PM.ref(pm, n, :gen)) +
                sum(M[n]*z_shunt[n][i] for (i,shunt) in _PM.ref(pm, n, :shunt)) +
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
                )
            )
            for n in nws)
        )

    #return JuMP.@objective(pm.model, Max, sum( M*z_gen[i] for (i,gen) in pm.ref[:gen]) + sum( M*z_shunt[i] + abs(bus["pd"])*z_demand[i] for (i,bus) in pm.ref[:bus]))

    #return JuMP.@objective(pm.model, Max, sum(abs(bus["pd"])*z_demand[i] for (i,bus) in pm.ref[:bus]))

    #pg = pm.var[:pg]
    #M = maximum([abs(gen["pmax"]) for (i,gen) in pm.ref[:gen]])
    #return JuMP.@objective(pm.model, Max, sum(z_gen[i] + pg[i] for (i,gen) in pm.ref[:gen]) + sum(M/10*z_voltage[i]^2 + M*abs(bus["pd"])*z_demand[i] for (i,bus) in pm.ref[:bus]))
end

# can we just add storage to the regular max_loadability objective? #
function objective_max_loadability_strg(pm::_PM.AbstractPowerModel)
    nws = _PM.nw_ids(pm)

    @assert all(!_PM.ismulticonductor(pm, n) for n in nws)

    z_demand = Dict(n => _PM.var(pm, n, :z_demand) for n in nws)
    z_shunt = Dict(n => _PM.var(pm, n, :z_shunt) for n in nws)
    z_gen = Dict(n => _PM.var(pm, n, :z_gen) for n in nws)
    z_storage = Dict(n => _PM.var(pm, n, :z_storage) for n in nws)
    z_voltage = Dict(n => _PM.var(pm, n, :z_voltage) for n in nws)
    time_elapsed = Dict(n => get(_PM.ref(pm, n), :time_elapsed, 1) for n in nws)

    load_weight = Dict(n =>
        Dict(i => get(load, "weight", 1.0) for (i,load) in _PM.ref(pm, n, :load))
    for n in nws)

    #println(load_weight)

    M = Dict()
    for n in nws
        scaled_weight = [load_weight[n][i]*abs(load["pd"]) for (i,load) in _PM.ref(pm, n, :load)]
        if isempty(scaled_weight)
            scaled_weight = [1.0]
        end
        M[n] = 10*maximum(scaled_weight)
    end

    return JuMP.@objective(pm.model, Max,
        sum(
            (
            time_elapsed[n]*(
                sum(M[n]*10*z_voltage[n][i] for (i,bus) in _PM.ref(pm, n, :bus)) +
                sum(M[n]*z_gen[n][i] for (i,gen) in _PM.ref(pm, n, :gen)) +
                sum(M[n]*z_storage[n][i] for (i,storage) in _PM.ref(pm, n, :storage)) +
                sum(M[n]*z_shunt[n][i] for (i,shunt) in _PM.ref(pm, n, :shunt)) +
                sum(load_weight[n][i]*abs(load["pd"])*z_demand[n][i] for (i,load) in _PM.ref(pm, n, :load))
                )
            )
            for n in nws)
        )

    #return JuMP.@objective(pm.model, Max, sum( M*z_gen[i] for (i,gen) in pm.ref[:gen]) + sum( M*z_shunt[i] + abs(bus["pd"])*z_demand[i] for (i,bus) in pm.ref[:bus]))

    #return JuMP.@objective(pm.model, Max, sum(abs(bus["pd"])*z_demand[i] for (i,bus) in pm.ref[:bus]))

    #pg = pm.var[:pg]
    #M = maximum([abs(gen["pmax"]) for (i,gen) in pm.ref[:gen]])
    #return JuMP.@objective(pm.model, Max, sum(z_gen[i] + pg[i] for (i,gen) in pm.ref[:gen]) + sum(M/10*z_voltage[i]^2 + M*abs(bus["pd"])*z_demand[i] for (i,bus) in pm.ref[:bus]))
end

