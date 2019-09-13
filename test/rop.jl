### Restoration Ordering Tests
@testset "ROP" begin

    @testset "test ac rop" begin
        @testset "5-bus case" begin
            mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=1)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 36.29; atol = 1)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-2)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4.3808; atol=1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.8492; atol=1)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"]), 4.398; atol=1)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 9.87; atol=1)

        end

        @testset "5-bus storage case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=1)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 46.0; atol = 1e0)

            @test isapprox(bus_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(bus_status(result,"1","4"), 1; atol=1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-2)

            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"1","1"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"1","2"), 1; atol=1e-2)
            # cross platfrom stability
            @test isapprox(branch_status(result,"1","3"), 1; atol=1e-2)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-2)

            @test isapprox(load_power(result, "0",["1","2","3"]), 3.0; atol=1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.8492; atol=1)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"])+storage_power(result, "0",["1","2"]),  4.37; atol=1e1)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"])+storage_power(result, "1",["1","2"]),  10.66; atol=1e1)
        end
    end


    @testset "test dc rop" begin
        @testset "5-bus case" begin
            mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 53.20; atol = 1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"1","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4.3999; atol=1e-2)
            @test isapprox(load_power(result, "1",["1","2","3"]), 10.0; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10.0; atol=1e-2)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"]), 4.398; atol=1e-2)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 10.0; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 10.0; atol=1e-2)

        end

        @testset "5-bus strg case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 98.8; atol = 1e-2)

            @test isapprox(bus_status(result,"0","1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"0","2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"0","3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"0","4"), 0; atol=1e-2)
            @test isapprox(bus_status(result,"0","10"), 1; atol=1e-2)

            @test isapprox(bus_status(result,"1","1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"1","2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"1","3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"1","4"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"1","10"), 1; atol=1e-2)

            @test isapprox(bus_status(result,"2","1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2","2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2","3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2","4"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"2","10"), 1; atol=1e-2)

            @test isapprox(bus_status(result,"3","1"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3","2"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3","3"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3","4"), 1; atol=1e-2)
            @test isapprox(bus_status(result,"3","10"), 1; atol=1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"0","4"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","5"), 1; atol=1e-6)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","5"), 1; atol=1e-6)

            @test isapprox(gen_status(result,"2","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","5"), 1; atol=1e-6)

            @test isapprox(gen_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","5"), 1; atol=1e-6)


            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","3"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","5"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","6"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","7"), 0; atol=1e-6)

            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","3"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"1","5"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","6"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","7"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","3"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","5"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","6"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","7"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","3"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","5"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","6"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","7"), 1; atol=1e-6)


            @test isapprox(storage_status(result, "0", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "0", "2"), 1; atol=1e-6)

            @test isapprox(storage_status(result, "1", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-6)

            @test isapprox(storage_status(result, "2", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-6)

            @test isapprox(storage_status(result, "3", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "3", "2"), 1; atol=1e-6)


            @test isapprox(load_power(result, "0",["1","2","3"]), 3.00; atol=1e-2)
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.20; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10.00; atol=1e-2)
            @test isapprox(load_power(result, "3",["1","2","3"]), 10.00; atol=1e-2)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"])+storage_power(result, "0",["1","2"]), 3.00; atol=1e-2)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"])+storage_power(result, "1",["1","2"]), 9.20; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"])+storage_power(result, "2",["1","2"]), 10.00; atol=1e-2)
            @test isapprox(gen_power(result, "3",["1","2","3","4","5"])+storage_power(result, "3",["1","2"]), 10.00; atol=1e-2)
        end
    end


    #numerical stabilty issues.  This can be fixed by changing variable_generation_indicator start value to 0.5
    @testset "test soc rop" begin
        @testset "5-bus case" begin
            mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=1)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            # non-stable solution in osx and linux
            @test isapprox(result["objective"], 36.30; atol = 1e1)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-2)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4.3808; atol=1)
            # cross platform stability
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.999; atol=1)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"]), 4.398; atol=1)
            # cross platform stability
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 10.40; atol=1)
        end
    end

    #=
    @testset "test qc rop" begin
        # solution stabilty issues on OS X and Linux
        @testset "5-bus strg case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.QCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 6701.3818; atol = 1e-2)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-4)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-4)
            @test isapprox(gen_status(result,"1","3"), 0; atol=1e-4)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","1"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","2"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","3"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","4"), 1; atol=1e-4)

            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","4"), 0; atol=1e-6)

            @test isapprox(storage_status(result, "1", "1"), 0; atol=1e-4)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "2", "1"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "3", "1"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "3", "2"), 1; atol=1e-4)

            @test isapprox(load_power(result, "1",["1","2","3"]), 4.3816; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 7.0; atol=1e-2)
            @test isapprox(load_power(result, "3",["1","2","3"]), 10.0; atol=1e-2)

            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 3.7721; atol=2e-1)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 5.8908; atol=2e-1)
            @test isapprox(gen_power(result, "3",["1","2","3","4","5"]), 8.3770; atol=2e-1)

            @test isapprox(storage_power(result, "1",["1","2"]), 0.6261; atol=2e-1)
            @test isapprox(storage_power(result, "2",["1","2"]), 0.8430; atol=2e-1)
            @test isapprox(storage_power(result, "3",["1","2"]), 1.0273; atol=2e-1)

        end
    end
    =#

end

