### Minimum Restoration Set Tests
@testset "MRSP" begin

    @testset "test dc mrsp" begin
        @testset "5-bus strg case" begin
            data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
            PowerModelsRestoration.propagate_damage_status!(data)
            result = PowerModelsRestoration.run_mrsp(data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 5.0; atol = 1e-2)

            @test isapprox(bus_status(result,"1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"4"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"10"), 1; atol=1e-2)

            @test isapprox(gen_status(result,"1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"4"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"2"), 1; atol=1e-2)

            @test isapprox(branch_status(result,"1"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"3"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"5"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"6"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"7"), 1; atol=1e-2)
        end
    end


    @testset "test soc mrsp" begin
        @testset "5-bus strg case" begin
            data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
            PowerModelsRestoration.propagate_damage_status!(data)
            result = PowerModelsRestoration.run_mrsp(data, PowerModels.SOCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 5.0; atol = 1e-2)

            @test isapprox(bus_status(result,"1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"4"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"10"), 1; atol=1e-2)

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
            @test isapprox(branch_status(result,"5"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"6"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"7"), 1; atol=1e-2)
        end
    end

    @testset "test ac mrsp" begin
        @testset "5-bus strg case" begin
            data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
            PowerModelsRestoration.propagate_damage_status!(data)
            result = PowerModelsRestoration.run_mrsp(data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 5.0; atol = 1e-2)

            @test isapprox(bus_status(result,"1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"4"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"10"), 1; atol=1e-2)

            # required due to oscillation between semantical solutions
            gen_status_total = sum(gen_status(result, id) for id in ["1", "2", "3", "4", "5"])
            @test isapprox(gen_status_total, 2; atol=1e-2)

            # @test isapprox(gen_status(result,"1"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"2"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"3"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"2"), 1; atol=1e-2)

            # required due to oscillation between semantical solutions
            branch_status_total = sum(branch_status(result, id) for id in ["1", "2", "3", "4", "5", "6", "7"])
            @test isapprox(branch_status_total, 4; atol=1e-2)

            # @test isapprox(branch_status(result,"1"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"2"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"3"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"4"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"5"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"6"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"7"), 0; atol=1e-2)
        end
    end

end