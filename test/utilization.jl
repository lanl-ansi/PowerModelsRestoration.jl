
### UTIL Restoration Tests
@testset "UTIL" begin

    @testset "total damage scenario" begin
        # totally damaged 5_bus system, includes storage
        data = PowerModels.parse_file("../test/data/case5_restoration_total_dmg.m")

        priority_order = run_UTIL(data)

        # check restoration order
        @test length(priority_order["1"]) == 1
        @test length(priority_order["2"]) == 1
        @test length(priority_order["3"]) == 0 # repair delayed for feasability
        @test length(priority_order["4"]) == 1
        @test length(priority_order["5"]) == 1
        @test length(priority_order["6"]) == 1
        @test length(priority_order["7"]) == 0 # repair delayed for feasability
        @test length(priority_order["8"]) == 0 # repair delayed for feasability
        @test length(priority_order["9"]) == 1
        @test length(priority_order["10"]) == 1
        @test length(priority_order["11"]) == 1
        @test length(priority_order["12"]) == 4
        @test length(priority_order["13"]) == 1
        @test length(priority_order["14"]) == 1
        @test length(priority_order["15"]) == 1
        @test length(priority_order["16"]) == 1
        @test length(priority_order["17"]) == 1
        @test length(priority_order["17"]) == 1
        @test length(priority_order["17"]) == 1


        test_priority = Dict{String, Any}(
            "14" => [("branch", "5")], "4" => [("storage", "2")], "1" => [("bus", "1")], "12" => [("bus", "4"), ("gen", "4"),
            ("storage", "1"), ("branch", "7")], "2" => [("bus", "10")], "6" => [("gen", "2")], "7" => Tuple{String, String}[],
            "11" => [("branch", "1")], "13" => [("branch", "4")], "8" => Tuple{String, String}[], "17" => [("branch", "3")],
            "5" => [("gen", "1")], "10" => [("bus", "3")], "15" => [("branch", "2")], "19" => [("gen", "5")],
            "9" => [("bus", "2")], "16" => [("branch", "6")], "18" => [("gen", "3")], "3" => Tuple{String, String}[]
        )

        for (priority_id, components) in priority_order
            @test components == test_priority[priority_id]
        end

    end
end
