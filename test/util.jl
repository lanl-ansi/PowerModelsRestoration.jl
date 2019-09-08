@testset "Forward Restoration" begin
    mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
    rop_result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)
    PowerModelsRestoration.clean_solution!(rop_result)

    @testset "ac forward case" begin

        PowerModels.update_data!(mn_data, rop_result["solution"])
        result = PowerModelsRestoration.run_forward_restoration(mn_data, PowerModels.ACPPowerModel, juniper_solver)

        @test result["termination_status"] == LOCALLY_SOLVED
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
        result = PowerModelsRestoration.run_forward_restoration(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 8834.38; atol = 1e0)

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
    #     result = PowerModelsRestoration.run_forward_restoration(mn_data, PowerModels.QCWRPowerModel, juniper_solver)

    #     @test result["termination_status"] == LOCALLY_SOLVED
    #     @test isapprox(result["objective"], 6168.399; atol = 1e-2)

    #     @test isapprox(gen_status(result,"1","1"), gen_status(rop_result,"1","1"); atol=1e-6)
    #     @test isapprox(gen_status(result,"1","4"), gen_status(rop_result,"1","4"); atol=1e-6)
    #     @test isapprox(gen_status(result,"2","1"), gen_status(rop_result,"2","1"); atol=1e-6)
    #     @test isapprox(gen_status(result,"2","4"), gen_status(rop_result,"2","4"); atol=1e-6)
    #     @test isapprox(branch_status(result,"2","2"), branch_status(rop_result,"2","2"); atol=1e-6)
    #     @test isapprox(branch_status(result,"3","2"), branch_status(rop_result,"3","2"); atol=1e-6)
    # end
end