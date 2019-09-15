"Compute forward restoration of network_data"
function run_restoration_simulation(network_data, model_constructor, optimizer; kwargs...)
    _network_data = deepcopy(network_data)

    clean_status!(_network_data)
    net_id = map(x->parse(Int,x), sort(collect(keys(_network_data["nw"]))))

    for n in net_id
        network = _network_data["nw"]["$n"]
        network["per_unit"] = _network_data["per_unit"]

        result = _PMs.run_model(network, model_constructor, optimizer, _MLD.post_mld_strg; solution_builder=solution_rop, kwargs...)
        _network_data["nw"]["$n"]["solution"] = result
        network_forward = get(_network_data["nw"],"$(n+1)", Dict())

        # TODO is this the correct way to update storage energy?
        #=
        for (j, storage) in get(network_forward, "storage", Dict())
            energy = solution["solution"]["storage"]["$j"]["se"]
            if !isnan(energy)
                storage["energy"] = energy
            else # if network fails to solve, then set energy value to previous network's energy value
                storage["energy"] = _network_data["nw"]["$(n-1)"]["storage"]["$j"]["energy"]
            end
        end
        =#

        active_power_served = sum(load["pd"] for (i,load) in result["solution"]["load"])
        Memento.warn(_PMs._LOGGER, "restoration step $(n), objective $(result["objective"]), active power $(active_power_served)")
    end

    return solution = process_network(_network_data)
end
