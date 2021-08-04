Pkg.activate(temp=true)
Pkg.add("PowerModels")
Pkg.add("JuMP")
Pkg.add("Gurobi")
Pkg.develop("PowerModelsRestoration")
Pkg.add("DataStructures")

using PowerModelsRestoration
using DataStructures
using PowerModels
using Gurobi
using JuMP

optimizer = optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag"=>0)
model_constructor = DCPPowerModel

@show solution |> keys


pms_path = joinpath(dirname(pathof(PowerModels)), "..")
data = PowerModels.parse_file("$(pms_path)/test/data/matpower/case5.m")
damage_items!(data, Dict("bus"=>[id for (id, bus) in data["bus"]]))
propagate_damage_status!(data)

# solution = run_iterative_restoration(data, DCPPowerModel, optimizer, time_limit=10.0)

solution = rad_heuristic(data, model_constructor, optimizer)
display(stats["repair_list"])

SortedDict(parse(Int,k)=>v for (k,v) in restoration_order)


data_mn = replicate_restoration_network(data, count=maximum(parse.(Int,collect(keys(restoration_order)))))
apply_restoration_sequence!(data_mn, restoration_order)
print_summary_restoration(solution["solution"])


##
# Random partition sizing
repair_ordering = utilization_heuristic_restoration(data)
repair_ordering = final_period_restoration(data)

network_count=length(keys(repair_ordering))
partition_min = 3
partition_max = 5

partitions = Int[]
partition_count = 0
while partition_count < network_count
    partition_range = min((network_count-partition_count),partition_min):min((network_count-partition_count),partition_max)
    push!(partitions,rand(partition_range))
    partition_count = sum(partitions)
end
partitions
sum(partitions)

nwids = sort([parse(Int,k) for k in keys(repair_ordering)], rev=true)

partition_repairs = Dict{Int,Any}()
partition_networks = Dict{Int,Any}()
for  i in eachindex(partitions)
    partition_size = partitions[i]
    partition_networks[i] = [pop!(nwids) for j in 1:partition_size]

    partition_repairs[i] = Dict(k=>String[] for k in restoration_comps)
    for nw_id in partition_networks[i]
        for (comp_type,comp_data) in partition_repairs[i]
            append!(comp_data, repair_ordering["$nw_id"][comp_type])
        end
    end
end
partition_repairs
partition_networks

##

data_mn = replicate_restoration_network(data, count=maximum(parse.(Int,collect(keys(restoration_order)))))
apply_restoration_sequence!(data_mn, restoration_order)
print_summary_restoration(data_mn)


solution = run_iterative_restoration(data, model_constructor, optimizer)

repair_ordering = utilization_heuristic_restoration(data)
partition_count = 3
items_per_partition = length(repair_ordering)/partition_count

partition_repairs = Dict{Int,Any}()
partition_networks = Dict{Int,Any}()
for r_id in 1:partition_count
    nw_ids = round(Int,(r_id-1)*items_per_partition)+1:round(Int,(r_id)*items_per_partition)
    r_dict = Dict(k=>String[] for (k,v) in repair_ordering["1"])
    for nw_id in nw_ids
        for (comp_type,comp_data) in r_dict
            append!(comp_data, repair_ordering["$nw_id"][comp_type])
        end
    end
    partition_repairs[r_id]=r_dict
    partition_networks[r_id]=collect(nw_ids)
end
# @show partition_repairs

## Solve subperiod ROP problems
new_repair_ordering = deepcopy(repair_ordering)
for (nwid, nw) in new_repair_ordering
    for (comp_type,comp_ids) in nw
        empty!(comp_ids)
    end
end
new_repair_ordering
# data_mn = replicate_restoration_network(data, count=partition_count)
# apply_restoration_sequence!(data_mn,partition_repairs)


## Solve a subperiod ROP problem
new_repair_ordering = Dict{String,Any}()
for (r_id, repairs) in partition_repairs
    r_data = deepcopy(data)

    # apply repair orders approraityle
    for (r_id_it, repairs_it) in partition_repairs
        if r_id_it < r_id #repaired before r_id, then status =1 damage = 0
            for (comp_type, comp_ids) in repairs_it
                for comp_id in comp_ids
                    r_data[comp_type][comp_id]["damaged"] = 0
                end
            end
        elseif r_id_it > r_id # repaired after r_id status = 0
            for (comp_type, comp_ids) in repairs_it
                comp_status_key = PowerModels.pm_component_status[comp_type]
                comp_status_inactive = PowerModels.pm_component_status_inactive[comp_type]
                for comp_id in comp_ids
                    r_data[comp_type][comp_id][comp_status_key] = comp_status_inactive
                end
            end
        else
             # repairs to be order in this stage
        end
    end

    # solve ROP
    repair_periods=count_repairable_items(r_data)
    mn_network = replicate_restoration_network(r_data, repair_periods, PowerModels._pm_global_keys)
    solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer; )
    clean_status!(solution["solution"])

    # insert reordered reapirs into  reapirs
    r_repairs =  get_repairs(solution)
    for (rr_id, repairs) in r_repairs
        if rr_id != "0"
            nw_id = round(Int,(r_id-1)*items_per_partition)+parse(Int,rr_id)

            @show r_id
            @show rr_id
            @show nw_id

            new_repair_ordering["$nw_id"] = Dict(comp_type=>String[] for comp_type in restoration_comps)
            for (comp_type,comp_id) in repairs
                push!(new_repair_ordering["$nw_id"][comp_type],comp_id)
            end
        end
    end


    # println(r_id)
    # get_repairable_items(r_data) |> println
    # get_repairs(solution) |> println
end
@show new_repair_ordering
