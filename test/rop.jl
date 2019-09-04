### Restoration Ordering Tests
@testset "ROP" begin

    @testset "test ac rop" begin
        mn_data = build_mn_data(case5_restoration, replicates=1)
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 25765.38; atol = 1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-2)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-2)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-2)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4.3808; atol=1e-2)
            @test isapprox(load_power(result, "1",["1","2","3"]), 9.8492; atol=1e-2)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"]), 4.398; atol=1e-2)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 9.87; atol=1e-1)

        end

        ## Juniper solver cannot find solution to AC unit commitment model

        # mn_data = build_mn_data(case5_restoration_strg, replicates=2)
        # @testset "5-bus case" begin
        #     result = PowerModelsRestoration.run_rop_uc(mn_data, PowerModels.ACPPowerModel, juniper_solver)

        #     @test result["termination_status"] == LOCALLY_SOLVED
        #     @test isapprox(result["objective"], 2329.500; atol = 1e-2)

        #     @test isapprox(result["solution"]["nw"]["1"]["gen"]["1"]["gen_status"], 0; atol = 1e-1)
        #     @test isapprox(result["solution"]["nw"]["1"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
        #     @test isapprox(result["solution"]["nw"]["2"]["gen"]["1"]["gen_status"], 1; atol = 1e-1)
        #     @test isapprox(result["solution"]["nw"]["2"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
        # end
    end


    @testset "test dc rop" begin
        mn_data = build_mn_data(case5_restoration, replicates=2)
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 1508.1; atol = 1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-6)
            # @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4.3999; atol=1e-2)
            @test isapprox(load_power(result, "1",["1","2","3"]), 8.2999; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10.0; atol=1e-2)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"]), 4.398; atol=1e-2)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 8.299; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 10; atol=1e-2)

        end


        mn_data = build_mn_data(case5_restoration_strg, replicates=2)
        @testset "5-bus strg case" begin
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 2805.6; atol = 1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 0; atol=1e-6)
            # Not stabled on linux, osx
            # @test isapprox(branch_status(result,"2","2"), 1; atol=1e-6)
            # @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(storage_status(result, "0", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "0", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "1", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-6)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4.3999; atol=1e-2)
            @test isapprox(load_power(result, "1",["1","2","3"]), 7.0; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10.0; atol=1e-2)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"])+storage_power(result, "0",["1","2"]), 4.398; atol=1e-2)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"])+storage_power(result, "1",["1","2"]), 7.0; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"])+storage_power(result, "2",["1","2"]), 10.0; atol=1e-2)

            # @test isapprox(storage_power(result, "0",["1","2"]), 0.0; atol=1e-2)
            # @test isapprox(storage_power(result, "1",["1","2"]), 0.0; atol=1e-2)
            # @test isapprox(storage_power(result, "2",["1","2"]), 0.25; atol=1e-2)

        end
    end


    @testset "test dc rop uc" begin
        mn_data = build_mn_data(case5_restoration, replicates=2)
        @testset "5-bus case" begin
            result = PowerModelsRestoration.run_rop_uc(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 1503.0; atol = 1e-2)

            @test isapprox(gen_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"0","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"0","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"0","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-6)
            # @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            # @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(load_power(result, "0",["1","2","3"]), 4; atol=1e-2)
            @test isapprox(load_power(result, "1",["1","2","3"]), 7; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 10; atol=1e-2)

            @test isapprox(gen_power(result, "0",["1","2","3","4","5"]), 4; atol=1e-2)
            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 7; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 10; atol=1e-2)

        end

        mn_data = build_mn_data(case5_restoration_strg, replicates=2)
        @testset "5-bus strg case" begin
            result = PowerModelsRestoration.run_rop_uc(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 2804.0; atol = 1e-2)

            @test isapprox(storage_status(result, "0", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "0", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "1", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-6)


            # non-stable solution in osx and linux
            # @test isapprox(gen_power(result, "0", ["1","2","3","4","5"]) + storage_power(result, "0",["1","2"]), 4.25; atol=1e-2)
            @test isapprox(gen_power(result, "1", ["1","2","3","4","5"]) + storage_power(result, "1",["1","2"]),  7.00; atol=1e-2)
            @test isapprox(gen_power(result, "2", ["1","2","3","4","5"]) + storage_power(result, "2",["1","2"]),  10.0; atol=1e-2)

        end
    end

    #numerical stabilty issues.  This can be fixed by changing variable_generation_indicator start value to 0.5
    # @testset "test soc rop" begin
    #     @testset "5-bus strg case" begin
    #         mn_data = build_mn_data(case5_restoration_strg, replicates=3)
    #         result = PowerModelsRestoration.run_rop(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)

    #         @test result["termination_status"] == LOCALLY_SOLVED
    #         @test isapprox(result["objective"], 6701.3818; atol = 1e-2)

    #         @test isapprox(storage_status(result, "1", "1"), 0.000000; atol=1e-6)
    #         @test isapprox(storage_status(result, "1", "2"), 1.000000; atol=1e-6)
    #         @test isapprox(storage_status(result, "2", "1"), 1.000000; atol=1e-6)
    #         @test isapprox(storage_status(result, "2", "2"), 1.000000; atol=1e-6)
    #     end
    # end

    @testset "test qc rop" begin
        # solution stabilty issues on OS X and Linux
        #=
        @testset "5-bus strg case" begin
            mn_data = build_mn_data(case5_restoration_strg, replicates=3)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.QCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 6701.3818; atol = 1e-2)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-4)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-4)
            @test isapprox(gen_status(result,"1","3"), 0; atol=1e-4)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","1"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","2"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","3"), 1; atol=1e-4)
            @test isapprox(gen_status(result,"3","4"), 1; atol=1e-4)

            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","4"), 0; atol=1e-6)

            @test isapprox(storage_status(result, "1", "1"), 0; atol=1e-4)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "2", "1"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "3", "1"), 1; atol=1e-4)
            @test isapprox(storage_status(result, "3", "2"), 1; atol=1e-4)

            @test isapprox(load_power(result, "1",["1","2","3"]), 4.3816; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 7.0; atol=1e-2)
            @test isapprox(load_power(result, "3",["1","2","3"]), 10.0; atol=1e-2)

            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 3.7721; atol=2e-1)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 5.8908; atol=2e-1)
            @test isapprox(gen_power(result, "3",["1","2","3","4","5"]), 8.3770; atol=2e-1)

            @test isapprox(storage_power(result, "1",["1","2"]), 0.6261; atol=2e-1)
            @test isapprox(storage_power(result, "2",["1","2"]), 0.8430; atol=2e-1)
            @test isapprox(storage_power(result, "3",["1","2"]), 1.0273; atol=2e-1)

        end
        =#
    end
end

