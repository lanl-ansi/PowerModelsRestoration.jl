## Test data processing functions
@testset "Data" begin

    @testset "clean_solution" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        mn_network = replicate_restoration_network(network, count=2)
        solution = Dict("solution"=>network)
        mn_solution = Dict("solution"=>mn_network)

        for comp_type in ["bus","gen","load","branch"]
            network[comp_type]["1"]["status"] = NaN
        end
        for (nwid, net) in mn_network["nw"]
            for comp_type in ["bus","gen","load","branch"]
                net[comp_type]["1"]["status"] = NaN
            end
        end

        
        clean_solution!(solution)
        @test !isnan(solution["solution"]["bus"]["1"]["status"])
        @test !isnan(solution["solution"]["gen"]["1"]["status"])
        @test !isnan(solution["solution"]["load"]["1"]["status"])
        @test !isnan(solution["solution"]["branch"]["1"]["status"])

        clean_solution!(mn_solution)
        @test !isnan(mn_solution["solution"]["nw"]["1"]["bus"]["1"]["status"])
        @test !isnan(mn_solution["solution"]["nw"]["1"]["gen"]["1"]["status"])
        @test !isnan(mn_solution["solution"]["nw"]["2"]["load"]["1"]["status"])
        @test !isnan(mn_solution["solution"]["nw"]["2"]["branch"]["1"]["status"])
    end

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
        @test isapprox(network["storage"]["1"]["damaged"], 0, atol=1e-4)

        propagate_damage_status!(network)

        @test isapprox(network["gen"]["4"]["damaged"], 1, atol=1e-4)
        @test isapprox(network["branch"]["7"]["damaged"], 1, atol=1e-4)
        @test isapprox(network["storage"]["1"]["damaged"], 1, atol=1e-4)

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

        @test isapprox(count["nw"]["0"], 12, atol=1e-4)
        @test isapprox(count["nw"]["1"], 12, atol=1e-4)
        @test isapprox(count["nw"]["2"], 12, atol=1e-4)
    end

    @testset "get_damaged_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        comp_set = get_damaged_items(network)

        @test "1" in comp_set["gen"]
        @test "4" in comp_set["bus"]
        @test "6" in comp_set["branch"]
        @test !( "2" in comp_set["storage"] )

        network_mn = replicate_restoration_network(network, count=2)
        comp_set = get_damaged_items(network_mn)

        @test "1" in comp_set["nw"]["0"]["gen"]
        @test "4" in comp_set["nw"]["0"]["bus"]
        @test "6" in comp_set["nw"]["0"]["branch"]
        @test !( "2" in comp_set["nw"]["0"]["storage"] )

    end

    @testset "get_isolated_load" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        set_component_inactive!(network, Dict("bus" =>["4"]))

        load_set = get_isolated_load(network)

        @test "3" in load_set["load"]
        @test !("2" in load_set["load"])

        network_mn = replicate_restoration_network(network, count=2)
        set_component_inactive!(network_mn, Dict("bus" =>["1","2","3","4","10"]))

        load_set = get_isolated_load(network_mn)

        @test ("3" in load_set["nw"]["1"]["load"])
        @test ("2" in load_set["nw"]["2"]["load"])

    end

    @testset "count_repairable_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        @test isapprox(count_repairable_items(network), 12, atol=1e-6)
        set_component_inactive!(network, Dict("branch"=> ["1"]))
        @test isapprox(count_repairable_items(network), 11, atol=1e-6)

        network_mn = replicate_restoration_network(network, count=2)
        repariable = count_repairable_items(network_mn)
        @test isapprox(repariable["nw"]["0"], 11, atol=1e-6)
        @test isapprox(repariable["nw"]["1"], 11, atol=1e-6)
        @test isapprox(repariable["nw"]["2"], 11, atol=1e-6)



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
        @test !("1" in repairable_set["branch"])

        #should have same result in multinetwork
        mn_network = replicate_restoration_network(network,count=3)
        repairable_set = get_repairable_items(mn_network)

        @test ("1" in repairable_set["nw"]["2"]["gen"])
        @test !("1" in repairable_set["nw"]["2"]["branch"])
    end

    @testset "count_active_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        @test isapprox(count_active_items(network), 22, atol=1e-2)

        set_component_inactive!(network, Dict("bus"=> ["1"]))
        set_component_inactive!(network, Dict("gen"=> ["2"]))
        set_component_inactive!(network, Dict("branch"=> ["3"]))
        set_component_inactive!(network, Dict("storage"=> ["1"]))

        @test isapprox(count_active_items(network), 18, atol=1e-2)


        network_mn = replicate_restoration_network(network,count=2)

        @test isapprox(count_active_items(network_mn["nw"]["0"]), 18, atol=1e-2)
        @test isapprox(count_active_items(network_mn["nw"]["1"]), 18, atol=1e-2)
        @test isapprox(count_active_items(network_mn["nw"]["2"]), 18, atol=1e-2)
    end

    @testset "get_active_items" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        active_set = get_active_items(network)

        @test [i in active_set["gen"] for i in ["1","2","3","4","5"]] == ones(5)
        @test [i in active_set["bus"] for i in ["1","2","3","4","10"]] == ones(5)
        @test [i in active_set["branch"] for i in ["1","2","3","4","5","6","7"]] == ones(7)
        @test [i in active_set["storage"] for i in ["1","2"]] == ones(2)

        ## set status to 0, should not longer be active
        set_component_inactive!(network, Dict("branch" => ["1"]))
        set_component_inactive!(network, Dict("gen" => ["1"]))
        set_component_inactive!(network, Dict("bus" => ["1"]))
        set_component_inactive!(network, Dict("storage" => ["1"]))

        active_set = get_active_items(network)
        @test !("1" in active_set["gen"]) #items no longer active
        @test !("1" in active_set["bus"])
        @test !("1" in active_set["branch"])
        @test !("1" in active_set["storage"])

        @test [i in active_set["gen"] for i in ["2","3","4","5"]] == ones(4) #items still active
        @test [i in active_set["bus"] for i in ["2","3","4","10"]] == ones(4)
        @test [i in active_set["branch"] for i in ["2","3","4","5","6","7"]] == ones(6)
        @test [i in active_set["storage"] for i in ["2"]] == ones(1)

        #should have same result in multinetwork
        network_mn = replicate_restoration_network(network,count=2)
        active_set_0 = get_active_items(network_mn["nw"]["0"])
        @test !("1" in active_set_0["gen"]) #items no longer active
        @test !("1" in active_set_0["bus"])
        @test !("1" in active_set_0["branch"])
        @test !("1" in active_set_0["storage"])

        @test [i in active_set_0["gen"] for i in ["2","3","4","5"]] == ones(4) #items still active
        @test [i in active_set_0["bus"] for i in ["2","3","4","10"]] == ones(4)
        @test [i in active_set_0["branch"] for i in ["2","3","4","5","6","7"]] == ones(6)
        @test [i in active_set_0["storage"] for i in ["2"]] == ones(1)
    end

    @testset "clear_damage_indicator!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)

        @test isapprox(count_damaged_items(network), 12, atol=1e-2)

        clear_damage_indicator!(network)
        @test isapprox(count_damaged_items(network), 0, atol=1e-2)

        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        network_mn = replicate_restoration_network(network,count=2)

        count = count_damaged_items(network_mn)
        @test isapprox(count["nw"]["0"], 12, atol=1e-2)
        @test isapprox(count["nw"]["1"], 12, atol=1e-2)
        @test isapprox(count["nw"]["2"], 12, atol=1e-2)

        clear_damage_indicator!(network_mn)

        count = count_damaged_items(network_mn)
        @test isapprox(count["nw"]["0"], 0, atol=1e-2)
        @test isapprox(count["nw"]["1"], 0, atol=1e-2)
        @test isapprox(count["nw"]["2"], 0, atol=1e-2)

    end

    @testset "set_component_inactive!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)

        @test isapprox(count_repairable_items(network), 12, atol=1e-2)
        set_component_inactive!(network, Dict("branch"=> ["1"]))
        @test isapprox(count_repairable_items(network), 11, atol=1e-2)

        network_mn = replicate_restoration_network(network,count=2)
        repariable = count_repairable_items(network_mn)

        @test isapprox(repariable["nw"]["0"], 11, atol=1e-2)
        @test isapprox(repariable["nw"]["1"], 11, atol=1e-2)
        @test isapprox(repariable["nw"]["2"], 11, atol=1e-2)

        set_component_inactive!(network_mn, Dict("branch"=> ["2"]))
        repariable = count_repairable_items(network_mn)

        @test isapprox(repariable["nw"]["0"], 10, atol=1e-2)
        @test isapprox(repariable["nw"]["1"], 10, atol=1e-2)
        @test isapprox(repariable["nw"]["2"], 10, atol=1e-2)
    end
end



