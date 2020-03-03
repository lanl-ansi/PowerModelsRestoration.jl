### Data Structure Tests

@testset "test ml output" begin
    @testset "active and reactive" begin
        result = run_mld(case3_mld_s, PowerModels.ACPPowerModel, ipopt_solver)

        @test result["termination_status"] == LOCALLY_SOLVED
        for (i,bus) in result["solution"]["bus"]
            @test haskey(bus, "status")
            @test haskey(bus, "vm")
            @test haskey(bus, "va")
            @test bus["status"] >= 0.0 && bus["status"] <= 1.0
        end

        for (i,load) in result["solution"]["load"]
            @test haskey(load, "status")
            @test haskey(load, "pd")
            @test haskey(load, "qd")
            @test load["status"] >= 0.0 && load["status"] <= 1.0
        end

        for (i,shunt) in result["solution"]["shunt"]
            @test haskey(shunt, "status")
            @test haskey(shunt, "gs")
            @test haskey(shunt, "bs")
            @test shunt["status"] >= 0.0 && shunt["status"] <= 1.0
        end

        for (i,gen) in result["solution"]["gen"]
            @test haskey(gen, "pg")
            @test haskey(gen, "qg")
            @test haskey(gen, "gen_status")
            @test gen["gen_status"] >= 0.0 && gen["gen_status"] <= 1.0
        end

        bus2 = result["solution"]["bus"]["2"] # load 1, shunt 1
        bus3 = result["solution"]["bus"]["3"] # load 2, shunt 2

        load1 = result["solution"]["load"]["1"]
        load2 = result["solution"]["load"]["2"]
        @test isapprox(load1["pd"], 0.000000; atol = 1e-3)
        @test isapprox(load1["qd"], 0.000000; atol = 1e-3)
        @test isapprox(load2["pd"], 0.795165; atol = 1e-3)
        @test isapprox(load2["qd"], 0.397583; atol = 1e-3)

        shunt1 = result["solution"]["shunt"]["1"]
        shunt2 = result["solution"]["shunt"]["2"]
        @test isapprox(shunt1["gs"],  0.00821754; atol = 1e-3)
        @test isapprox(shunt1["bs"], -0.246526; atol = 1e-3)
        @test isapprox(shunt2["gs"],  0.000000; atol = 1e-3)
        @test isapprox(shunt2["bs"], -0.300000; atol = 1e-3)
    end

    @testset "active only" begin
        result = run_mld(case3_mld_s, PowerModels.DCPPowerModel, ipopt_solver)

        @test result["termination_status"] == LOCALLY_SOLVED
        for (i,bus) in result["solution"]["bus"]
            #if bus[PowerModels.pm_component_status["bus"]] != PowerModels.pm_component_status_inactive["bus"]
                @test haskey(bus, "vm")
                @test haskey(bus, "va")
                @test bus["status"] >= 0.0 && bus["status"] <= 1.0
            #end
        end

        for (i,load) in result["solution"]["load"]
            @test haskey(load, "status")
            @test haskey(load, "pd")
            @test haskey(load, "qd")
            @test load["status"] >= 0.0 && load["status"] <= 1.0
        end

        for (i,shunt) in result["solution"]["shunt"]
            @test haskey(shunt, "status")
            @test haskey(shunt, "gs")
            @test haskey(shunt, "bs")
            @test shunt["status"] >= 0.0 && shunt["status"] <= 1.0
        end

        for (i,gen) in result["solution"]["gen"]
            @test haskey(gen, "pg")
            @test haskey(gen, "qg")
            @test haskey(gen, "gen_status")
            @test gen["gen_status"] >= 0.0 && gen["gen_status"] <= 1.0
        end

        load1 = result["solution"]["load"]["1"]
        load2 = result["solution"]["load"]["2"]
        @test isapprox(load1["pd"], 0.570512; atol=1e-3)
        @test isapprox(load1["qd"], 0.285256; atol=1e-3)
        @test isapprox(load2["pd"], 0.800; atol=1e-3)
        @test isapprox(load2["qd"], 0.400; atol=1e-3)

        shunt1 = result["solution"]["shunt"]["1"]
        shunt2 = result["solution"]["shunt"]["2"]
        @test isapprox(shunt1["gs"],  0.010; atol=1e-3)
        @test isapprox(shunt1["bs"], -0.300; atol=1e-3)
        @test isapprox(shunt2["gs"],  0.000; atol=1e-3)
        @test isapprox(shunt2["bs"], -0.300; atol=1e-3)
    end
end

