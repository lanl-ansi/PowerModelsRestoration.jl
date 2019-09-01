### Restoration Ordering Tests
@testset "ROP" begin

    @testset "test ac rop" begin
        @testset "5-bus case" begin
            mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=2)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 4294.38; atol = 1e-2)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)

            @test isapprox(load_power(result, "1",["1","2","3"]), 4.3808; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 9.9998; atol=1e-2)

            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 4.398; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 10.03; atol=1e-1)

        end

        @testset "5-bus storage case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=2)
            result = PowerModelsRestoration.run_rop_uc(mn_data, PowerModels.ACPPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 4327.0; atol = 1e-2)

            @test isapprox(result["solution"]["nw"]["1"]["gen"]["1"]["gen_status"], 0; atol = 1e-1)
            @test isapprox(result["solution"]["nw"]["1"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
            @test isapprox(result["solution"]["nw"]["2"]["gen"]["1"]["gen_status"], 1; atol = 1e-1)
            @test isapprox(result["solution"]["nw"]["2"]["gen"]["4"]["gen_status"], 1; atol = 1e-1)
        end
    end


    @testset "test dc rop" begin
        @testset "5-bus case" begin
            mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=3)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 504.0; atol = 1e-2)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"3","4"), 1; atol=1e-6)

            @test isapprox(load_power(result, "1",["1","2","3"]), 4.3999; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 9.6; atol=1e-2)
            @test isapprox(load_power(result, "3",["1","2","3"]), 10.0; atol=1e-2)

            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 4.398; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 9.6; atol=1e-2)
            @test isapprox(gen_power(result, "3",["1","2","3","4","5"]), 10; atol=1e-2)
        end

        @testset "5-bus strg case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 578.864; atol = 1e-2)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"3","4"), 1; atol=1e-6)

            @test isapprox(storage_status(result, "1", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "3", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "3", "2"), 1; atol=1e-6)

            @test isapprox(load_power(result, "1",["1","2","3"]), 2.24; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 7.0; atol=1e-2)
            @test isapprox(load_power(result, "3",["1","2","3"]), 9.624; atol=1e-2)

            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 2.0; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 7.2; atol=1e-2)
            @test isapprox(gen_power(result, "3",["1","2","3","4","5"]), 9.3; atol=1e-2)

            @test isapprox(storage_power(result, "1",["1","2"]), -0.240; atol=1e-2)
            @test isapprox(storage_power(result, "2",["1","2"]),  0.200; atol=1e-2)
            @test isapprox(storage_power(result, "3",["1","2"]), -0.324; atol=1e-2)
        end
    end


    @testset "test dc rop uc" begin
        @testset "5-bus case" begin
            mn_data = build_mn_data("../test/data/case5_restoration.m", replicates=3)
            result = PowerModelsRestoration.run_rop_uc(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 501.0; atol = 1e-2)

            @test isapprox(gen_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","3"), 0; atol=1e-6)
            @test isapprox(gen_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","1"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","3"), 1; atol=1e-6)
            @test isapprox(gen_status(result,"3","4"), 1; atol=1e-6)

            @test isapprox(branch_status(result,"1","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"1","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"2","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","2"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"2","4"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","1"), 0; atol=1e-6)
            @test isapprox(branch_status(result,"3","2"), 1; atol=1e-6)
            @test isapprox(branch_status(result,"3","4"), 1; atol=1e-6)

            @test isapprox(load_power(result, "1",["1","2","3"]), 4; atol=1e-2)
            @test isapprox(load_power(result, "2",["1","2","3"]), 7; atol=1e-2)
            @test isapprox(load_power(result, "3",["1","2","3"]), 10; atol=1e-2)

            @test isapprox(gen_power(result, "1",["1","2","3","4","5"]), 4; atol=1e-2)
            @test isapprox(gen_power(result, "2",["1","2","3","4","5"]), 7; atol=1e-2)
            @test isapprox(gen_power(result, "3",["1","2","3","4","5"]), 10; atol=1e-2)
        end

        @testset "5-bus strg case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
            result = PowerModelsRestoration.run_rop_uc(mn_data, PowerModels.DCPPowerModel, cbc_solver)

            @test result["termination_status"] == OPTIMAL
            @test isapprox(result["objective"], 577.0; atol = 1e-2)

            @test isapprox(storage_status(result, "1", "1"), 0; atol=1e-6)
            @test isapprox(storage_status(result, "1", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "2", "2"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "3", "1"), 1; atol=1e-6)
            @test isapprox(storage_status(result, "3", "2"), 1; atol=1e-6)


            # non-stable solution in osx and linux
            #@test isapprox(storage_power(result, "1",["1","2"]),  0.5000; atol=1e-2)
            @test isapprox(storage_power(result, "2",["1","2"]),  0.1388; atol=1e-2)
            # non-stable solution in osx and linux
            #@test isapprox(storage_power(result, "3",["1","2"]), -0.7000; atol=1e-2)
        end
    end

    #numerical stabilty issues.  This can be fixed by changing variable_generation_indicator start value to 0.5
    @testset "test soc rop" begin
        @testset "5-bus strg case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
            result = PowerModelsRestoration.run_rop(mn_data, PowerModels.SOCWRPowerModel, juniper_solver)

            @test result["termination_status"] == LOCALLY_SOLVED
            @test isapprox(result["objective"], 6538.22; atol = 1e-2)

            @test isapprox(storage_status(result, "1", "1"), 0.0000; atol=1e-4)
            @test isapprox(storage_status(result, "1", "2"), 1.0000; atol=1e-4)
            @test isapprox(storage_status(result, "2", "1"), 0.6699; atol=1e-4)
            @test isapprox(storage_status(result, "2", "2"), 1.0000; atol=1e-4)
        end
    end

    @testset "test qc rop" begin
        # solution stabilty issues on OS X and Linux
        #=
        @testset "5-bus strg case" begin
            mn_data = build_mn_data("../test/data/case5_restoration_strg.m", replicates=3)
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

