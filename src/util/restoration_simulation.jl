# "Compute forward restoration of network_data"
# function run_restoration_simulation(network_data, model_constructor, optimizer; kwargs...)
#     _network_data = deepcopy(network_data)

#     clean_status!(_network_data)
#     net_id = map(x->parse(Int,x), sort(collect(keys(_network_data["nw"]))))

#     for n in net_id
#         network = _network_data["nw"]["$n"]
#         network["per_unit"] = _network_data["per_unit"]

#         result = _PMs.run_model(network, model_constructor, optimizer, _MLD.build_mld_strg; solution_builder=solution_rop, kwargs...)
#         _network_data["nw"]["$n"]["solution"] = result
#         network_forward = get(_network_data["nw"],"$(n+1)", Dict())

#         # TODO is this the correct way to update storage energy?
#         #=
#         for (j, storage) in get(network_forward, "storage", Dict())
#             energy = result["solution"]["storage"]["$j"]["se"]
#             if !isnan(energy)
#                 storage["energy"] = energy
#             else # if network fails to solve, then set energy value to previous network's energy value
#                 storage["energy"] = _network_data["nw"]["$(n-1)"]["storage"]["$j"]["energy"]
#             end
#         end
#         =#

#         active_power_served = sum(load["pd"] for (i,load) in result["solution"]["load"])
#         Memento.warn(_PMs._LOGGER, "restoration step $(n), objective $(result["objective"]), active power $(active_power_served)")
#     end

#     return process_network(_network_data)
# end

"Simulate a restoration sequence power flow"
function run_restoration_simulation(file::String, model_type::Type, optimizer; kwargs...)
    data = _PMs.parse_file(file)
    return run_restoration_simulation(data, model_type, optimizer; kwargs...)
end

"Simulate a restoration sequence power flow"
function run_restoration_simulation(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    clear_damage_indicator!(data)
    return run_rop(data, model_type::Type, optimizer; kwargs...)
end

# ""
# function build_restoration_simulation(pm::_PMs.AbstractPowerModel)
#     for (n, network) in _PMs.nws(pm)
#         _PMs.variable_voltage(pm, nw=n)
#         _PMs.variable_generation(pm, nw=n)
#         _PMs.variable_storage(pm, nw=n)
#         _PMs.variable_branch_flow(pm, nw=n)
#         _PMs.variable_dcline_flow(pm, nw=n)

#         _PMs.constraint_model_voltage(pm, nw=n)

#         _MLD.variable_demand_factor(pm, nw=n, relax=true)
#         _MLD.variable_shunt_factor(pm, nw=n, relax=true)

#         for i in _PMs.ids(pm, :ref_buses, nw=n)
#             _PMs.constraint_theta_ref(pm, i, nw=n)
#         end

#         for i in _PMs.ids(pm, :bus, nw=n)
#             _MLD.constraint_power_balance_shed(pm, i, nw=n)
#         end

#         for i in _PMs.ids(pm, :storage, nw=n)
#             _PMs.constraint_storage_complementarity_nl(pm, i, nw=n)
#             _PMs.constraint_storage_loss(pm, i, nw=n)
#             _PMs.constraint_storage_thermal_limit(pm, i, nw=n)
#         end

#         for i in _PMs.ids(pm, :branch, nw=n)
#             _PMs.constraint_ohms_yt_from(pm, i, nw=n)
#             _PMs.constraint_ohms_yt_to(pm, i, nw=n)

#             _PMs.constraint_voltage_angle_difference_on_off(pm, i, nw=n)

#             _PMs.constraint_thermal_limit_from(pm, i, nw=n)
#             _PMs.constraint_thermal_limit_to(pm, i, nw=n)
#         end

#         for i in _PMs.ids(pm, :dcline, nw=n)
#             _PMs.constraint_dcline(pm, i, nw=n)
#         end
#     end

#     network_ids = sort(collect(_PMs.nw_ids(pm)))

#     n_1 = network_ids[1]
#     for i in _PMs.ids(pm, :storage, nw=n_1)
#         _PMs.constraint_storage_state(pm, i, nw=n_1)
#     end

#     for n_2 in network_ids[2:end]
#         for i in _PMs.ids(pm, :storage, nw=n_2)
#             _PMs.constraint_storage_state(pm, i, n_1, n_2)
#         end
#         n_1 = n_2
#     end

#     objective_max_load_delivered(pm)
# end

