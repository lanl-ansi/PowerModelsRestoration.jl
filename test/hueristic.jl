### Hueristic Restoration Tests
@testset "Hueristic" begin

    @testset "test ac hueristic" begin
        mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_rop_heuristic(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            if isnan(gen_status(result,"0","1"))
                @test true
            else
                @test isapprox(gen_status(result,"0","1"), 0; atol = 1e-1)
            end
            if isnan(gen_status(result,"0","4"))
                @test true
            else
                @test isapprox(gen_status(result,"0","4"), 1; atol = 1e-1)
            end
            @test isapprox(gen_status(result,"2","1"), 1; atol = 1e-1)
            @test isapprox(gen_status(result,"2","4"), 1; atol = 1e-1)
        end
    end


    @testset "test dc hueristic" begin
        mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_rop_heuristic(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL

            @test isapprox(gen_status(result,"0","1"), 0; atol = 1e-1)
            @test isapprox(gen_status(result,"2","1"), 1; atol = 1e-1)
            @test isapprox(branch_status(result,"0","1"), 0; atol = 1e-1)
            @test isapprox(branch_status(result,"2","1"), 1; atol = 1e-1)
            @test isapprox(gen_status(result,"0","4"), 1; atol = 1e-1)
            @test isapprox(gen_status(result,"1","4"), 1; atol = 1e-1)
        end
    end

    @testset "test SOCWR hueristic" begin
        mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_rop_heuristic(mn_data, PowerModels.SOCWRPowerModel, ipopt_solver)

            @test isapprox(gen_status(result,"0","1"), 0; atol = 1e-1)
            @test isapprox(gen_status(result,"2","1"), 1; atol = 1e-1)
            @test isapprox(branch_status(result,"0","1"), 0; atol = 1e-1)
            @test isapprox(branch_status(result,"2","1"), 1; atol = 1e-1)
            @test isapprox(gen_status(result,"0","4"), 1; atol = 1e-1)
            @test isapprox(gen_status(result,"1","4"), 1; atol = 1e-1)
        end
    end

    ## MLD does not support QC yet.  Requires alternate voltage constraint/voltage definitions
    # @testset "test QCWR hueristic" begin
    #     mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=3)
    #     @testset "5-bus case" begin
    #         result = PowerModelsRestoration.run_rop_heuristic(mn_data, PowerModels.QCWRPowerModel, ipopt_solver)

    #         @test isapprox(result["solution"]["nw"]["1"]["gen"]["1"]["gen_status"], 0; atol = 1e-1)
    #         @test isapprox(result["solution"]["nw"]["3"]["gen"]["1"]["gen_status"], 1; atol = 1e-1)
    #         @test isapprox(result["solution"]["nw"]["1"]["branch"]["1"]["br_status"], 0; atol = 1e-1)
    #         @test isapprox(result["solution"]["nw"]["3"]["branch"]["1"]["br_status"], 1; atol = 1e-1)
    #         @test isapprox(result["solution"]["nw"]["1"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
    #         @test isapprox(result["solution"]["nw"]["2"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
    #     end
    # end

end