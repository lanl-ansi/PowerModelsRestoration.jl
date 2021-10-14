### RRR Restoration Tests
@testset "RRR" begin
    # data = PowerModels.parse_file("../test/data/case5_restoration_RRR.m")

    @testset "test AC RRR" begin
        @testset "5-bus case" begin
            # result = PowerModelsRestoration.run_RRR(data, PowerModels.ACPPowerModel, juniper_solver)

            # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
            # @test isapprox(result["objective"], 538.9; atol = 1e0)
            # @test isapprox(length(keys(result["solution"]["nw"])), 8; atol=1e-1)

            # #there should be a new active item in each time period
            # @test count_active_items(result["solution"]["nw"]["1"]) >= 15
            # @test count_active_items(result["solution"]["nw"]["2"]) >= 15
            # @test count_active_items(result["solution"]["nw"]["3"]) >= 17
            # @test count_active_items(result["solution"]["nw"]["4"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["5"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["6"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["7"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["8"]) == 22

            # @test isapprox(load_power(result, "1",["1","2","3"]), 9.57; atol=1e-1)
            # @test isapprox(load_power(result, "2",["1","2","3"]), 9.61; atol=1e-1)
            # @test isapprox(load_power(result, "3",["1","2","3"]), 9.62; atol=1e-1)
            # @test isapprox(load_power(result, "4",["1","2","3"]), 9.99; atol=1e-1)
            # @test isapprox(load_power(result, "5",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "6",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "7",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "8",["1","2","3"]), 10.0; atol=1e-1)
        end
    end

    @testset "test SOCWR RRR" begin
        @testset "5-bus case" begin
            # result = PowerModelsRestoration.run_RRR(data, PowerModels.SOCWRPowerModel, juniper_solver)

            # @test result["termination_status"] == PowerModels.LOCALLY_SOLVED
            # @test isapprox(result["objective"], 539.09; atol = 1e0)
            # @test isapprox(length(keys(result["solution"]["nw"])), 8; atol=1e-1)

            # #there should be a new active item in each time period
            # @test count_active_items(result["solution"]["nw"]["1"]) >= 15
            # @test count_active_items(result["solution"]["nw"]["2"]) >= 16
            # @test count_active_items(result["solution"]["nw"]["3"]) >= 17
            # @test count_active_items(result["solution"]["nw"]["4"]) >= 17
            # @test count_active_items(result["solution"]["nw"]["5"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["6"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["7"]) >= 18
            # @test count_active_items(result["solution"]["nw"]["8"]) == 22


            # @test isapprox(load_power(result, "1",["1","2","3"]), 9.57; atol=1e-1)
            # @test isapprox(load_power(result, "2",["1","2","3"]), 9.61; atol=1e-1)
            # @test isapprox(load_power(result, "3",["1","2","3"]), 9.62; atol=1e-1)
            # @test isapprox(load_power(result, "4",["1","2","3"]), 9.99; atol=1e-1)
            # @test isapprox(load_power(result, "5",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "6",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "7",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "8",["1","2","3"]), 10.0; atol=1e-1)
        end
    end



    @testset "test dc RRR" begin
        data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        @testset "5-bus case" begin
            # result = PowerModelsRestoration.run_RRR(data, PowerModels.DCPPowerModel, cbc_solver)

            # @test result["termination_status"] == PowerModels.OPTIMAL
            # @test isapprox(result["objective"], 1275.2; atol = 1e0)
            # @test isapprox(length(keys(result["solution"]["nw"])), 12; atol=1e-1)

            # #there should be a new active item in each time period
            # @test count_active_items( result["solution"]["nw"]["1"]) >= 9
            # @test count_active_items( result["solution"]["nw"]["2"]) >= 10
            # @test count_active_items( result["solution"]["nw"]["3"]) >= 12
            # @test count_active_items( result["solution"]["nw"]["4"]) >= 12
            # @test count_active_items( result["solution"]["nw"]["5"]) >= 15
            # @test count_active_items( result["solution"]["nw"]["6"]) >= 16
            # @test count_active_items( result["solution"]["nw"]["7"]) >= 16
            # @test count_active_items( result["solution"]["nw"]["8"]) >= 16
            # @test count_active_items( result["solution"]["nw"]["9"]) >= 16
            # @test count_active_items( result["solution"]["nw"]["10"]) >= 16
            # @test count_active_items( result["solution"]["nw"]["11"]) >= 16
            # @test count_active_items( result["solution"]["nw"]["12"]) == 22


            # @test isapprox(load_power(result, "1",["1","2","3"]), 3.0; atol=1e-1)
            # @test isapprox(load_power(result, "2",["1","2","3"]), 5.2; atol=1e-1)
            # @test isapprox(load_power(result, "3",["1","2","3"]), 7.0; atol=1e-1)
            # @test isapprox(load_power(result, "4",["1","2","3"]), 7.0; atol=1e-1)
            # @test isapprox(load_power(result, "5",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "6",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "7",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "8",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "9",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "10",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "11",["1","2","3"]), 10.0; atol=1e-1)
            # @test isapprox(load_power(result, "12",["1","2","3"]), 10.0; atol=1e-1)
        end


        @testset "multi-item restore" begin
            # # shunt damage and bus damage to the same component
            # data = PowerModels.parse_file("../test/data/case5_restoration_shunt.m")
            # damaged_n = Dict("bus" => ["1"])
            # damage_items!(data, damaged_n)
            # propagate_damage_status!(data)

            # # does it solve for ROP?
            # mn_data = build_mn_data(data, replicates=2)
            # result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)
            # @test result["termination_status"] == PowerModels.OPTIMAL

            # # does it solve for iter?
            # result = run_RRR(data, PowerModels.DCPPowerModel, cbc_solver)
            # @test result["termination_status"] == PowerModels.OPTIMAL

            # ## TODO What tests should compare ROP and RRR restoration?
        end

        @testset "total damage scenario" begin
            # totally damaged 3_bus system
            # data = PowerModels.parse_file("../test/data/case3_restoration_total.m")

            # result = run_RRR(data, PowerModels.DCPPowerModel, cbc_solver)
            #  @test result["termination_status"] == PowerModels.OPTIMAL
            #  @test isapprox(length(keys(result["solution"]["nw"])), 9; atol=1e-1)
        end

    end

end