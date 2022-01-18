### RAD Restoration Ordering Tests
@testset "ROP RAD" begin



    @testset "test dc rop rad" begin
        @testset "5-bus case" begin
            Random.seed!(1234) # ensure RNG is set in run_rad
            data = PowerModels.parse_file("../test/data/case5_restoration_total_dmg.m")
            result = PowerModelsRestoration.run_rad(data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
            @test isapprox(result["objective"], 145.3; atol = 1e-1)

            @testset "gen_status" begin
                @test isapprox(gen_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","3"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","4"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","5"), 0; atol=1e-2)

                @test isapprox(gen_status(result,"2","3"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"3","3"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"4","4"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"5","4"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"6","4"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"7","2"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"8","2"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"9","2"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"11","5"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"12","5"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"13","5"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"12","1"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"13","1"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"14","1"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"19","1"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"19","2"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"19","3"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"19","4"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"19","5"), 1; atol=1e-2)
            end

            @testset "bus_status" begin
                @test isapprox(bus_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"1","3"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"1","4"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"1","10"), 0; atol=1e-2)

                @test isapprox(bus_status(result,"2","3"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"3","3"), 1; atol=1e-2)

                @test isapprox(bus_status(result,"3","4"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"4","4"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"5","4"), 1; atol=1e-2)

                @test isapprox(bus_status(result,"5","2"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"6","2"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"7","2"), 1; atol=1e-2)

                @test isapprox(bus_status(result,"6","1"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"7","1"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"8","1"), 1; atol=1e-2)

                @test isapprox(bus_status(result,"9","10"), 0; atol=1e-2)
                @test isapprox(bus_status(result,"10","10"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"11","10"), 1; atol=1e-2)

                @test isapprox(bus_status(result,"19","1"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"19","2"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"19","3"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"19","4"), 1; atol=1e-2)
                @test isapprox(bus_status(result,"19","10"), 1; atol=1e-2)
            end

            @testset "branch_status" begin
                @test isapprox(branch_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","3"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","4"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","5"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","6"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","7"), 0; atol=1e-2)

                @test isapprox(branch_status(result,"3","5"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"4","5"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"5","5"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"8","1"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"9","1"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"10","1"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"11","3"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"12","3"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"13","3"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"13","4"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"14","4"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"15","4"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"16","6"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"17","6"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"18","6"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"15","2"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"16","2"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"17","2"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"18","7"), 0; atol=1e-2)

                @test isapprox(branch_status(result,"19","1"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"19","2"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"19","3"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"19","4"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"19","5"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"19","6"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"19","7"), 1; atol=1e-2)
            end

            @test isapprox(load_power(result, "0",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 3.0; atol=1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 3.0; atol=1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 5.2; atol=1)
            @test isapprox(load_power(result, "5",["1","2","3"]), 7.0; atol=1)
            @test isapprox(load_power(result, "6",["1","2","3"]), 7.0; atol=1)
            @test isapprox(load_power(result, "7",["1","2","3"]), 7.0; atol=1)
            @test isapprox(load_power(result, "8",["1","2","3"]), 7.0; atol=1)
            @test isapprox(load_power(result, "9",["1","2","3"]), 8.7; atol=1)
            @test isapprox(load_power(result, "10",["1","2","3"]), 8.7; atol=1)
            @test isapprox(load_power(result, "11",["1","2","3"]), 8.7; atol=1)
            @test isapprox(load_power(result, "12",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "13",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "14",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "15",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "16",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "17",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "18",["1","2","3"]), 10.0; atol=1)
            @test isapprox(load_power(result, "19",["1","2","3"]), 10.0; atol=1)

        end
    end
end
