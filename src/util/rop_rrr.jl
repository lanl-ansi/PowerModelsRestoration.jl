

function run_rrr(network, model_constructor, optimizer;
        time_limit::Float64=3600.0,
        minimum_solver_time_limit::Float64=0.1,
        minimum_recovery_problem_time_limit::Float64 = 10.0,
        kwargs...
    )
    t_start = time()
    sol = _run_rrr(network, model_constructor, optimizer, time_limit, minimum_solver_time_limit, minimum_recovery_problem_time_limit; kwargs...)

    _fill_missing_variables!(sol, network) # some networks do not have all variables if devices were status 0
    sol["solve_time"] = time()-t_start
    return sol
end


"recrusive call of RRR"
function _run_rrr(network, model_constructor, optimizer,
        time_limit::Float64,
        minimum_solver_time_limit::Float64,
        minimum_recovery_problem_time_limit::Float64;
        kwargs...
    )

    # record starting time
    t_start = time()
    solver_time_limit = time_limit/2
    remaining_time_limit = max(minimum_solver_time_limit, time_limit-(time()-t_start))
    pm =  JuMP.Model(optimizer)
    JuMP.set_time_limit_sec(pm, solver_time_limit)

    repair_periods=2
    mn_network = replicate_restoration_network(network, repair_periods, _PM._pm_global_keys)
    # set time_elapsed correctly
    for (nwid,net) in mn_network["nw"]
        net["time_elapsed"] = max(1, net["repairs"])
    end

    ## solve ROP problem
    solution = _run_partial_rop(mn_network, model_constructor, nothing; jump_model=pm, kwargs...)

    # collect stats on solution
    solution["stats"] = Dict(
        "termination_status" => [solution["termination_status"]],
        "primal_status" => [solution["primal_status"]],
        "solve_time" => [solution["solve_time"]],
        "item_count" => [count_repairable_components(network)],
        "period_count"=>[repair_periods],
        "alt_condition"=>[]
    )

    ## Clean solution and apply result to network
    clean_status!(solution["solution"]) # replace status with bus_type for buses


    ## IF primal infeasible, run Utilization for a repair ordering and continue
    if solution["primal_status"] ==_PM.FEASIBLE_POINT
        _apply_repairs!(mn_network, get_component_activations(solution["solution"]))
    else
        Memento.warn(_PM._LOGGER, "Primal status is not feasible.")
        Memento.warn(_PM._LOGGER, "Running a $(count_repairable_components(network)) period recovery using Utilization Heuristic")

        util_order = utilization_repair_order(network)

        restoration_order = Dict("$nwid"=>Tuple{String,String}[] for nwid in 0:2)
        l = maximum(parse.(Int,collect(keys(util_order))))
        m = round(Int,l/2)
        net_keys = [1:m,m+1:l]
        for r_id in axes(net_keys,1)
            for nw_id in net_keys[r_id]
                append!(restoration_order["$r_id"],util_order["$nw_id"])
            end
        end

        mn_network = replicate_restoration_network(network, count=2)
        # set time_elapsed correctly
        for (nwid,net) in mn_network["nw"]
            net["time_elapsed"] = max(1, net["repairs"])
        end

        _apply_repairs!(mn_network, restoration_order)

        ## if result will have single repair in a period, run RRP to create a reporting solution
        if count_repairable_components(mn_network["nw"]["1"]) ≤ 1 || count_repairable_components(mn_network["nw"]["2"]) ≤ 1

            # update time limit
            remaining_time_limit = max(minimum_recovery_problem_time_limit, time_limit-(time()-t_start))
            solver_time_limit = remaining_time_limit/2
            pm =  JuMP.Model(optimizer)
            JuMP.set_time_limit_sec(pm, solver_time_limit)

            Memento.warn(_PM._LOGGER, "Running a $(count_repairable_components(network)) period recovery and
            a redispatch with a time limit of $solver_time_limit")

            # RRP to get load served
            solution = run_restoration_redispatch(mn_network, model_constructor, nothing; jump_model=pm)
            solution["stats"] = Dict(
                "termination_status" => [solution["termination_status"]],
                "primal_status" => [solution["primal_status"]],
                "solve_time" => [solution["solve_time"]],
                "item_count" => [count_repairable_components(network)],
                "period_count"=>[repair_periods],
                "alt_condition"=>["Util recovery caused small network"]
            )

            # fill missing items removed for status=0 in redispatch
            _fill_missing_variables!(solution, network)
            update_status!(solution["solution"], mn_network)
        end
    end


    r_comps = get_repairable_components(network)
    r_count = _count_cumulative_component_repairs(mn_network)
    ## IF (all repairs in period 2) OR (Exceeding time limit) then run Redispatch and return
    if (r_count["1"]==0 && r_count["2"]!=0)
        # update time limit
        remaining_time_limit = time_limit-(time()-t_start)
        solver_time_limit = max(minimum_recovery_problem_time_limit, remaining_time_limit/2)
        pm =  JuMP.Model(optimizer)
        JuMP.set_time_limit_sec(pm, solver_time_limit)

        Memento.warn(_PM._LOGGER, "All repairs in final time period.")
        Memento.warn(_PM._LOGGER, "Running a $(count_repairable_components(network)) period recovery and
        a redispatch with a time limit of $solver_time_limit")

        # run utilization
        restoration_order = utilization_repair_order(network)
        case_mn = replicate_restoration_network(network, count=length(keys(restoration_order)))
        # set time_elapsed correctly
        for (nwid,net) in mn_network["nw"]
            net["time_elapsed"] = max(1, net["repairs"])
        end
        _apply_repairs!(case_mn, restoration_order)
        delete!(case_mn["nw"], "0")

        # RRP to get load served
        solution = run_restoration_redispatch(case_mn, model_constructor, nothing, jump_model=pm)
        solution["stats"] = Dict(
            "termination_status" => [solution["termination_status"]],
            "primal_status" => [solution["primal_status"]],
            "solve_time" => [solution["solve_time"]],
            "item_count" => [count_repairable_components(network)],
            "period_count"=>[repair_periods],
            "alt_condition"=>["all repairs in period 2"]
        )

        # fill missing items removed for status=0 in redispatch
        _fill_missing_variables!(solution, network)
        update_status!(solution["solution"], case_mn)
        return_solution = deepcopy(solution)

    elseif time()-t_start > time_limit
        # update time limit
        remaining_time_limit = time_limit-(time()-t_start)
        solver_time_limit = max(minimum_recovery_problem_time_limit, remaining_time_limit/2)
        pm =  JuMP.Model(optimizer)
        JuMP.set_time_limit_sec(pm, solver_time_limit)

        Memento.warn(_PM._LOGGER, "Time Limit Exceeded, setting repairs to final period")
        Memento.warn(_PM._LOGGER, "Running a $(count_repairable_components(network)) redispatch with a limit of $solver_time_limit")

        # run utilization
        restoration_order = utilization_repair_order(network)
        case_mn = replicate_restoration_network(network, count=length(keys(restoration_order)))

        # set time_elapsed correctly
        for (nwid,net) in mn_network["nw"]
            net["time_elapsed"] = max(1, net["repairs"])
        end
        _apply_repairs!(case_mn, restoration_order)
        delete!(case_mn["nw"], "0")

        # RRP to get load served
        solution = run_restoration_redispatch(case_mn, model_constructor, nothing; jump_model=pm)
        solution["stats"] = Dict(
            "termination_status" => [solution["termination_status"]],
            "primal_status" => [solution["primal_status"]],
            "solve_time" => [solution["solve_time"]],
            "item_count" => [count_repairable_components(network)],
            "period_count"=>[repair_periods],
            "alt_condition"=>["ordering exceeeded time limit"]
        )

        # fill missing items removed for status=0 in redispatch
        _fill_missing_variables!(solution, network)
        update_status!(solution["solution"], case_mn)
        return_solution = deepcopy(solution)

    else # ELSE run iter on each network
        delete!(mn_network["nw"],"0") # remove network "0" for recursion
        return_solution = deepcopy(solution) # create return network
        return_solution["solution"]["nw"]=Dict{String,Any}()

        for (nw_id) in string.(sort(parse.(Int,collect(keys(mn_network["nw"])))))
            net = mn_network["nw"][nw_id]

            ## IF more than 1 repair in time period, run recursion
            if count_repairable_components(net) > 1
                sub_net = deepcopy(net)
                for key in _PM._pm_global_keys
                    if haskey(network, key)
                        sub_net[key] = network[key]
                    end
                end

                remaining_time_limit = max(minimum_solver_time_limit, time_limit-(time()-t_start))
                sub_sol = _run_rrr(sub_net, model_constructor, optimizer, remaining_time_limit, minimum_solver_time_limit, minimum_recovery_problem_time_limit; kwargs...)
                merge_solution!(return_solution,sub_sol) # accumulate objective, solve status, etc.

                # collect return networks
                return_keys = keys(return_solution["solution"]["nw"]) |> collect |> (y->parse.(Int,y))
                if isempty(return_keys)
                    current_net_id = 0
                else
                    current_net_id = maximum(return_keys)
                end
                for (sol_id, sol_net) in sub_sol["solution"]["nw"]
                    return_solution["solution"]["nw"]["$(current_net_id+parse(Int,sol_id))"] = sol_net
                end

                # collect stats from each sub sol
                for stat in keys(return_solution["stats"])
                    append!(return_solution["stats"][stat], sub_sol["stats"][stat])
                end

            else # add solution network to return
                return_keys = keys(return_solution["solution"]["nw"]) |> collect |> (y->parse.(Int,y))
                if isempty(return_keys)
                    current_net_id = 0
                else
                    current_net_id = maximum(return_keys)
                end
                return_solution["solution"]["nw"]["$(current_net_id+1)"] = solution["solution"]["nw"][nw_id]
            end
        end
    end

    return return_solution
end


"""
    update device status and remove damaged indicator if item was repaired in network 3
    Before:
    | nw_id   |  1  |  2  |  3  |  4  |
    | ------- | --- | --- | --- | --- |
    | status  |  1  |  1  |  1  |  1  |
    | damaged |  1  |  1  |  1  |  1  |

    Repaired in network 3
    After:
    | nw_id   |  1  |  2  |  3  |  4  |
    | ------- | --- | --- | --- | --- |
    | status  |  0  |  0  |  1  |  1  |
    | damaged |  1  |  1  |  1  |  0  |
"""
function _apply_repairs!(data, repairs)
    for (repair_nw_id, nw_repairs) in repairs
        for (comp_type, comp_id) in nw_repairs
            status_key = _PM.pm_component_status[comp_type]
            for (nw_id, net) in data["nw"]
                if  nw_id < repair_nw_id
                    net[comp_type][comp_id][status_key] = _PM.pm_component_status_inactive[comp_type]
                elseif nw_id > repair_nw_id
                    net[comp_type][comp_id]["damaged"] = 0
                end
            end
        end
    end
    return data
end