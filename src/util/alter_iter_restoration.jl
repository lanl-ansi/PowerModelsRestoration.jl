
# only required for first stage to get the 0 period??
function run_iter_res(network, model_constructor, optimizer; repair_periods=2, kwargs...)
    t_start = time()

    repair_count = count_repairable_items(network)
    t = collect(1:repair_count)
    repair_remainder = 0
    sol = _run_iter_res(network, model_constructor, optimizer, t, repair_remainder; repair_periods, kwargs...)

    fill_missing_variables!(sol, network) # some networks do not have all variables if devices were status 0

    sol["solve_time"] = time()-t_start
    return sol
end


"recrusive call to iterative restoration"
function _run_iter_res(network,model_constructor,optimizer, t::Vector{Int}, repair_remainder::Int; repair_periods=2, kwargs... )

    # assign time periods into repair_periods
    t_split = split_time_periods(t, repair_periods)

    ## replicate network, set repairs per period
    mn_network = replicate_network(network, repair_periods, _PM._pm_global_keys)
    apply_repair_limits!(mn_network, t_split, repair_remainder)

    ## solve ROP
    solution = _run_rop_ir(mn_network, model_constructor, optimizer; kwargs...)

    ## Clean solution and apply result to network
    clean_status!(solution["solution"]) # replace stauts with bus_type for buses
    N_cumulative_repairs = count_cumulative_repairs(solution)
    apply_repairs!(mn_network, get_repairs(solution))

    ## remove network "0" for recursion
    delete!(mn_network["nw"],"0")

    ## return network
    return_solution = deepcopy(solution)
    return_solution["solution"]["nw"]=Dict{String,Any}() #clear networks in return

    # println("Times: $(t) Repairs Available: $(count_repairable_items(network))")
    # println("Assigned Split:")
    # println("Times: $(t_split[1][1]) $(t_split[1][end]) Repair Limit: $(mn_network["nw"]["1"]["repaired_total"]) \t Times: $(t_split[2][1]) $(t_split[2][end]) Repair Limit: $(mn_network["nw"]["2"]["repaired_total"])")
    # println("Actual Repairs 1: $(N_cumulative_repairs["1"]) \t Actual Repairs 2: $(N_cumulative_repairs["2"])")
    # println()

    ## calc subproblem
    for (nw_id, net) in mn_network["nw"]
        t_sub = t_split[parse(Int,nw_id)] # time slot allocation for sub network

        # check termination conditions
        if !(length(t_sub) == 1)# || repairable_count == 1) iterate down through non repairs to get individual networks?
            sub_net = deepcopy(net)
            for key in _PM._pm_global_keys
                if haskey(network, key)
                    sub_net[key] = network[key]
                end
            end

            repair_remainder = net["repaired_total"] - N_cumulative_repairs["$(nw_id)"] # repair_limit - actual_repairs_done
            sub_sol = _run_iter_res(sub_net, model_constructor, optimizer, t_sub, repair_remainder; repair_periods, kwargs...)
            update_solution!(return_solution, sub_sol)
        else
            # Does this need to use update_solution?
            return_solution["solution"]["nw"]["$(t_sub[1])"] = solution["solution"]["nw"]["$(nw_id)"]
        end
    end

    return return_solution # temp
end


"calculate the time periods to associate with each network"
function split_time_periods(t, repair_periods)
    t_length=length(t)
    time_slots = t_length/repair_periods

    # calculat the split of time periods into networks
    t_index = [[i for i in (p-1)*ceil(Int,time_slots)+1:ceil(Int,time_slots)*p if i <= t_length] for p in 1:repair_periods]

    # use the time periods in t_index to index the periods in t into appropriate divisions
    t_split = [[t[index] for index in period] for period in t_index]
    return t_split
end

"create count replicates of network in multi-network"
function replicate_network(sn_data::Dict{String,<:Any}, count::Int, global_keys::Set{String})
    pm_sn_data = _PM.get_pm_data(sn_data)
    name = get(pm_sn_data, "name", "anonymous")

    mn_data = Dict{String,Any}(
        "nw" => Dict{String,Any}()
    )
    mn_data["multinetwork"] = true
    pm_sn_data_tmp = deepcopy(pm_sn_data)
    for k in global_keys
        if haskey(pm_sn_data_tmp, k)
            mn_data[k] = pm_sn_data_tmp[k]
        end
        # note this is robust to cases where k is not present in pm_sn_data_tmp
        delete!(pm_sn_data_tmp, k)
    end

    mn_data["name"] = "$(count) period restoration of $(name)"
    for n in 0:count
        mn_data["nw"]["$n"] = deepcopy(pm_sn_data_tmp)
    end

    return mn_data
end


"""
Calculate the maximum repairs in each period of the multinetwork using the number of
time periods, and the number of repairs in the previous level of the recursion.
"""
function apply_repair_limits!(mn_network, t, N_0_remainder)
    mn_network["nw"]["0"]["repaired_total"] = 0
    mn_network["nw"]["1"]["repaired_total"] = length(t[1])+N_0_remainder

    for id in 2:maximum(parse.(Int,keys(mn_network["nw"])))
        N_max = length(t[id]) + mn_network["nw"]["$(id-1)"]["repaired_total"]
        mn_network["nw"]["$(id)"]["repaired_total"] = N_max
    end
end


"get repairs in each period of the solution data"
function get_repairs(solution)
    if !_IM.ismultinetwork(solution["solution"])
        Memento.error(_PM._LOGGER, "get_repairs requires multinetwork.")
    end

    repairs = Dict{String,Array{Tuple{String,String},1}}(nw=>[] for nw in keys(solution["solution"]["nw"]))
    for (nw_id, network) in solution["solution"]["nw"]
        for comp_type in restoration_comps
            status_key = _PM.pm_component_status[comp_type]
            for (comp_id, comp) in get(network, comp_type, Dict())
                if nw_id != "0" #not items are repaired in "0", do not check in previous network for a change
                    if comp[status_key] != _PM.pm_component_status_inactive[comp_type] &&  # if comp is active
                        solution["solution"]["nw"]["$(parse(Int,nw_id)-1)"][comp_type][comp_id][status_key] == _PM.pm_component_status_inactive[comp_type] # if comp was previously inactive
                        push!(repairs[nw_id], (comp_type,comp_id))
                    end
                end
            end
        end
    end
    return repairs
end


"get a count of the repairs in each period of the solution data"
function count_repairs(solution)
    repairs = get_repairs(solution)
    repair_count = Dict{String,Int}(nw=>length(repair_list) for (nw, repair_list) in repairs )
    return repair_count
end


"get a count of the cumulative repairs in each period of the solution data"
function count_cumulative_repairs(solution)
    repair_count = count_repairs(solution)

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
    update device status and remove damaged indicator if item was repaired
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
function apply_repairs!(data, repairs)
    for (repair_nw_id, repair_list) in repairs
        for (comp_type, comp_id) in repair_list
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

"""
Update sol_1 dictionary with sol_2 dictionary. `termination_status`, `primal_status`, and `dual_status`
values are the maximum of the MOI status code. `solvetime`,`objective`, and `objective_lb` are accumulated. The
`solution` dictionary is merged using `PowerModels.update_data(sol_1["solution"],sol_2["solution"])`.
"""
function update_solution!(sol_1, sol_2)
    Memento.info(_PM._LOGGER, "networks $(keys(sol_2["solution"]["nw"])) finished with status $(sol_2["termination_status"])")

    sol_1["termination_status"] = max(sol_1["termination_status"],sol_2["termination_status"])
    sol_1["primal_status"] = max(sol_1["primal_status"],sol_2["primal_status"])
    sol_1["dual_status"] = max(sol_1["dual_status"],sol_2["dual_status"])
    sol_1["solve_time"] += sol_2["solve_time"]
    sol_1["objective"] += sol_2["objective"]
    sol_1["objective_lb"] += sol_2["objective_lb"]
    _PM.update_data!(sol_1["solution"],sol_2["solution"])
end


""
function fill_missing_variables!(sol::Dict{String,<:Any}, network::Dict{String,<:Any})

    # Is there a way to do this based on formulation, any default comps?
    variable_fill = Dict(
        "bus"=>Dict{String,Any}("va"=>0.0,"status"=>0.0, "bus_type"=>4, "vm"=>NaN),
        "gen"=>Dict{String,Any}("gen_status"=>0.0,"pg"=>0.0, "qg"=>NaN),
        "branch"=>Dict{String,Any}("qf"=>NaN,"qt"=>NaN,"br_status"=>0.0,"pt"=>0.0,"pf"=>0.0),
        "dcline"=>Dict{String,Any}("qf"=>NaN,"qt"=>NaN,"br_status"=>0.0,"pt"=>0.0,"pf"=>0.0),
        "load"=>Dict{String,Any}("status"=>0.0,"qd"=>0.0,"pd"=>0.0)
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
