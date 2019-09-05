### Minimum Restoration Set Tests
@testset "MRSP" begin

    @testset "test ac mrsp" begin
        @testset "5-bus strg case" begin
            result = PowerModelsRestoration.run_mrsp("../test/data/case5_restoration_strg.m", PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 3.0; atol = 1e-2)

            @test isapprox(gen_status(result,"1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"4"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"2"), 1; atol=1e-2)

            @test isapprox(branch_status(result,"1"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"3"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"5"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"6"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"7"), 1; atol=1e-2)
        end
    end

    @testset "test dc mrsp" begin
        @testset "5-bus strg case" begin
            result = PowerModelsRestoration.run_mrsp("../test/data/case5_restoration_strg.m", PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 3.0; atol = 1e-2)

            @test isapprox(gen_status(result,"1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"4"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"2"), 1; atol=1e-2)

            @test isapprox(branch_status(result,"1"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"3"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"5"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"6"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"7"), 1; atol=1e-2)
        end
    end


    @testset "test soc mrsp" begin
        @testset "5-bus strg case" begin
            result = PowerModelsRestoration.run_mrsp("../test/data/case5_restoration_strg.m", PowerModels.SOCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 3.0; atol = 1e-2)

            @test isapprox(gen_status(result,"1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"4"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"2"), 1; atol=1e-2)

            @test isapprox(branch_status(result,"1"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"3"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"5"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"6"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"7"), 1; atol=1e-2)
        end
    end

end