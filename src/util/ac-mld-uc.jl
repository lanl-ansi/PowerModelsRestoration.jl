
"implements a scalable huristic solution to the AC-MLD problem"
function run_ac_mld_uc(case::Dict{String,<:Any}, solver; modifications::Dict{String,<:Any}=Dict{String,Any}("per_unit" => case["per_unit"]), setting::Dict{String,<:Any}=Dict{String,Any}(), int_tol::Real=1e-6)
    case = deepcopy(case)
    _PMs.update_data!(case, modifications)

    _PMs.propagate_topology_status!(case)
    _PMs.select_largest_component!(case)
    #_PMs.correct_refrence_buses!(case)

    if length(setting) != 0
        Memento.info(_PMs._LOGGER, "settings: $(setting)")
    end


    soc_result = run_mld(case, _PMs.SOCWRPowerModel, solver; setting=setting)

    @assert (soc_result["termination_status"] == _PMs.LOCALLY_SOLVED || soc_result["termination_status"] == _PMs.OPTIMAL)
    soc_sol = soc_result["solution"]

    soc_active_delivered = sum([if (case["load"][i]["status"] != 0) load["pd"] else 0.0 end for (i,load) in soc_sol["load"]])
    soc_active_output = sum([if (isequal(gen["pg"], NaN) || gen["gen_status"] == 0) 0.0 else gen["pg"] end for (i,gen) in soc_sol["gen"]])
    Memento.info(_PMs._LOGGER, "soc active gen:    $(soc_active_output)")
    Memento.info(_PMs._LOGGER, "soc active demand: $(soc_active_delivered)")


    for (i,bus) in soc_sol["bus"]
        if !isequal(bus["status"], NaN) && case["bus"][i]["bus_type"] != 4 && bus["status"] <= 1-int_tol
            case["bus"][i]["bus_type"] = 4
            Memento.info(_PMs._LOGGER, "removing bus $i, $(bus["status"])")
        end
    end

    for (i,gen) in soc_sol["gen"]
        if !isequal(gen["gen_status"], NaN) && case["gen"][i]["gen_status"] != 0 && gen["gen_status"] <= 1-int_tol
            case["gen"][i]["gen_status"] = 0
            Memento.info(_PMs._LOGGER, "removing gen $i, $(gen["gen_status"])")
        end
    end

    _PMs.propagate_topology_status!(case)

    bus_count = sum([if (case["bus"][i]["bus_type"] != 4) 1 else 0 end for (i,bus) in case["bus"]])

    if bus_count <= 0
        result = soc_result
    else
        _PMs.select_largest_component!(case)

        ac_result = run_mld_smpl(case, _PMs.ACPPowerModel, solver; setting=setting)
        ac_result["solve_time"] = ac_result["solve_time"] + soc_result["solve_time"]

        # update solution with status values
        ac_sol = ac_result["solution"]

        result = ac_result
    end


    sol = result["solution"]
    for (i,bus) in case["bus"]
        if bus["bus_type"] != 4
            sol["bus"][i]["status"] = 1
        else
            sol["bus"][i]["status"] = 0
        end

        if !haskey(sol["bus"][i], "va")
            sol["bus"][i]["va"] = 0.0
        end
    end

    for (i,gen) in case["gen"]
        if haskey(sol["gen"], i)
            sol["gen"][i]["gen_status"] = gen["gen_status"]
        else
            sol["gen"][i] = Dict("gen_status" => 0)
        end
    end

    for (i,branch) in case["branch"]
        if haskey(sol, "branch") && haskey(sol["branch"], i)
            sol["branch"][i]["br_status"] = branch["br_status"]
        else
            sol["branch"][i] = Dict("br_status" => 0)
        end
    end

    active_delivered = sum(load["pd"] for (i,load) in sol["load"])
    active_output = sum(gen["pg"] for (i,gen) in sol["gen"] if haskey(gen, "pg"))
    Memento.info(_PMs._LOGGER, "ac active gen:    $active_output")
    Memento.info(_PMs._LOGGER, "ac active demand: $active_delivered")

    return result
end
