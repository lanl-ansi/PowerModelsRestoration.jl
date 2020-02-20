### Data Transformation Tests

@testset "test topology propagation" begin
    @testset "component status updates" begin

        data_initial = PowerModels.parse_file("../test/data/case5_mld_ft.m")

        data = PowerModels.parse_file("../test/data/case5_mld_ft.m")
        PowerModels.propagate_topology_status!(data)

        @test length(data_initial["bus"]) == length(data["bus"])
        @test length(data_initial["gen"]) == length(data["gen"])
        @test length(data_initial["branch"]) == length(data["branch"])

        active_buses = Set(["2", "4", "5"])
        active_branches = Set(["8"])

        for (i,bus) in data["bus"]
            if i in active_buses
                @test bus["bus_type"] != 4
            else
                @test bus["bus_type"] == 4
            end
        end

        for (i,branch) in data["branch"]
            if i in active_branches
                @test branch["br_status"] == 1
            else
                @test branch["br_status"] == 0
            end
        end

    end

    @testset "component filtering updates" begin

        data_initial = PowerModels.parse_file("../test/data/case5_mld_ft.m")

        data = PowerModels.parse_file("../test/data/case5_mld_ft.m")
        PowerModels.propagate_topology_status!(data)
        PowerModels.select_largest_component!(data)

        @test length(data_initial["bus"]) == length(data["bus"])
        @test length(data_initial["gen"]) == length(data["gen"])
        @test length(data_initial["branch"]) == length(data["branch"])

        active_buses = Set(["4", "5"])
        active_branches = Set(["8"])

        for (i,bus) in data["bus"]
            if i in active_buses
                @test bus["bus_type"] != 4
            else
                @test bus["bus_type"] == 4
            end
        end

        for (i,branch) in data["branch"]
            if i in active_branches
                @test branch["br_status"] == 1
            else
                @test branch["br_status"] == 0
            end
        end

    end

    @testset "output values" begin

        data = PowerModels.parse_file("../test/data/case5_mld_ft.m")
        PowerModels.propagate_topology_status!(data)
        result = run_mld(data, PowerModels.ACPPowerModel, ipopt_solver)
        solution = result["solution"]

        active_buses = Set(["2", "4", "5"])
        active_gens = Set(["2", "3"])

        for (i,bus) in data["bus"]
            if i in active_buses
                @test !isequal(solution["bus"][i]["va"], NaN)
                # note status may be non-one from optimization
                @test solution["bus"][i]["status"] >= 0
            end
        end

        for (i,gen) in data["gen"]
            if i in active_gens
                @test !isequal(solution["gen"][i]["pg"], NaN)
                @test solution["gen"][i]["gen_status"] == 1
            end
        end

    end

end


@testset "test adding load weights from pti data" begin
    data = PowerModels.parse_file("../test/data/case5.raw")
    for (i,load) in data["load"]
        @test !haskey(load, "weight")
    end

    add_load_weights!(data)

    loads = data["load"]
    @test loads["1"]["weight"] == 100.0
    @test loads["2"]["weight"] == 10.0
    @test !haskey(loads["3"], "weight")
    @test loads["4"]["weight"] == 1.0
end
