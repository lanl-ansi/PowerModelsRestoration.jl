### UTIL Restoration Tests
@testset "UTIL" begin

    @testset "test AC UTIL" begin
    end

    @testset "test SOCWR UTIL" begin
    end

    @testset "test dc UTIL" begin
        @testset "total damage scenario" begin
            # totally damaged 3_bus system
            # data = PowerModels.parse_file("../test/data/case3_restoration_total.m")

            # result = run_UTIL(data)
            #  @test result["termination_status"] == PowerModels.OPTIMAL
            #  @test isapprox(length(keys(result["solution"]["nw"])), 9; atol=1e-1)
        end

    end

end