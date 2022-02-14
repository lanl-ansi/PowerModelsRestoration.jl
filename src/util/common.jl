
"""
        `_fill_missing_variables!(sol::Dict{String,<:Any}, network::Dict{String,<:Any})`
    add network values for components removed for status=0 from solution
"""
function _fill_missing_variables!(sol::Dict{String,<:Any}, network::Dict{String,<:Any})

    # Is there a way to do this based on formulation, any default comps?
    variable_fill = Dict(
        "bus"=>Dict{String,Any}("va"=>0.0,"status"=>0, "bus_type"=>4, "vm"=>NaN),
        "gen"=>Dict{String,Any}("gen_status"=>0,"pg"=>0.0, "qg"=>NaN),
        "branch"=>Dict{String,Any}("qf"=>NaN,"qt"=>NaN,"br_status"=>0,"pt"=>0.0,"pf"=>0.0),
        "dcline"=>Dict{String,Any}("qf"=>NaN,"qt"=>NaN,"br_status"=>0,"pt"=>0.0,"pf"=>0.0),
        "load"=>Dict{String,Any}("status"=>0.0,"qd"=>0.0,"pd"=>0.0),
        "shunt"=>Dict{String,Any}("status"=>0, "gs"=>0.0, "bs"=>0.0),
        #"storage"=>Dict{String,Any}("status"=>0) verify storage is working
    )

    for (nw_id, sol_net) in sol["solution"]["nw"]
        for (comp_type,comp_vars) in variable_fill
            for (comp_id,comp_net) in network[comp_type]
                if !(haskey(sol_net,comp_type))
                    sol_net[comp_type] = Dict{String,Any}()
                end
                if !(haskey(sol_net[comp_type], comp_id))
                    sol_net[comp_type][comp_id]=comp_vars
                end
            end
        end
    end
end


"get repairs in each period of the solution data"
function get_component_activations(solution_dict)
    if !_IM.ismultinetwork(solution_dict)
        Memento.error(_PM._LOGGER, "get_component_activations requires multinetwork.")
    end

    repairs = Dict{String,Any}("$nwid"=>Tuple{String,String}[] for nwid in keys(solution_dict["nw"]))
    for (nw_id, net) in solution_dict["nw"]
        for comp_type in restoration_components
            status_key = _PM.pm_component_status[comp_type]
            for (comp_id, comp) in get(net, comp_type, Dict())
                if nw_id != "0" #not items are repaired in "0", do not check in previous net for a change
                    if comp[status_key] != _PM.pm_component_status_inactive[comp_type] &&  # if comp is active
                        solution_dict["nw"]["$(parse(Int,nw_id)-1)"][comp_type][comp_id][status_key] == _PM.pm_component_status_inactive[comp_type] # if comp was previously inactive
                        push!(repairs[nw_id], (comp_type,comp_id))
                    end
                end
            end
        end
    end
    return repairs
end


"count repairs in each period of the solution data"
function _count_component_repairs(solution_dict)
    repairs = get_component_activations(solution_dict)
    repair_count = Dict{String,Int}(nw=>length(nw_repairs) for (nw, nw_repairs) in repairs )
    return repair_count
end


"count the cumulative repairs in each period of the solution data"
function _count_cumulative_component_repairs(solution_dict)
    repair_count = _count_component_repairs(solution_dict)

    cumulative_count = Dict{String,Int}(nw_id=>0 for nw_id in keys(repair_count))
    end_nw_id = maximum(parse.(Int,keys(repair_count)))

    for (nw_id, count) in repair_count
        for id in parse(Int,nw_id):end_nw_id
            cumulative_count["$(id)"]+= count
        end
    end
    return cumulative_count
end


"""
Update sol_1 dictionary with sol_2 dictionary. `termination_status`, `primal_status`, and `dual_status`
values are the maximum of the MOI status code. `solvetime`,`objective`, and `objective_lb` are accumulated. The
`solution` dictionary is merged using `PowerModels.update_data(sol_1["solution"],sol_2["solution"])`.
"""
function merge_solution!(sol_1, sol_2)
    Memento.info(_PM._LOGGER, "networks $(keys(sol_2["solution"]["nw"])) finished with status $(sol_2["termination_status"])")

    sol_1["termination_status"] = _compare_termination_statuses([sol_1["termination_status"],sol_2["termination_status"]])
    sol_1["primal_status"] =  _compare_result_statuses([sol_1["primal_status"],sol_2["primal_status"]])
    sol_1["dual_status"] =  _compare_result_statuses([sol_1["dual_status"],sol_2["dual_status"]])
    sol_1["solve_time"] += sol_2["solve_time"]
    sol_1["objective"] += sol_2["objective"]
    sol_1["objective_lb"] += sol_2["objective_lb"]
end



function _compare_termination_statuses(statuses::Vector{JuMP.TerminationStatusCode})
    for status in statuses
        if status == JuMP.INFEASIBLE
            return JuMP.INFEASIBLE
        elseif status != JuMP.OPTIMAL && status != JuMP.LOCALLY_SOLVED
            return JuMP.UNKNOWN_STATUS
        end
    end
    return JuMP.OPTIMAL
end

function _compare_result_statuses(statuses::Vector{JuMP.ResultStatusCode})
    for status in statuses
        if status == JuMP.NO_SOLUTION
            return JuMP.NO_SOLUTION
        elseif status != JuMP.FEASIBLE_POINT
            return JuMP.UNKNOWN_RESULT_STATUS
        end
    end
    return JuMP.FEASIBLE_POINT
end


"Create a restoration network with 1 repair per time period. Final period will contain remainder repairs."
function _single_repair_restoration_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String}=Set{String}())
    union(global_keys, _PM._pm_global_keys)
    pm_sn_data = _PM.get_pm_data(sn_data)

    @assert count > 0
    if _IM.ismultinetwork(pm_sn_data)
        Memento.error(_PM._LOGGER, "_single_repair_restoration_network can only be used on single networks")
    end

    clean_status!(pm_sn_data)
    propagate_damage_status!(pm_sn_data)

    name = get(pm_sn_data, "name", "anonymous")

    mn_data = Dict{String,Any}(
    "nw" => Dict{String,Any}(),
    "multinetwork" => true
    )

    pm_sn_data_tmp = deepcopy(pm_sn_data)
    for k in global_keys
        if haskey(pm_sn_data_tmp, k)
            mn_data[k] = pm_sn_data_tmp[k]
        end

        # note this is robust to cases where k is not present in pm_sn_data_tmp
        delete!(pm_sn_data_tmp, k)
    end

    total_repairs = count_repairable_components(pm_sn_data)

    mn_data["name"] = "$(count) period restoration of $(name)"
    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(pm_sn_data_tmp)
    end

    mn_data["nw"]["0"]["repairs"] = 0
    mn_data["nw"]["0"]["repaired_total"] = 0
    for n in 1:count
        if n < count
            mn_data["nw"]["$n"]["repairs"] = n > total_repairs ? 0 : 1
        else
            mn_data["nw"]["$n"]["repairs"] = max(total_repairs-count+1,0)
        end

        mn_data["nw"]["$(n-1)"]["time_elapsed"] = mn_data["nw"]["$n"]["repairs"] * get(mn_data["nw"]["$(n-1)"], "time_elapsed", 1.0)
        mn_data["nw"]["$n"]["repaired_total"] = sum(mn_data["nw"]["$(nw)"]["repairs"] for nw=0:n)
    end
    mn_data["nw"]["$(count)"]["time_elapsed"] = get(mn_data["nw"]["$(count)"], "time_elapsed", 1.0)

    return mn_data
end


"Variation of run_rop that permits some load not to be restored in final period. Useful for partial restoration of a network in rop heuristics"
function _run_partial_rop(file, model_constructor, optimizer; kwargs...)
    return _PM.run_model(file, model_constructor, optimizer, _build_partial_rop; multinetwork=true,
        ref_extensions=[_PM.ref_add_on_off_va_bounds!, ref_add_damaged_components!], kwargs...)
end


""
function _build_partial_rop(pm::_PM.AbstractPowerModel)
    for (n, network) in _PM.nws(pm)
        variable_bus_damage_indicator(pm, nw=n)
        variable_bus_voltage_damage(pm, nw=n)

        variable_branch_damage_indicator(pm, nw=n)
        _PM.variable_branch_power(pm, nw=n)

        _PM.variable_dcline_power(pm, nw=n)

        variable_storage_damage_indicator(pm, nw=n)
        variable_storage_power_mi_damage(pm, nw=n)

        variable_gen_damage_indicator(pm, nw=n)
        variable_gen_power_damage(pm, nw=n)

        _PM.variable_load_power_factor(pm, nw=n, relax=true)
        _PM.variable_shunt_admittance_factor(pm, nw=n, relax=true)

        constraint_restoration_cardinality_ub(pm, nw=n)

        constraint_model_voltage_damage(pm, nw=n)

        for i in _PM.ids(pm, :ref_buses, nw=n)
            _PM.constraint_theta_ref(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :bus, nw=n)
            constraint_bus_damage_soft(pm, i, nw=n)
            constraint_power_balance_shed(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :gen, nw=n)
            constraint_gen_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :load, nw=n)
            constraint_load_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :shunt, nw=n)
            constraint_shunt_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :branch, nw=n)
            constraint_branch_damage(pm, i, nw=n)
            constraint_ohms_yt_from_damage(pm, i, nw=n)
            constraint_ohms_yt_to_damage(pm, i, nw=n)

            constraint_voltage_angle_difference_damage(pm, i, nw=n)

            constraint_thermal_limit_from_damage(pm, i, nw=n)
            constraint_thermal_limit_to_damage(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :dcline, nw=n)
            _PM.constraint_dcline_power_losses(pm, i, nw=n)
        end

        for i in _PM.ids(pm, :storage, nw=n)
            constraint_storage_damage(pm, i, nw=n)
            _PM.constraint_storage_complementarity_mi(pm, i, nw=n)
            _PM.constraint_storage_losses(pm, i, nw=n)
        end
    end


    network_ids = sort(collect(_PM.nw_ids(pm)))
    n_1 = network_ids[1]
    for i in _PM.ids(pm, :storage, nw=n_1)
        _PM.constraint_storage_state(pm, i, nw=n_1)
    end

    for n_2 in network_ids[2:end]
        for i in _PM.ids(pm, :storage, nw=n_2)
            _PM.constraint_storage_state(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :gen, nw=n_2)
            constraint_gen_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :bus, nw=n_2)
            constraint_bus_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :storage, nw=n_2)
            constraint_storage_energized(pm, i, n_1, n_2)
        end
        for i in _PM.ids(pm, :branch, nw=n_2)
            constraint_branch_energized(pm, i, n_1, n_2)
        end
        n_1 = n_2
    end

    # restore all devices
    n_final = last(network_ids)
    z_storage = _PM.var(pm, n_final, :z_storage)
    z_gen = _PM.var(pm, n_final, :z_gen)
    z_branch = _PM.var(pm, n_final, :z_branch)
    z_bus = _PM.var(pm, n_final, :z_bus)
    for (i,storage) in  _PM.ref(pm, n_final, :storage_damage)
        JuMP.@constraint(pm.model, z_storage[i] == 1)
    end
    for (i,gen) in  _PM.ref(pm, n_final, :gen_damage)
        JuMP.@constraint(pm.model, z_gen[i] == 1)
    end
    for (i,branch) in  _PM.ref(pm, n_final, :branch_damage)
        JuMP.@constraint(pm.model, z_branch[i] == 1)
    end
    for (i,bus) in  _PM.ref(pm, n_final, :bus_damage)
        JuMP.@constraint(pm.model, z_bus[i] == 1)
    end

    objective_max_load_delivered(pm)
end

