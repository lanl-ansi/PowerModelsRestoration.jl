## Test data processing functions
@testset "Data" begin

    @testset "damage items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        @test isapprox(network["gen"]["5"]["damaged"], 0, atol=1e-4)
        damage_items!(network, Dict("gen" => "5"))
        @test isapprox(network["gen"]["5"]["damaged"], 1, atol=1e-4)

        network_mn = replicate_restoration_network(network, count=2)
        @test isapprox(network_mn["nw"]["1"]["bus"]["10"]["damaged"], 0, atol=1e-4)
        damage_items!(network_mn, Dict("bus" => "10"))
        @test isapprox(network_mn["nw"]["1"]["bus"]["10"]["damaged"], 1, atol=1e-4)
    end


    @testset "propagate_damage_status" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        @test isapprox(network["gen"]["4"]["damaged"], 0, atol=1e-4)
        @test isapprox(network["branch"]["7"]["damaged"], 0, atol=1e-4)

        propagate_damage_status!(network)

        @test isapprox(network["gen"]["4"]["damaged"], 1, atol=1e-4)
        @test isapprox(network["branch"]["7"]["damaged"], 1, atol=1e-4)
        
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        network_mn = replicate_restoration_network(network, count=2)
        # replicate_restoration_network contains the propagate_damage_status! function.  
        # this is to verify that propagate_damage_status! can still be applied to a multinetwork.
        propagate_damage_status!(network_mn)

        @test isapprox(network_mn["nw"]["1"]["gen"]["4"]["damaged"], 1, atol=1e-4)
        @test isapprox(network_mn["nw"]["2"]["branch"]["7"]["damaged"], 1, atol=1e-4)

    end

    @testset "counting damaged items" begin

        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        count = count_damaged_items(network)
        
        @test isapprox(count,12, atol=1e-4)

        network_mn = replicate_restoration_network(network, count=2)
        count = count_damaged_items(network_mn)

        @test isapprox(count, 12, atol=1e-4)

    end
end



