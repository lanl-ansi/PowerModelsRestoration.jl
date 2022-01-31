
""
function run_rad(data, model_constructor, optimizer;
    time_limit::Float64=3600.0,
    averaging_window::Int = 100,
    partition_min::Int = 2,
    partition_max::Int = 5,
    iteration_with_no_improvement_limit::Int=10,
    fail_to_improve_limit::Float64=0.8,
    fail_time_limit::Float64=0.8,
    rng=Random.GLOBAl_RNG,
    kwargs...
    )

    ## create stats
    solution = Dict{String,Any}(
    "objective_lb" => 0.0,
    "objective" => 0.0,
    "solution" => Dict{String,Any}(),
    "solve_time" => 0.0
    )
    stats = Dict{String,Any}(
    "ENS" => Dict{Int,Vector{Float64}}(),
    "sub_ENS" => Dict{Int,Vector{Float64}}(),
    "improvement" => Dict{Int,Vector{Float64}}(),
    "solve_time" => Dict{Int,Vector{Float64}}(),
    "termination_status" => Dict{Int,Vector{_PM.TerminationStatusCode}}(),
    "primal_status" => Dict{Int,Vector{_PM.ResultStatusCode}}(),
    "average_fail_to_improve"=>Dict{Int,Vector{Float64}}(),
    "average_termination_time_limit"=>Dict{Int,Vector{Float64}}(),
    "solver_time_limit"=>Dict{Int,Vector{Float64}}(),
    "partition_max"=>Dict{Int,Vector{Float64}}(),
    "partition_size"=>Dict{Int,Vector{Float64}}(),
    "repair_count"=>Dict{Int,Vector{Float64}}(),
    "feasible_period"=>Dict{Int,Bool}(),
    )


    ## Start algorithm
    t_start = time()
    network_count = count_repairable_components(data)

    ## initial ordering (utilization heuristic)
    repair_ordering = utilization_repair_order(data)
    ens_dict = Dict(k=>sum(load["pd"] for (id,load) in data["load"]) for k in keys(repair_ordering))

    solution["solution"] = replicate_restoration_network(data,count=length(keys(repair_ordering)))
    solution["solution"] = apply_restoration_sequence!(solution["solution"],repair_ordering)
    for (nwid,net) in solution["solution"]["nw"] #initialize load solution to 0
        for (loadid,load) in net["load"]
            load["pd"] = 0.0
        end
    end
    delete!(solution["solution"]["nw"],"0")

    ## Update stats
    iteration_counter = 1
    stats["feasible_period"] = Dict{Int,Bool}(parse(Int,nwid)=>false for nwid in keys(repair_ordering))

    ## Adaptive information
    iterations_with_no_improvement = 0
    max_partition_max = max(partition_min+1,round(Int,network_count/2))
    partition_max = min(partition_max, max_partition_max)
    average_termination_time_limit = 0.0
    average_fail_to_improve = 0.0
    fail_to_improve = []
    termination_time_limit = []
    solver_time_limit = time_limit/averaging_window

    # while (iteration with no improvement is under the limit OR not every network has a feasible power flow) AND we are under the time limit
    while ((iterations_with_no_improvement < iteration_with_no_improvement_limit) || !minimum(values(stats["feasible_period"]))) && ((time()-t_start) < time_limit)

        stats["solve_time"][iteration_counter] =  Float64[]
        stats["termination_status"][iteration_counter] = Float64[]
        stats["primal_status"][iteration_counter] =  Float64[]
        stats["ENS"][iteration_counter] =  Float64[]
        stats["sub_ENS"][iteration_counter] =  Float64[]
        stats["improvement"][iteration_counter] =  Float64[]
        stats["solver_time_limit"][iteration_counter] = Float64[]
        stats["partition_max"][iteration_counter] =  Float64[]
        stats["partition_size"][iteration_counter] = Float64[]
        stats["repair_count"][iteration_counter] =  Float64[]

        ## Adapative changes to time limit and parition max
        updated = false
        if average_fail_to_improve > fail_to_improve_limit
            if average_termination_time_limit > fail_time_limit
                solver_time_limit = solver_time_limit*2.0
                updated = true
            else
                if partition_max != max_partition_max
                    partition_max = min(round(partition_max*1.1),max_partition_max)
                    updated = true
                end
            end
            if updated
                iterations_with_no_improvement = 0
            end
        end

        ## create partitions
        partitions = Int[]
        partition_count = 0
        while partition_count < network_count
            partition_range = min((network_count-partition_count),partition_min):min((network_count-partition_count),partition_max)
            push!(partitions,rand(rng,partition_range))
            partition_count = sum(partitions)
        end

        nwids = sort([parse(Int,k) for k in keys(repair_ordering)], rev=true)
        partition_repairs = Dict{Int,Any}()
        partition_networks = Dict{Int,Any}()
        for  i in eachindex(partitions)
            partition_size = partitions[i]
            partition_networks[i] = [pop!(nwids) for j in 1:partition_size]

            partition_repairs[i] = Tuple{String,String}[]
            for nw_id in partition_networks[i]
                    append!(partition_repairs[i], repair_ordering["$nw_id"])
            end
        end

        ## create new ordering dict
        new_repair_ordering = Dict(k=>Tuple{String,String}[] for k in keys(deepcopy(repair_ordering)))

        ## Solve subperiod ROP problems on each partition
        for (r_id, repairs) in partition_repairs
            network_ids = sort(partition_networks[r_id])
            r_data = deepcopy(data)

            # apply component status/damage for components in other partitions
            for (r_id_it, repairs_it) in partition_repairs
                if r_id_it < r_id
                    for (comp_type, comp_id) in repairs_it
                        r_data[comp_type][comp_id]["damaged"] = 0
                    end
                elseif r_id_it > r_id
                    for (comp_type, comp_id) in repairs_it
                        comp_status_key = PowerModels.pm_component_status[comp_type]
                        comp_status_inactive = PowerModels.pm_component_status_inactive[comp_type]
                        r_data[comp_type][comp_id][comp_status_key] = comp_status_inactive
                    end
                end
            end

            # solve ROP
            _update_optimizer_time_limit!(optimizer, min(solver_time_limit,max(0,time_limit-(time()-t_start))))
            repair_periods=length(network_ids)
            mn_network = _simple_replicate_restoration_network(r_data, repair_periods, PowerModels._pm_global_keys)
            rad_solution = PowerModelsRestoration._run_partial_rop(mn_network, model_constructor, optimizer; kwargs...)

            # calculate load
            total_load = sum(load["pd"] for (id,load) in r_data["load"])
            old_ens = Dict("$nwid"=> ens_dict["$nwid"] for nwid in network_ids)

            # if partition has feasible solution, save result
            if rad_solution["primal_status"] == _PM.FEASIBLE_POINT
                _fill_missing_variables!(rad_solution, r_data) # some devices like load are removed for status 0.  E.g. ensure that load pd is zero if removed
                clean_status!(rad_solution["solution"])

                # calculate load
                served_load = Dict(nwid=>0.0 for nwid in keys(rad_solution["solution"]["nw"]) if nwid != "0" )
                for nwid in keys(served_load)
                    for (id,load) in get(rad_solution["solution"]["nw"][nwid],"load",Dict())
                        served_load[nwid] += load["pd"]
                    end
                end
                new_ens = Dict(nwid=>(total_load - served_load[nwid]) for nwid in keys(served_load))

                # a feasible power flow was found for these networks
                for nwid in network_ids
                    stats["feasible_period"][nwid] = true
                end

                # insert reordered repairs into new ordering if ENS is improved
                if (sum(values(new_ens)) < sum(values(old_ens)))
                    # add new repair orders
                    iterations_with_no_improvement = 0
                    r_repairs =  _get_component_repairs(rad_solution)
                    for (rr_id, repairs) in r_repairs
                        if rr_id != "0"
                            nw_id = network_ids[parse(Int,rr_id)]
                            push!(new_repair_ordering["$nw_id"], repairs...)
                        end
                    end

                    # update ens_dict with improved ens
                    for (old_key,new_key) in zip(sort(parse.(Int,collect(keys(old_ens)))), sort(parse.(Int,collect(keys(new_ens)))))
                        ens_dict["$old_key"] = new_ens["$new_key"]
                    end

                    # update solution["solution"] dict
                    for rr_id in keys(r_repairs)
                        if rr_id != "0"
                            nw_id = network_ids[parse(Int,rr_id)]
                            _PM.update_data!(solution["solution"]["nw"]["$nw_id"], rad_solution["solution"]["nw"]["$rr_id"])
                        end
                    end

                    Memento.info(_PM._LOGGER, "better order succeded")
                    Memento.info(_PM._LOGGER, "new ENS: $(sum(values(new_ens)))")
                    Memento.info(_PM._LOGGER, "old ENS: $(sum(values(old_ens)))")
                else
                    # insert old order, ENS was not improved
                    for nwid in network_ids
                        new_repair_ordering["$nwid"] = deepcopy(repair_ordering["$nwid"])
                    end
                    Memento.warn(_PM._LOGGER, "Failed to improve ENS")
                    Memento.info(_PM._LOGGER, "new ENS: $(sum(values(new_ens)))")
                    Memento.info(_PM._LOGGER, "old ENS: $(sum(values(old_ens)))")
                end
            else ## no primal solution to rop
                new_ens = deepcopy(old_ens)

                # insert old order
                for nwid in network_ids
                    new_repair_ordering["$nwid"] = deepcopy(repair_ordering["$nwid"])
                end

                Memento.info(_PM._LOGGER, "No Solution")
                Memento.info(_PM._LOGGER, "Primal status: $(rad_solution["primal_status"])")
                Memento.info(_PM._LOGGER, "Termination status: $(rad_solution["termination_status"])")
            end

            ## update running averages
            if (sum(values(new_ens)) < sum(values(old_ens)))
                push!(fail_to_improve, false)
            else
                push!(fail_to_improve, true)
                average_fail_to_improve = average_fail_to_improve*(averaging_window-1)/averaging_window + 1/averaging_window
            end
            if rad_solution["termination_status"]!=_PM.TIME_LIMIT
                push!(termination_time_limit, false)
            else
                push!(termination_time_limit, true)
            end


            push!(stats["solve_time"][iteration_counter], rad_solution["solve_time"])
            push!(stats["termination_status"][iteration_counter], rad_solution["termination_status"])
            push!(stats["primal_status"][iteration_counter], rad_solution["primal_status"])
            push!(stats["ENS"][iteration_counter], sum(values(ens_dict)))
            push!(stats["sub_ENS"][iteration_counter], sum(values(new_ens)))
            push!(stats["improvement"][iteration_counter], sum(values(old_ens))-sum(values(new_ens)))
            push!(stats["solver_time_limit"][iteration_counter], solver_time_limit)
            push!(stats["partition_max"][iteration_counter], partition_max)
            push!(stats["partition_size"][iteration_counter], repair_periods)
            push!(stats["repair_count"][iteration_counter], count_repairable_components(r_data))
        end

        # Calc average and reset
        average_fail_to_improve = sum(fail_to_improve)/length(fail_to_improve)
        average_termination_time_limit = sum(termination_time_limit)/length(termination_time_limit)
        fail_to_improve = []
        termination_time_limit = []
        stats["average_fail_to_improve"][iteration_counter] = [average_fail_to_improve]
        stats["average_termination_time_limit"][iteration_counter] = [average_termination_time_limit]

        iterations_with_no_improvement += 1
        Memento.info(_PM._LOGGER, "iterations_with_no_improvement: $iterations_with_no_improvement")

        repair_ordering = deepcopy(new_repair_ordering)

        iteration_counter += 1
    end

    ## Collection final solution and return
    solution["stats"] = stats
    solution["repair_ordering"] = repair_ordering
    solution["solve_time"] = time()-t_start
    solution["primal_status"] = minimum(collect(values(stats["feasible_period"]))) ? _PM.FEASIBLE_POINT : _PM.NO_SOLUTION
    solution["termination_status"] = time()-t_start>time_limit ? _PM.TIME_LIMIT : solution["primal_status"]==_PM.FEASIBLE_POINT ?  _PM.LOCALLY_SOLVED :  _PM.LOCALLY_INFEASIBLE

    solution["objective"] = sum(sum(load["pd"] for (id,load) in nw["load"]) for (nwid,nw) in solution["solution"]["nw"])
    return solution
end
