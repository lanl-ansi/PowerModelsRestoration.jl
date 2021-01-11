### Iterative Restoration Tests
@testset "Iterative" begin
    data = PowerModels.parse_file("../test/data/case5_restoration_iterative.m")

    @testset "test AC Iterative" begin
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_iterative_restoration(data, PowerModels.ACPPowerModel, juniper_solver, repair_periods=3)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 1990.87; atol = 1e0)
            @test isapprox(length(keys(result["solution"]["nw"])), 9; atol=1e0)

            #there should be a new active item in each time period
            @test isapprox(count_active_items(result["solution"]["nw"]["0"]), 10, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["1"]), 14, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["2"]), 15, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["3"]), 16, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["4"]), 17, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["5"]), 18, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["6"]), 19, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["7"]), 20, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["8"]), 21, atol=1e0)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(bus_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"0","1"), 0; atol=1e-2)

            # repair order is degenerate and changes across OS
            # @test isapprox(gen_status(result,"1","3"), 1; atol=1e-2)

            # @test isapprox(gen_status(result,"2","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"2","3"), 1; atol=1e-2)

            # @test isapprox(gen_status(result,"3","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"3","2"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"3","3"), 1; atol=1e-2)

            # @test isapprox(gen_status(result,"4","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","2"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","3"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"4","1"), 1; atol=1e-2)


            @test isapprox(load_power(result, "0",["1","2","3"]), 4.38; atol=1e-1) # 0 period is MLD solution
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.57; atol=1e-1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 9.61; atol=1e-1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 9.62; atol=1e-1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 9.60; atol=1e-1)
            @test isapprox(load_power(result, "5",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "6",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "7",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "8",["1","2","3"]), 10.0; atol=1e-1)
        end
    end

    @testset "test SOCWR Iterative" begin
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_iterative_restoration(data, PowerModels.SOCWRPowerModel, juniper_solver, repair_periods=3)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 1990.91; atol = 1e0)
            @test isapprox(length(keys(result["solution"]["nw"])), 9; atol=1e0)

            #there should be a new active item in each time period
            @test isapprox(count_active_items(result["solution"]["nw"]["0"]), 10, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["1"]), 14, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["2"]), 15, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["3"]), 16, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["4"]), 17, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["5"]), 18, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["6"]), 19, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["7"]), 20, atol=1e0)
            @test isapprox(count_active_items(result["solution"]["nw"]["8"]), 21, atol=1e0)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(bus_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(storage_status(result,"0","1"), 0; atol=1e-2)

            # repair order is degenerate and changes across OS
            # @test isapprox(gen_status(result,"1","3"), 1; atol=1e-2)

            # @test isapprox(gen_status(result,"2","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"2","3"), 1; atol=1e-2)

            # @test isapprox(gen_status(result,"3","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"3","3"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"3","1"), 1; atol=1e-2)

            # @test isapprox(gen_status(result,"4","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","2"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","3"), 1; atol=1e-2)
            # @test isapprox(branch_status(result,"4","1"), 1; atol=1e-2)


            @test isapprox(load_power(result, "0",["1","2","3"]), 4.38; atol=1e-1) # 0 period is MLD solution
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.57; atol=1e-1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 9.61; atol=1e-1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 9.62; atol=1e-1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 9.60; atol=1e-1)
            @test isapprox(load_power(result, "5",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "6",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "7",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "8",["1","2","3"]), 10.0; atol=1e-1)
        end
    end



    @testset "test dc Iterative" begin
        data = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_iterative_restoration(data, PowerModels.DCPPowerModel, cbc_solver, repair_periods=3)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 755.72; atol = 1e0)
            @test isapprox(length(keys(result["solution"]["nw"])), 13; atol=1e0)

            #there should be a new active item in each time period
            @test isapprox(count_active_items( result["solution"]["nw"]["0"]), 6, atol=1e0) #MLD is the first time period will disable isolated devices
            @test isapprox(count_active_items( result["solution"]["nw"]["1"]), 10, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["2"]), 11, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["3"]), 12, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["4"]), 13, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["5"]), 14, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["6"]), 15, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["7"]), 16, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["8"]), 17, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["9"]), 18, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["10"]), 19, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["11"]), 20, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["12"]), 21, atol=1e0)

            # @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"0","4"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","2"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","3"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","4"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","5"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","6"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"0","7"), 0; atol=1e-2)
            # @test isapprox(bus_status(result,"0","1"), 0; atol=1e-2)
            # @test isapprox(bus_status(result,"0","2"), 0; atol=1e-2)
            # @test isapprox(bus_status(result,"0","4"), 0; atol=1e-2)
            # @test isapprox(storage_status(result,"0","1"), 0; atol=1e-2)


            @test isapprox(load_power(result, "0",["1","2","3"]), 3.0; atol=1e-1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 5.2; atol=1e-1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 5.2; atol=1e-1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 5.2; atol=1e-1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 9.2; atol=1e-1)
            @test isapprox(load_power(result, "5",["1","2","3"]), 9.46; atol=1e-1)
            @test isapprox(load_power(result, "6",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "7",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "8",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "9",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "10",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "11",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "12",["1","2","3"]), 10.0; atol=1e-1)
        end


        @testset "multi-item restore" begin
            # shunt damage and bus damage to the same component
            data = PowerModels.parse_file("../test/data/case5_restoration_iterative_shunt.m")
            damaged_n = Dict("bus" => ["1"])
            damage_items!(data, damaged_n)
            propagate_damage_status!(data)

            # does it solve for ROP?
            mn_data = build_mn_data(data, replicates=2)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)
            @test result["termination_status"] == OPTIMAL

            # does it solve for iter?
            result = run_iterative_restoration(data, PowerModels.DCPPowerModel, cbc_solver; repair_periods=2)
            @test result["termination_status"] == OPTIMAL
        end
    end

end