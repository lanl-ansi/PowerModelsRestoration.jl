## Test data processing functions
@testset "Data" begin

    @testset "damage_components!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        @test isapprox(network["gen"]["5"]["damaged"], 0, atol=1e-4)
        damage_components!(network, Dict("gen" => Set(["5"])))
        @test isapprox(network["gen"]["5"]["damaged"], 1, atol=1e-4)
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

    @testset "count_damaged_components" begin

        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        count = count_damaged_components(network)

        @test isapprox(count,12, atol=1e-4)
    end

    @testset "get_damaged_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        comp_set = get_damaged_components(network)

        @test in("1", comp_set["gen"])
        @test in("4", comp_set["bus"])
        @test in("6", comp_set["branch"])
        @test !in("2", comp_set["storage"])
    end

    @testset "get_isolated_load" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        make_inactive!(network, Dict("bus" =>Set(["4"])))

        load_set = get_isolated_load(network)

        @test in("3", load_set)
        @test !in("2", load_set)

    end

    @testset "count_repairable_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        @test isapprox(count_repairable_components(network), 12, atol=1e-6)
        make_inactive!(network, Dict("branch"=> Set(["1"])))
        @test isapprox(count_repairable_components(network), 11, atol=1e-6)
    end

    @testset "get_repairable_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)
        repairable_set = get_repairable_components(network)

        @test ("1" in repairable_set["gen"])
        @test ("1" in repairable_set["branch"])

        ## set status to 0, should not longer be repairable
        make_inactive!(network, Dict("branch" => Set(["1"])))
        repairable_set = get_repairable_components(network)
        @test ("1" in repairable_set["gen"])
        @test !("1" in repairable_set["branch"])
    end

    @testset "count_active_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        @test isapprox(count_active_components(network), 19, atol=1e-2)

        make_inactive!(network, Dict("bus"=> Set(["1"])))
        make_inactive!(network, Dict("gen"=> Set(["2"])))
        make_inactive!(network, Dict("branch"=> Set(["3"])))
        make_inactive!(network, Dict("storage"=> Set(["1"])))

        @test isapprox(count_active_components(network), 15, atol=1e-2)

    end

    @testset "clear_damage_indicator!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        propagate_damage_status!(network)

        @test isapprox(count_damaged_components(network), 12, atol=1e-2)

        clear_damage_indicator!(network)
        @test isapprox(count_damaged_components(network), 0, atol=1e-2)


        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        network_mn = replicate_restoration_network(network,count=2)
        propagate_damage_status!(network)

        @test isapprox(count_damaged_components(network_mn["nw"]["0"]), 12, atol=1e-2)
        @test isapprox(count_damaged_components(network_mn["nw"]["1"]), 12, atol=1e-2)
        @test isapprox(count_damaged_components(network_mn["nw"]["2"]), 12, atol=1e-2)

        clear_damage_indicator!(network_mn)

        @test isapprox(count_damaged_components(network_mn["nw"]["0"]), 0, atol=1e-2)
        @test isapprox(count_damaged_components(network_mn["nw"]["1"]), 0, atol=1e-2)
        @test isapprox(count_damaged_components(network_mn["nw"]["2"]), 0, atol=1e-2)
    end

    @testset "make_inactive!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        @test isapprox(count_repairable_components(network), 7, atol=1e-2)
        make_inactive!(network, Dict("branch"=> Set(["1"])))
        @test isapprox(count_repairable_components(network), 6, atol=1e-2)
    end

    @testset "get_inactive_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        comp_set = get_inactive_components(network)
        @test !in("2", comp_set["gen"])
        @test !in("1", comp_set["bus"])
        @test !in("3",  comp_set["branch"])
        @test !in("2", comp_set["storage"])

        make_inactive!(network, Dict("bus"=> Set(["1"])))
        make_inactive!(network, Dict("gen"=> Set(["2"])))
        make_inactive!(network, Dict("branch"=> Set(["3"])))
        make_inactive!(network, Dict("storage"=> Set(["1"])))
        comp_set = get_inactive_components(network)

        @test in("2", comp_set["gen"])
        @test in("1", comp_set["bus"])
        @test in("3", comp_set["branch"])
        @test !in( "2",comp_set["storage"])
    end

    @testset "count_inactive_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        @test isapprox(count_inactive_components(network), 0, atol=1e-2)

        make_inactive!(network, Dict("bus"=> Set(["1"])))
        make_inactive!(network, Dict("gen"=> Set(["2"])))
        make_inactive!(network, Dict("branch"=> Set(["3"])))
        make_inactive!(network, Dict("storage"=> Set(["1"])))

        @test isapprox(count_inactive_components(network), 4, atol=1e-2)
    end

    @testset "get_active_components" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        active_set = get_active_components(network)

        @test [i in active_set["gen"] for i in ["1","2","3","4","5"]] == ones(5)
        @test [i in active_set["bus"] for i in ["1","2","3","4","10"]] == ones(5)
        @test [i in active_set["branch"] for i in ["1","2","3","4","5","6","7"]] == ones(7)
        @test [i in active_set["storage"] for i in ["1","2"]] == ones(2)

        ## set status to 0, should not longer be active
        make_inactive!(network, Dict("branch" => Set(["1"])))
        make_inactive!(network, Dict("gen" => Set(["1"])))
        make_inactive!(network, Dict("bus" => Set(["1"])))
        make_inactive!(network, Dict("storage" => Set(["1"])))

        active_set = get_active_components(network)
        @test !("1" in active_set["gen"]) #components no longer active
        @test !("1" in active_set["bus"])
        @test !("1" in active_set["branch"])
        @test !("1" in active_set["storage"])

        @test [i in active_set["gen"] for i in ["2","3","4","5"]] == ones(4) #components still active
        @test [i in active_set["bus"] for i in ["2","3","4","10"]] == ones(4)
        @test [i in active_set["branch"] for i in ["2","3","4","5","6","7"]] == ones(6)
        @test [i in active_set["storage"] for i in ["2"]] == ones(1)

    end

    @testset "clean_status!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        mn_network = replicate_restoration_network(network, count=2)

        network["gen"]["1"]["gen_status"] = 0.9999
        network["bus"]["1"]["status"] = 0.9999
        network["load"]["1"]["status"] = 0.0001
        network["branch"]["1"]["br_status"] = 0.0001

        mn_network["nw"]["1"]["gen"]["1"]["gen_status"] = 0.9999
        mn_network["nw"]["1"]["bus"]["1"]["status"] = 0.9999
        mn_network["nw"]["1"]["load"]["1"]["status"] = 0.0001
        mn_network["nw"]["1"]["branch"]["1"]["br_status"] = 0.0001

        clean_status!(network)
        @test network["bus"]["1"]["bus_type"] == 2
        @test network["gen"]["1"]["gen_status"] == 1
        @test network["load"]["1"]["status"] == 0
        @test network["branch"]["1"]["br_status"] == 0

        clean_status!(mn_network)
        @test mn_network["nw"]["1"]["bus"]["1"]["bus_type"] == 2
        @test mn_network["nw"]["1"]["gen"]["1"]["gen_status"] == 1
        @test mn_network["nw"]["1"]["load"]["1"]["status"] == 0
        @test mn_network["nw"]["1"]["branch"]["1"]["br_status"] == 0
    end


    @testset "update_status!" begin
        network1 = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        network2 = PowerModels.parse_file("../test/data/case5_restoration_strg.m")

        network2["gen"]["1"]["gen_status"] = 1
        network2["bus"]["1"]["bus_type"] = 4
        network2["load"]["1"]["status"] = 0
        network2["branch"]["1"]["br_status"] = 0
        delete!(network1["branch"],"2")
        delete!(network2["branch"],"3")

        mn_network1 = replicate_restoration_network(network1, count=2)
        mn_network2 = replicate_restoration_network(network2, count=2)


        update_status!(network1, network2)
        @test network1["bus"]["1"]["bus_type"] == 4
        @test network1["gen"]["1"]["gen_status"] == 1
        @test network1["load"]["1"]["status"] == 0
        @test network1["branch"]["1"]["br_status"] == 0
        @test network1["branch"]["3"]["br_status"] == 1
        @test !haskey(network1["branch"],"2")


        update_status!(mn_network1, mn_network2)
        @test mn_network1["nw"]["1"]["bus"]["1"]["bus_type"] == 4
        @test mn_network1["nw"]["2"]["gen"]["1"]["gen_status"] == 1
        @test mn_network1["nw"]["1"]["load"]["1"]["status"] == 0
        @test mn_network1["nw"]["2"]["branch"]["1"]["br_status"] == 0
        @test mn_network1["nw"]["1"]["branch"]["3"]["br_status"] == 1
        @test !haskey(mn_network1["nw"]["1"]["branch"],"2")

        @test_throws ErrorException("Network_1 and Network_2 must both be single networks or both be multinetworks") update_status!(mn_network1, network2)
        @test_throws ErrorException("Network_1 and Network_2 must both be single networks or both be multinetworks") update_status!(network1, mn_network2)

    end

    @testset "replicate_restoration_network!" begin
        network = PowerModels.parse_file("../test/data/case5_restoration_strg.m")
        mn_network = replicate_restoration_network(network, count=2)

        repair_count = 12
        @test length(keys(mn_network["nw"]))==3 # 0 period + 2 restoration periods = 3 periods
        @test mn_network["nw"]["0"]["time_elapsed"] == repair_count/2
        @test mn_network["nw"]["1"]["time_elapsed"] == repair_count/2
        @test mn_network["nw"]["2"]["time_elapsed"] == 1

        @test mn_network["nw"]["0"]["repairs"] == 0
        @test mn_network["nw"]["1"]["repairs"] == repair_count/2
        @test mn_network["nw"]["2"]["repairs"] == repair_count/2

        @test mn_network["nw"]["0"]["repaired_total"] == 0
        @test mn_network["nw"]["1"]["repaired_total"] == repair_count/2
        @test mn_network["nw"]["2"]["repaired_total"] == repair_count


        mn_network = replicate_restoration_network(network, repair_count)
        @test length(keys(mn_network["nw"]))==1+repair_count # 0 period + 12 restoration periods = 3 periods

        @test mn_network["nw"]["0"]["time_elapsed"] == 1
        @test mn_network["nw"]["6"]["time_elapsed"] == 1
        @test mn_network["nw"]["12"]["time_elapsed"] == 1

        @test mn_network["nw"]["0"]["repairs"] == 0
        @test mn_network["nw"]["6"]["repairs"] == 1
        @test mn_network["nw"]["12"]["repairs"] == 1

        @test mn_network["nw"]["0"]["repaired_total"] == 0
        @test mn_network["nw"]["6"]["repaired_total"] == repair_count/2
        @test mn_network["nw"]["12"]["repaired_total"] == repair_count

    end
end



