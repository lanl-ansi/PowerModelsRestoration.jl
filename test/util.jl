@testset "test ac ml uc heuristic" begin
    @testset "3-bus case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case3_mld, nlp_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 1.0344; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 1.0344; atol = 1e-1)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
    @testset "3-bus uc case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case3_mld_uc, nlp_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.49999999; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.49999999; atol = 1e-1)
        @test isapprox(gen_status(result, "1"), 0.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
    @testset "3-bus line charge case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case3_mld_lc, nlp_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 210.641; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.34770; atol = 1e-3)
        #@test all_gens_on(result)
        #println([bus["status"] for (i,bus) in result["solution"]["bus"]])
        @test isapprox(bus_status(result, "1"), 0.0; atol = 1e-4)
        @test isapprox(bus_status(result, "2"), 0.0; atol = 1e-4)
        @test isapprox(bus_status(result, "3"), 0.0; atol = 1e-4)
    end
    @testset "5-bus weights case" begin
        data = PowerModels.parse_file("../test/data/case5.raw")
        add_load_weights!(data)

        result = PowerModelsRestoration.run_ac_mld_uc(data, nlp_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 310.635; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 4.063481; atol = 1e-3)
        #@test all_gens_on(result)
        #println([bus["status"] for (i,bus) in result["solution"]["bus"]])
        @test isapprox(bus_status(result, "1"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "2"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "3"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "4"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "10"), 0.0; atol = 1e-4)

        loads = result["solution"]["load"]

        # load 1 is high priorty, load 2 is medium priorty
        @test loads["1"]["status"] >= loads["2"]["status"]

        # load 2 is medium priorty, loads 3/4 are low priorty
        @test loads["2"]["status"] >= loads["3"]["status"]
        @test loads["2"]["status"] >= loads["4"]["status"]
    end
    @testset "24-bus rts case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case24, nlp_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 31.83; atol = 1e-1)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 28.5; atol = 1e-0)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
end


@testset "test util common functions" begin
    @testset "_compare_termination_statuses"   begin
        @test JuMP.OPTIMAL==PowerModelsRestoration._compare_termination_statuses([JuMP.OPTIMAL,JuMP.OPTIMAL,JuMP.OPTIMAL])
        @test JuMP.LOCALLY_SOLVED==PowerModelsRestoration._compare_termination_statuses([JuMP.LOCALLY_SOLVED,JuMP.LOCALLY_SOLVED,JuMP.OPTIMAL])
        @test JuMP.INFEASIBLE==PowerModelsRestoration._compare_termination_statuses([JuMP.INFEASIBLE,JuMP.OPTIMAL,JuMP.OPTIMAL])
        @test JuMP.INFEASIBLE==PowerModelsRestoration._compare_termination_statuses([JuMP.LOCALLY_SOLVED,JuMP.LOCALLY_SOLVED,JuMP.INFEASIBLE])
        @test JuMP.TIME_LIMIT==PowerModelsRestoration._compare_termination_statuses([JuMP.LOCALLY_SOLVED,JuMP.TIME_LIMIT,JuMP.LOCALLY_SOLVED])
        @test JuMP.OTHER_ERROR==PowerModelsRestoration._compare_termination_statuses([JuMP.LOCALLY_SOLVED,JuMP.LOCALLY_SOLVED,JuMP.NUMERICAL_ERROR])
    end
    @testset "_compare_result_statuses"   begin
        @test JuMP.FEASIBLE_POINT==PowerModelsRestoration._compare_result_statuses([JuMP.FEASIBLE_POINT,JuMP.FEASIBLE_POINT,JuMP.FEASIBLE_POINT])
        @test JuMP.NO_SOLUTION==PowerModelsRestoration._compare_result_statuses([JuMP.FEASIBLE_POINT,JuMP.NO_SOLUTION,JuMP.FEASIBLE_POINT])
        @test JuMP.INFEASIBILITY_CERTIFICATE==PowerModelsRestoration._compare_result_statuses([JuMP.INFEASIBILITY_CERTIFICATE,JuMP.INFEASIBILITY_CERTIFICATE,JuMP.INFEASIBILITY_CERTIFICATE])
        @test JuMP.UNKNOWN_RESULT_STATUS==PowerModelsRestoration._compare_result_statuses([JuMP.FEASIBLE_POINT,JuMP.FEASIBLE_POINT,JuMP.NEARLY_FEASIBLE_POINT])
    end
end



#=
@testset "Forward Restoration" begin
## Forward restoration is not currently working with MLD when buses are disabled.
    mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
    rop_result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, milp_solver)

    @testset "ac forward case" begin

        PowerModels.update_data!(mn_data, rop_result["solution"])
        result = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.ACPPowerModel, minlp_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 8834.38; atol = 1)

        @test isapprox(gen_status(result,"1","1"), gen_status(rop_result,"1","1"); atol=1e-6)
        @test isapprox(gen_status(result,"1","4"), gen_status(rop_result,"1","4"); atol=1e-6)
        @test isapprox(gen_status(result,"2","1"), gen_status(rop_result,"2","1"); atol=1e-6)
        @test isapprox(gen_status(result,"2","4"), gen_status(rop_result,"2","4"); atol=1e-6)
        @test isapprox(branch_status(result,"2","2"), branch_status(rop_result,"2","2"); atol=1e-6)
        @test isapprox(branch_status(result,"3","2"), branch_status(rop_result,"3","2"); atol=1e-6)
    end

    @testset "soc forward case" begin

        PowerModels.update_data!(mn_data, rop_result["solution"])
        result = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.SOCWRPowerModel, minlp_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 8834.38; atol = 1e0)

        @test isapprox(gen_status(result,"1","1"), gen_status(rop_result,"1","1"); atol=1e-6)
        @test isapprox(gen_status(result,"1","4"), gen_status(rop_result,"1","4"); atol=1e-6)
        @test isapprox(gen_status(result,"2","1"), gen_status(rop_result,"2","1"); atol=1e-6)
        @test isapprox(gen_status(result,"2","4"), gen_status(rop_result,"2","4"); atol=1e-6)
        @test isapprox(branch_status(result,"2","2"), branch_status(rop_result,"2","2"); atol=1e-6)
        @test isapprox(branch_status(result,"3","2"), branch_status(rop_result,"3","2"); atol=1e-6)
    end

    mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=3)
    rop_result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, milp_solver)

    @testset "ac forward case" begin

        PowerModels.update_data!(mn_data, rop_result["solution"])
        result = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.ACPPowerModel, minlp_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        ## Not stable on mac
        # @test isapprox(result["objective"], 8073.94; atol = 1)

        @test isapprox(gen_status(result,"1","1"), gen_status(rop_result,"1","1"); atol=1e-6)
        @test isapprox(gen_status(result,"1","4"), gen_status(rop_result,"1","4"); atol=1e-6)
        @test isapprox(gen_status(result,"2","1"), gen_status(rop_result,"2","1"); atol=1e-6)
        @test isapprox(gen_status(result,"2","4"), gen_status(rop_result,"2","4"); atol=1e-6)
        @test isapprox(branch_status(result,"2","2"), branch_status(rop_result,"2","2"); atol=1e-6)
        @test isapprox(branch_status(result,"3","2"), branch_status(rop_result,"3","2"); atol=1e-6)
    end

    @testset "soc forward case" begin

        PowerModels.update_data!(mn_data, rop_result["solution"])
        result = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.SOCWRPowerModel, minlp_solver)

        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        ## Not stable on mac
        # @test isapprox(result["objective"], 8073.94; atol = 1e0)

        @test isapprox(gen_status(result,"1","1"), gen_status(rop_result,"1","1"); atol=1e-6)
        @test isapprox(gen_status(result,"1","4"), gen_status(rop_result,"1","4"); atol=1e-6)
        @test isapprox(gen_status(result,"2","1"), gen_status(rop_result,"2","1"); atol=1e-6)
        @test isapprox(gen_status(result,"2","4"), gen_status(rop_result,"2","4"); atol=1e-6)
        @test isapprox(branch_status(result,"2","2"), branch_status(rop_result,"2","2"); atol=1e-6)
        @test isapprox(branch_status(result,"3","2"), branch_status(rop_result,"3","2"); atol=1e-6)
    end

    ## MLD does not support QC yet.  Requires alternate voltage constraint/voltage definitions
    # @testset "qc forward case" begin

    #     PowerModels.update_data!(mn_data, rop_result["solution"])
    #     result = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.QCWRPowerModel, minlp_solver)

    #     @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
    #     @test isapprox(result["objective"], 6168.399; atol = 1e-2)

    #     @test isapprox(gen_status(result,"1","1"), gen_status(rop_result,"1","1"); atol=1e-6)
    #     @test isapprox(gen_status(result,"1","4"), gen_status(rop_result,"1","4"); atol=1e-6)
    #     @test isapprox(gen_status(result,"2","1"), gen_status(rop_result,"2","1"); atol=1e-6)
    #     @test isapprox(gen_status(result,"2","4"), gen_status(rop_result,"2","4"); atol=1e-6)
    #     @test isapprox(branch_status(result,"2","2"), branch_status(rop_result,"2","2"); atol=1e-6)
    #     @test isapprox(branch_status(result,"3","2"), branch_status(rop_result,"3","2"); atol=1e-6)
    # end
end
=#