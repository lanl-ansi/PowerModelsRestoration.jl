### RAD Restoration Ordering Tests
@testset "ROP RAD" begin



    @testset "test dc rop rad" begin
        @testset "5-bus case" begin
            data = PowerModels.parse_file("../test/data/case3_restoration_total_dmg.m")
            rng = Random.MersenneTwister(1234) # ensure RNG is set in run_rad
            result = PowerModelsRestoration.run_rad(data, PowerModels.DCPPowerModel, cbc_solver,rng=rng)

            @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
            @test isapprox(result["objective"], 12.9; atol = 1e-1)

            @testset "gen_status" begin
                @test isapprox(gen_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","3"), 0; atol=1e-2)

                @test isapprox(gen_status(result,"3","2"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"4","2"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"5","2"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"5","1"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"6","1"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"7","1"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"7","3"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"8","3"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"9","1"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"9","2"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"9","3"), 1; atol=1e-2)
            end
            @testset "bus_status" begin  # heurstic does not return "status", bu
                @test bus_type(result,"1","1") == 4
                @test bus_type(result,"1","2") == 4
                @test bus_type(result,"1","3") == 4

                @test bus_type(result,"3","2") == 4
                @test bus_type(result,"4","2") != 4
                @test bus_type(result,"5","2") != 4

                @test bus_type(result,"5","1") == 4
                @test bus_type(result,"6","1") != 4
                @test bus_type(result,"7","1") != 4

                @test bus_type(result,"6","3") == 4
                @test bus_type(result,"7","3") != 4
                @test bus_type(result,"8","3") != 4

                @test bus_type(result,"9","1") != 4
                @test bus_type(result,"9","2") != 4
                @test bus_type(result,"9","3") != 4
            end
            @testset "branch_status" begin
                @test isapprox(branch_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","3"), 0; atol=1e-2)

                @test isapprox(branch_status(result,"7","1"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"8","1"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"7","2"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"8","2"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"8","3"), 0; atol=1e-2)

                @test isapprox(branch_status(result,"9","1"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"9","2"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"9","3"), 1; atol=1e-2)
            end

            @test isapprox(load_power(result, "0",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 1.1; atol=1)
            @test isapprox(load_power(result, "5",["1","2","3"]), 1.1; atol=1)
            @test isapprox(load_power(result, "6",["1","2","3"]), 2.2; atol=1)
            @test isapprox(load_power(result, "7",["1","2","3"]), 2.2; atol=1)
            @test isapprox(load_power(result, "8",["1","2","3"]), 3.15; atol=1)
            @test isapprox(load_power(result, "9",["1","2","3"]), 3.15; atol=1)


        end
    end
end
