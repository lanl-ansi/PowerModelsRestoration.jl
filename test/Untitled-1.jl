1=> Tuple{String, String}[]
2=> Tuple{String, String}[]
3=> Tuple{String, String}[]
4=> [("bus", "2"), ("gen", "2")]
5=> Tuple{String, String}[]
6=> [("bus", "1"), ("gen", "1")]
7=> [("bus", "3")]
8=> [("gen", "3"), ("branch", "1"), ("branch", "2")]
9=> [("branch", "3")]

1: 0.0
2: 0.0
3: 0.0
4: 1.1
5: 1.1
6: 2.2
7: 2.2
8: 3.1500000000000004
9: 3.1500000000000004

old_active = Dict{String, Set{String}}("gen" => Set(), "branch" => Set(), "storage" => Set(), "bus" => Set())
for i in 1:9
    new_active = get_active_components(data_mn["nw"]["$i"])
    for (comp_type, comp_ids) in new_active
        for comp_id in comp_ids
            if comp_id in old_active[comp_type]
            else
                println("$i => ($comp_type, $comp_id")
            end
        end
    end
    old_active = new_active
end

for i in 1:9
    println("$i=> $(result["repair_ordering"]["$i"])")
end

for  i in 1:9
    print("$i: "); println(sum(load["pd"] for (id,load) in result["solution"]["nw"]["$i"]["load"]))
end