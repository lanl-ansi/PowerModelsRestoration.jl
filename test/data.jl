## Test data processing functions
@testset "Data" begin

    @testset "damage_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        @test isapprox(network["gen"]["5"]["damaged"], 0, atol=1e-4)
        damage_items!(network, Dict("gen" => ["5"]))
        @test isapprox(network["gen"]["5"]["damaged"], 1, atol=1e-4)

        network_mn = replicate_restoration_network(network, count=2)
        @test isapprox(network_mn["nw"]["0"]["bus"]["10"]["damaged"], 0, atol=1e-4)
        damage_items!(network_mn, Dict("bus" =>["10"]))
        @test isapprox(network_mn["nw"]["0"]["bus"]["10"]["damaged"], 1, atol=1e-4)        
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

    @testset "count_damaged_items" begin

        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        count = count_damaged_items(network)
        
        @test isapprox(count,12, atol=1e-4)

        network_mn = replicate_restoration_network(network, count=2)
        count = count_damaged_items(network_mn)

        @test isapprox(count, 12, atol=1e-4)

    end

    @testset "get_damaged_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        comp_set = get_damaged_items(network)

        @test "1" in comp_set["gen"]
        @test "4" in comp_set["bus"]
        @test "6" in comp_set["branch"]
        @test ~( "2" in comp_set["storage"] )
    end

    @testset "get_isolated_load" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        set_component_inactive!(network, Dict("bus" =>["4"]))

        load_set = get_isolated_load(network)

        @test "3" in load_set["load"]
        @test ~("2" in load_set["load"])
    end

    @testset "count_repairable_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        @test isapprox(count_repairable_items(network), 12, atol=1e-6)
        set_component_inactive!(network, Dict("branch"=> ["1"]))
        @test isapprox(count_repairable_items(network), 11, atol=1e-6)
    end

    @testset "get_repairable_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        repairable_set = get_repairable_items(network)

        @test ("1" in repairable_set["gen"])
        @test ("1" in repairable_set["branch"])

        ## set status to 0, should not longer be repairable
        set_component_inactive!(network, Dict("branch" => ["1"]))
        repairable_set = get_repairable_items(network)
        @test ("1" in repairable_set["gen"])
        @test ~("1" in repairable_set["branch"])
        
    end

    @testset "count_active_items" begin
    network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

    @test isapprox(count_active_items(network), 22, atol=1e-2)

    set_component_inactive!(network, Dict("bus"=> ["1"]))
    set_component_inactive!(network, Dict("gen"=> ["2"]))
    set_component_inactive!(network, Dict("branch"=> ["3"]))
    set_component_inactive!(network, Dict("storage"=> ["1"]))

    @test isapprox(count_active_items(network), 18, atol=1e-2)
    end

    @testset "clear_damage_indicator!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)

        @test isapprox(count_damaged_items(network), 12, atol=1e-2)

        clear_damage_indicator!(network)
        @test isapprox(count_damaged_items(network), 0, atol=1e-2)
    end

end



