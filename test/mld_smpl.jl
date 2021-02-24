

@testset "test ac ml smpl" begin
    @testset "3-bus case" begin
        result = run_mld_smpl(case3_mld, PowerModels.ACPPowerModel, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 1.0343968918668984; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 1.0343968580341767; atol = 1e-1)
    end
    @testset "3-bus shunt case" begin
        result = run_mld_smpl(case3_mld_s, PowerModels.ACPPowerModel, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 2.6169184606322173; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.7951651020410877; atol = 1e-1)
    end
    @testset "3-bus uc case" begin
        result = run_mld_smpl(case3_mld_uc, PowerModels.ACPPowerModel, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], -1.890295644489507; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 1.1343738262510479; atol = 1e-1)
    end
    @testset "3-bus line charge case" begin
        result = run_mld_smpl(case3_mld_lc, PowerModels.ACPPowerModel, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], -10.82123253253493; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.008694603282259982; atol = 1e-1)
    end
    @testset "24-bus rts case" begin
        result = run_mld_smpl(case24, PowerModels.ACPPowerModel, ipopt_solver)

        #println(result["objective"])
        @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
        @test isapprox(result["objective"], 31.83001231870211; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 28.49999875765314; atol = 1e-0)
    end
end