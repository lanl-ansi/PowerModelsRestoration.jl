"implements a scalable heuristic solution to the AC-MLD problem"
function run_ac_mld_uc(
    case::Dict{String,<:Any},
    solver;
    modifications::Dict{String,<:Any}=Dict{String,Any}("per_unit" => case["per_unit"]),
    setting::Dict{String,<:Any}=Dict{String,Any}(),
    int_tol::Real=1e-6,
    optimize_disconnected_subnetworks::Bool=false,
)
    base_case = case
    case = deepcopy(case)
    _PM.update_data!(case, modifications)

    # Note that this can hide some load shed if a connected component with
    # load but no generation is created.
    _PM.simplify_network!(case)
    if optimize_disconnected_subnetworks
        _PM.correct_reference_buses!(case)
    else
        _PM.select_largest_component!(case)
    end

    if length(setting) != 0
        Memento.info(_PM._LOGGER, "settings: $(setting)")
    end

    # Run MLD with SOC relaxation. This gives us an upper bound on load delivery for any
    # feasible solution to our original problem. I.e., the contingency will always be
    # at least this bad.
    soc_result = run_mld(case, _PM.SOCWRPowerModel, solver; setting=setting)

    # Check termination_status instead of primal_status here as, without optimality,
    # the relaxation solution loses its meaning.
    @assert (soc_result["termination_status"] == _PM.LOCALLY_SOLVED || soc_result["termination_status"] == _PM.OPTIMAL)
    soc_sol = soc_result["solution"]

    soc_active_delivered = sum([if (case["load"][i]["status"] != 0) load["pd"] else 0.0 end for (i,load) in soc_sol["load"]])
    soc_active_output = sum([if (isequal(gen["pg"], NaN) || gen["gen_status"] == 0) 0.0 else gen["pg"] end for (i,gen) in soc_sol["gen"]])
    Memento.info(_PM._LOGGER, "soc active gen:    $(soc_active_output)")
    Memento.info(_PM._LOGGER, "soc active demand: $(soc_active_delivered)")

    # Round down bus and generator statuses from SOC solution and propagate to
    # case data. I.e., if the optimistic solution doesn't have a bus/gen "all the
    # way on", we deactivate that device.
    # This is a heuristic to help us get feasible solutions later. (We also
    # relax bounds to *ensure* we get a feasible solution, but this helps us
    # not violate bounds.)
    for (i,bus) in soc_sol["bus"]
        if case["bus"][i]["bus_type"] != 4 && bus["status"] <= 1-int_tol
            case["bus"][i]["bus_type"] = 4
            Memento.info(_PM._LOGGER, "removing bus $i, $(bus["status"])")
        end
    end

    for (i,gen) in soc_sol["gen"]
        if case["gen"][i]["gen_status"] != 0 && gen["gen_status"] <= 1-int_tol
            case["gen"][i]["gen_status"] = 0
            Memento.info(_PM._LOGGER, "removing gen $i, $(gen["gen_status"])")
        end
    end

    _PM.simplify_network!(case)

    bus_count = sum([if (case["bus"][i]["bus_type"] != 4) 1 else 0 end for (i,bus) in case["bus"]])

    if bus_count <= 0
        result = soc_result
    else
        if optimize_disconnected_subnetworks
            _PM.correct_reference_buses!(case)
        else
            _PM.select_largest_component!(case)
        end

        # MLD with gen and bus participation fixed, and generation/voltage bounds
        # relaxed (and penalized)
        ac_result = run_mld_smpl(case, _PM.ACPPowerModel, solver; setting=setting)
        ac_result["solve_time"] = ac_result["solve_time"] + soc_result["solve_time"]

        _PM.update_data!(soc_sol, ac_result["solution"])
        ac_result["solution"] = soc_sol

        result = ac_result
    end

    # Propagate statuses of deactivated components back to solution. These
    # components were deactivated by rounding the SOC solution by subsequent
    # simplification steps.
    sol = result["solution"]
    for (i,bus) in base_case["bus"]
        if bus["bus_type"] != 4 && case["bus"][i]["bus_type"] == 4
            if !haskey(sol["bus"], i)
                sol["bus"][i] = Dict("status" => 0, "va" => 0.0, "vm" => 0.0)
            else
                sol["bus"][i]["status"] = 0
            end
        end
    end

    for (i,gen) in base_case["gen"]
        if gen["gen_status"] != 0 && case["gen"][i]["gen_status"] == 0
            if !haskey(sol["gen"], i)
                sol["gen"][i] = Dict("gen_status" => 0, "pg" => 0.0, "qg" => 0.0)
            else
                sol["gen"][i]["gen_status"] = 0
            end
        end
    end

    for (i,branch) in case["branch"]
        if branch["br_status"] != 0 && case["branch"][i]["br_status"] == 0
            if !haskey(sol["branch"], i)
                sol["branch"][i] = Dict("br_status" => 0)
            else
                sol["branch"][i]["br_status"] = 0
            end
        end
    end

    active_delivered = sum(load["pd"] for (i,load) in sol["load"])
    active_output = sum(gen["pg"] for (i,gen) in sol["gen"] if haskey(gen, "pg"))
    Memento.info(_PM._LOGGER, "ac active gen:    $active_output")
    Memento.info(_PM._LOGGER, "ac active demand: $active_delivered")

    return result
end
