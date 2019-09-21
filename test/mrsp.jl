### Minimum Restoration Set Tests
@testset "MRSP" begin

    @testset "test dc mrsp" begin
        data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        PowerModelsRestoration.propagate_damage_status!(data)
        result = Dict()
        @testset "5-bus strg case" begin
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
        
        @testset "test ROP with MRSP preprocessing" begin
            PowerModelsRestoration.clean_solution!(result)
            PowerModels.update_data!(data, result["data"])
            PowerModels.update_data!(data, result["solution"])

            mn_data = build_mn_data(data, replicates=2)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 34.0; atol = 1e0)

            @test isapprox(bus_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(bus_status(result,"2","4"), 1; atol=1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","5"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"2","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"2","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"2","5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"0","1"), 0; atol=1e-2) 
            @test isapprox(storage_status(result,"0","2"), 1; atol=1e-2) 
            @test isapprox(storage_status(result,"2","1"), 0; atol=1e-2) 
            @test isapprox(storage_status(result,"2","2"), 1; atol=1e-2) 

            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"2","1"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"2","3"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2","4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"2","5"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"2","6"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"2","7"), 1; atol=1e-2)


            @test isapprox(load_power(result, "0",["1","2","3"]), 3.0; atol=1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 7.0; atol=1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10.0; atol=1)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"])+storage_power(result, "0",["1","2"]),  4.37; atol=1e1)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"])+storage_power(result, "1",["1","2"]),  10.66; atol=1e1)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"])+storage_power(result, "2",["1","2"]),  10.66; atol=1e1)
        end
    end


    @testset "test soc mrsp" begin
    data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
    PowerModelsRestoration.propagate_damage_status!(data)
    result = Dict()

        @testset "5-bus strg case" begin
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

        @testset "test ROP with MRSP preprocessing" begin
            PowerModelsRestoration.clean_solution!(result)
            PowerModels.update_data!(data, result["data"])
            PowerModels.update_data!(data, result["solution"])

            mn_data = build_mn_data(data, replicates=2)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)
            @test result[" termination_status"] == LOCALLY_SOLVED
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
            @test isapprox(gen_status_total, 3; atol=1e-2)

            # @test isapprox(gen_status(result,"1"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"2"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"3"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"5"), 1; atol=1e-2)

            @test isapprox(storage_status(result,"1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"2"), 1; atol=1e-2)

            # required due to oscillation between semantical solutions
            branch_status_total = sum(branch_status(result, id) for id in ["1", "2", "3", "4", "5", "6", "7"])
            @test isapprox(branch_status_total, 3; atol=1e-2)

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