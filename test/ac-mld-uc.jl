

@testset "test ac ml uc heuristic" begin
    @testset "3-bus case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case3_mld, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 1.0344; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 1.0344; atol = 1e-1)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
    @testset "3-bus uc case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case3_mld_uc, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 0.49999999; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.49999999; atol = 1e-1)
        @test isapprox(gen_status(result, "1"), 0.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
    @testset "3-bus line charge case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case3_mld_lc, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 210.641; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.34770; atol = 1e-3)
        #@test all_gens_on(result)
        #println([bus["status"] for (i,bus) in result["solution"]["bus"]])
        @test isapprox(bus_status(result, "1"), 0.0; atol = 1e-4)
        @test isapprox(bus_status(result, "2"), 0.0; atol = 1e-4)
        @test isapprox(bus_status(result, "3"), 0.0; atol = 1e-4)
    end
    @testset "5-bus weights case" begin
        data = PowerModels.parse_file("../test/data/case5.raw")
        add_load_weights!(data)

        result = PowerModelsRestoration.run_ac_mld_uc(data, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 310.635; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 4.063481; atol = 1e-3)
        #@test all_gens_on(result)
        #println([bus["status"] for (i,bus) in result["solution"]["bus"]])
        @test isapprox(bus_status(result, "1"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "2"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "3"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "4"), 1.0; atol = 1e-4)
        @test isapprox(bus_status(result, "10"), 0.0; atol = 1e-4)

        loads = result["solution"]["load"]

        # load 1 is high priorty, load 2 is medium priorty
        @test loads["1"]["status"] >= loads["2"]["status"]

        # load 2 is medium priorty, loads 3/4 are low priorty
        @test loads["2"]["status"] >= loads["3"]["status"]
        @test loads["2"]["status"] >= loads["4"]["status"]
    end
    @testset "24-bus rts case" begin
        result = PowerModelsRestoration.run_ac_mld_uc(case24, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 31.83; atol = 1e-1)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 28.5; atol = 1e-0)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
end
