### Iterative Restoration Tests
@testset "Iterative" begin

    # @testset "test SOCWR Iterative" begin
    #     data = PowerModels.parse_file("../test/data/case5_restoration_min_damage.m")
    #     @testset "5-bus case" begin
    #         result = PowerModelsRestoration.run_iterative_restoration(data, PowerModels.SOCWRPowerModel, juniper_solver, repair_periods=2)
    #         #@show keys(result["solution"]["nw"])
    #         @test result["termination_status"] == LOCALLY_SOLVED
    #         @test isapprox(result["objective"], 132.27; atol = 1e0)

    #         @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
    #         @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
    #         @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
    #         @test isapprox(gen_status(result,"0","4"), 1; atol=1e-2)
    #         @test isapprox(gen_status(result,"1","4"), 1; atol=1e-2)
    #         @test isapprox(gen_status(result,"4","1"), 1; atol=1e-2)
    #         @test isapprox(gen_status(result,"4","2"), 1; atol=1e-2)
    #         @test isapprox(gen_status(result,"4","3"), 1; atol=1e-2)

    #         @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
    #         @test isapprox(branch_status(result,"4","4"), 1; atol=1e-2)

    #         @test isapprox(load_power(result, "0",["1","2","3"]), 7.9145; atol=1)
    #         @test isapprox(load_power(result, "1",["1","2","3"]), 9.8492; atol=1)
    #         @test isapprox(load_power(result, "2",["1","2","3"]), 9.8492; atol=1)
    #         @test isapprox(load_power(result, "3",["1","2","3"]), 9.8492; atol=1)
    #         @test isapprox(load_power(result, "4",["1","2","3"]), 9.8492; atol=1)
    #     end
    # end

    @testset "test dc Iterative" begin
        data = PowerModels.parse_file("../test/data/case5_restoration_min_damage.m")
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_iterative_restoration(data, PowerModels.DCPPowerModel, cbc_solver, repair_periods=3)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 82.67; atol = 1e0)
            @test isapprox(length(keys(result["solution"]["nw"])), 5; atol=1e0)    

            #there should be a new active item in each time period
            @test isapprox(count_active_items( result["solution"]["nw"]["0"] ), 15, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["1"]), 16, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["2"]), 17, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["3"]), 18, atol=1e0)
            @test isapprox(count_active_items( result["solution"]["nw"]["4"]), 19, atol=1e0)
            
            # @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
            # @test isapprox(gen_status(result,"0","4"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"1","4"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","1"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","2"), 1; atol=1e-2)
            # @test isapprox(gen_status(result,"4","3"), 1; atol=1e-2)

            # @test isapprox(branch_status(result,"0","1"), 0; atol=1e-2)
            # @test isapprox(branch_status(result,"4","4"), 1; atol=1e-2)

            @test isapprox(load_power(result, "0",["1","2","3"]), 6.336; atol=1e-1)
            @test isapprox(load_power(result, "1",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "3",["1","2","3"]), 10.0; atol=1e-1)
            @test isapprox(load_power(result, "4",["1","2","3"]), 10.0; atol=1e-1)
        end
    end

end