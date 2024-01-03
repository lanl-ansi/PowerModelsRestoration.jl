### RRR Restoration Ordering Tests
@testset "ROP RRR" begin



    @testset "test dc rop rrr" begin
        @testset "5-bus case" begin
            # Random.seed!(1234) # ensure RNG is set in run_rad
            data = PowerModels.parse_file("../test/data/case3_restoration_total_dmg.m")
            result = PowerModelsRestoration.run_rrr(data, PowerModels.DCPPowerModel, milp_solver)
            clean_status!(result["solution"])

            @test result["termination_status"] == PowerModels.OPTIMAL
            @test isapprox(result["objective"], 80.591; atol = 1e-1)

            @testset "gen_status" begin
                @test isapprox(gen_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"1","3"), 0; atol=1e-2)

                @test isapprox(gen_status(result,"2","1"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"3","1"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"3","2"), 0; atol=1e-2)
                @test isapprox(gen_status(result,"4","2"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"5","2"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"7","3"), 0; atol=1e-2)
                #@test isapprox(gen_status(result,"8","3"), 1; atol=1e-2) # drop for CI compat julia v1.6 and v1.10
                @test isapprox(gen_status(result,"9","3"), 1; atol=1e-2)

                @test isapprox(gen_status(result,"9","1"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"9","2"), 1; atol=1e-2)
                @test isapprox(gen_status(result,"9","3"), 1; atol=1e-2)
            end

            @testset "bus_status" begin  # heurstic does not return "status", but bus_type
                @test bus_type(result,"1","1") != 4
                @test bus_type(result,"1","2") == 4
                @test bus_type(result,"1","3") == 4

                @test bus_type(result,"2","1") != 4

                @test bus_type(result,"2","2") == 4
                @test bus_type(result,"3","2") != 4
                @test bus_type(result,"4","2") != 4

                @test bus_type(result,"4","3") == 4
                @test bus_type(result,"5","3") != 4
                @test bus_type(result,"6","3") != 4

                @test bus_type(result,"9","1") != 4
                @test bus_type(result,"9","2") != 4
                @test bus_type(result,"9","3") != 4
            end

            @testset "branch_status" begin
                @test isapprox(branch_status(result,"1","1"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","2"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"1","3"), 0; atol=1e-2)

                @test isapprox(branch_status(result,"5","1"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"6","1"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"7","1"), 1; atol=1e-2)

                @test isapprox(branch_status(result,"6","2"), 0; atol=1e-2)
                @test isapprox(branch_status(result,"7","2"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"8","2"), 1; atol=1e-2)

                #@test isapprox(branch_status(result,"8","3"), 0; atol=1e-2)  # drop for CI compat julia v1.6 and v1.10

                @test isapprox(branch_status(result,"9","1"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"9","2"), 1; atol=1e-2)
                @test isapprox(branch_status(result,"9","3"), 1; atol=1e-2)
            end

            @test isapprox(load_power(result, "1",["1","2","3"]), 0.0; atol=1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 1.1; atol=1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 1.1; atol=1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 2.2; atol=1)
            @test isapprox(load_power(result, "5",["1","2","3"]), 2.2; atol=1)
            @test isapprox(load_power(result, "6",["1","2","3"]), 3.035; atol=1)
            @test isapprox(load_power(result, "7",["1","2","3"]), 3.15; atol=1)
            @test isapprox(load_power(result, "8",["1","2","3"]), 3.15; atol=1)
            @test isapprox(load_power(result, "9",["1","2","3"]), 3.15; atol=1)
        end
    end


    @testset "RRR Time limits" begin
        data = PowerModels.parse_file("../test/data/case3_restoration_total_dmg.m")

        # test time_limit=0.0, purely recovery problem
        result = PowerModelsRestoration.run_rrr(data, PowerModels.DCPPowerModel, milp_solver, time_limit=0.0,minimum_solver_time_limit=0.0, minimum_recovery_problem_time_limit=1.0)
        clean_status!(result["solution"])

        util_sol = utilization_repair_order(data)
        for (nwid,repairs) in get_component_activations(result["solution"])
            # test that each repair occurs in the same period in sol util and rrr
            for repair in repairs
                @test repair in util_sol[nwid]
            end
            for repair in util_sol[nwid]
                @test repair in repairs
            end
        end

        @test result["termination_status"] == PowerModels.OPTIMAL
        @test isapprox(result["objective"], 10.6; atol = 1e-1)
        @test length(result["stats"]["solve_time"]) == 1 # recursion depth==1 due to time limit
        @test result["stats"]["solve_time"][1] <=1.0 # recovery problem solve time
    end

end
