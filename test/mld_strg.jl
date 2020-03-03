### Max Loading w/ Storage

@testset "test ac ml strg" begin
    @testset "5-bus strg case relaxed" begin
        result = run_mld_strg(case5_mld_strg, PowerModels.ACPPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 2286.29; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 6.297338; atol = 1e-2)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
    # incorrectly infeasible for Juniper v0.6
    # @testset "5-bus strg case uc" begin
    #     result = run_mld_strg_uc(case5_mld_strg_uc, PowerModels.ACPPowerModel, juniper_solver)

    #     #println(result["objective"])
    #     @test result["termination_status"] == LOCALLY_SOLVED
    #     @test isapprox(result["objective"], 2294.2098; atol = 1e-2)
    #     #println("active power: $(active_power_served(result))")
    #     @test isapprox(active_power_served(result), 7.1258; atol = 1e-1)
    #     @test isapprox(gen_status(result, "1"), 1.000000; atol = 1e-6)
    #     @test isapprox(gen_status(result, "2"), 1.000000; atol = 1e-6)
    #     @test isapprox(gen_status(result, "3"), 1.000000; atol = 1e-6)
    #     @test isapprox(gen_status(result, "4"), 1.000000; atol = 1e-6)
    #     @test isapprox(gen_status(result, "5"), 0.000000; atol = 1e-6)
    #     @test isapprox(storage_status(result, "1"), 1.000000; atol = 1e-6)
    #     @test isapprox(storage_status(result, "2"), 1.000000; atol = 1e-6)
    #     @test all_voltages_on(result)
    # end
    @testset "5-bus strg only case uc" begin
        result = run_mld_strg_uc(case5_mld_strg_only, PowerModels.ACPPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 2080.1068,; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.10708; atol = 1e-1)
        @test !haskey(result["solution"],"gen") # all generators are inactive
        @test isapprox(storage_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
end


@testset "test soc ml strg" begin
    @testset "5-bus strg case relaxed" begin
        result = run_mld_strg(case5_mld_strg, PowerModels.SOCWRPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 2286.3; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 6.297338; atol = 1e-2)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
    @testset "5-bus strg case uc" begin
        result = run_mld_strg_uc(case5_mld_strg_uc, PowerModels.SOCWRPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 2304.98; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 6.9476; atol = 1e-1)
        @test isapprox(gen_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "2"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "3"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "4"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "5"), 0.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
    @testset "5-bus strg only case uc" begin
        result = run_mld_strg_uc(case5_mld_strg_only, PowerModels.SOCWRPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 2080.11,; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.10708; atol = 1e-1)
        @test !haskey(result["solution"],"gen") # all generators are inactive
        @test isapprox(storage_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
end


# NLP solver required until alternate constraints are created for storage
@testset "test dc ml strg" begin
    @testset "5-bus case" begin
        result = run_mld_strg(case5_mld_strg, PowerModels.DCPPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 286.3198; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 6.31987; atol = 1e-1)
        @test all_gens_on(result)
        @test all_voltages_on(result)
    end
    @testset "5-bus strg case uc" begin
        result = run_mld_strg_uc(case5_mld_strg_uc, PowerModels.DCPPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 326.3098; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 6.30989; atol = 1e-1)
        @test isapprox(gen_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "2"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "3"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "4"), 1.000000; atol = 1e-6)
        @test isapprox(gen_status(result, "5"), 0.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
    @testset "5-bus strg only case uc" begin
        result = run_mld_strg_uc(case5_mld_strg_only, PowerModels.DCPPowerModel, juniper_solver)

        #println(result["objective"])
        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 80.41996; atol = 1e-2)
        #println("active power: $(active_power_served(result))")
        @test isapprox(active_power_served(result), 0.4199800; atol = 1e-1)
        @test !haskey(result["solution"],"gen") # all generators are inactive
        @test isapprox(storage_status(result, "1"), 1.000000; atol = 1e-6)
        @test isapprox(storage_status(result, "2"), 1.000000; atol = 1e-6)
        @test all_voltages_on(result)
    end
end


# PowerModels.SOCWRPowerModel does not support storage yet
@testset "test soc ml strg" begin
    # @testset "5-bus case" begin
    #     result = run_mld_strg(case5_mld_strg, PowerModels.SOCWRPowerModel, juniper_solver)

    #     #println(result["objective"])
    #     @test result["termination_status"] == LOCALLY_SOLVED
    #     @test isapprox(result["objective"], 286.6276942310463; atol = 1e-2)
    #     #println("active power: $(active_power_served(result))")
    #     @test isapprox(active_power_served(result), 6.683425000630671; atol = 1e-1)
    #     @test all_gens_on(result)
    #     @test all_voltages_on(result)
    # end
end

