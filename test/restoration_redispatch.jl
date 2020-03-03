### Restoration Redispatch Tests


@testset "Restoration Redispatch" begin

    @testset "test ac redispatch" begin
        mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
        result_rop = PowerModelsRestoration.run_rop(mn_data, PowerModels.ACPPowerModel, juniper_solver)

        PowerModelsRestoration.clean_solution!(result_rop)
        clean_status!(result_rop["solution"])
        update_status!(mn_data, result_rop["solution"])

        result_sim = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.ACPPowerModel, ipopt_solver)
        @test result_sim["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_sim["objective"], 53.14; atol = 1)

        #@test isapprox(gen_status(result_sim,"0","1"), gen_status(result_rop,"0","1"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"0","2"), gen_status(result_rop,"0","2"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"0","3"), gen_status(result_rop,"0","3"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"0","4"), gen_status(result_rop,"0","4"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","1"), gen_status(result_rop,"1","1"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","2"), gen_status(result_rop,"1","2"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","3"), gen_status(result_rop,"1","3"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","4"), gen_status(result_rop,"1","4"); atol=1e-2)

        @test isapprox(load_power(result_sim, "0",["1","2","3"]), 4.3808; atol=1)
        @test isapprox(load_power(result_sim, "1",["1","2","3"]), 9.8492; atol=1)

        @test isapprox(gen_power(result_sim, "0",["4","5"]), 4.398; atol=1)
        @test isapprox(gen_power(result_sim, "1",["3","4","5"]), 9.87; atol=1)
    end


    @testset "test dc redispatch" begin
        mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
        result_rop = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

        PowerModelsRestoration.clean_solution!(result_rop)
        clean_status!(result_rop["solution"])
        update_status!(mn_data, result_rop["solution"])

        result_sim = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.ACPPowerModel, ipopt_solver)
        @test result_sim["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_sim["objective"], 53.09; atol = 1)

        #@test isapprox(gen_status(result_sim,"0","1"), gen_status(result_rop,"0","1"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"0","2"), gen_status(result_rop,"0","2"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"0","3"), gen_status(result_rop,"0","3"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"0","4"), gen_status(result_rop,"0","4"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","1"), gen_status(result_rop,"1","1"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","2"), gen_status(result_rop,"1","2"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","3"), gen_status(result_rop,"1","3"); atol=1e-2)
        #@test isapprox(gen_status(result_sim,"1","4"), gen_status(result_rop,"1","4"); atol=1e-2)

        @test isapprox(load_power(result_sim, "0",["1","2","3"]), 4.3808; atol=1)
        @test isapprox(load_power(result_sim, "1",["1","2","3"]), 9.8492; atol=1)

        @test isapprox(gen_power(result_sim, "0",["4","5"]), 4.398; atol=1)
        @test isapprox(gen_power(result_sim, "1",["2","3","4","5"]), 9.87; atol=1)
    end

    @testset "test soc redispatch" begin
        mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
        result_rop = PowerModelsRestoration.run_rop(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)

        PowerModelsRestoration.clean_solution!(result_rop)
        clean_status!(result_rop["solution"])
        update_status!(mn_data, result_rop["solution"])

        result_sim = PowerModelsRestoration.run_restoration_redispatch(mn_data, PowerModels.ACPPowerModel, ipopt_solver)
        @test result_sim["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result_sim["objective"], 53.15; atol = 1)

        # @test isapprox(gen_status(result_sim,"0","1"), gen_status(result_rop,"0","1"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"0","2"), gen_status(result_rop,"0","2"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"0","3"), gen_status(result_rop,"0","3"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"0","4"), gen_status(result_rop,"0","4"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"1","1"), gen_status(result_rop,"1","1"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"1","2"), gen_status(result_rop,"1","2"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"1","3"), gen_status(result_rop,"1","3"); atol=1e-2)
        # @test isapprox(gen_status(result_sim,"1","4"), gen_status(result_rop,"1","4"); atol=1e-2)

        @test isapprox(load_power(result_sim, "0",["1","2","3"]), 4.3808; atol=1)
        @test isapprox(load_power(result_sim, "1",["1","2","3"]), 9.8492; atol=1)

        @test isapprox(gen_power(result_sim, "0",["4","5"]), 4.398; atol=1)
        @test isapprox(gen_power(result_sim, "1",["2","3","4","5"]), 9.87; atol=1)
    end

    # ## MLD does not support QC yet.  Requires alternate voltage constraint/voltage definitions
    # # @testset "test QCWR hueristic" begin
    # #     mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=3)
    # #     @testset "5-bus case" begin
    # #         result = PowerModelsRestoration.run_rop_heuristic(mn_data, PowerModels.QCWRPowerModel, ipopt_solver)

    # #         @test isapprox(result["solution"]["nw"]["1"]["gen"]["1"]["gen_status"], 0; atol = 1e-1)
    # #         @test isapprox(result["solution"]["nw"]["3"]["gen"]["1"]["gen_status"], 1; atol = 1e-1)
    # #         @test isapprox(result["solution"]["nw"]["1"]["branch"]["1"]["br_status"], 0; atol = 1e-1)
    # #         @test isapprox(result["solution"]["nw"]["3"]["branch"]["1"]["br_status"], 1; atol = 1e-1)
    # #         @test isapprox(result["solution"]["nw"]["1"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
    # #         @test isapprox(result["solution"]["nw"]["2"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
    # #     end
    # # end

end