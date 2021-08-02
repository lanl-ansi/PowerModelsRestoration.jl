Pkg.activate(temp=true)
Pkg.add("PowerModels")
Pkg.add("JuMP")
Pkg.add("Gurobi")
Pkg.develop("PowerModelsRestoration")

using PowerModelsRestoration
using PowerModels
using Gurobi
using JuMP

optimizer = optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag"=>0)
model_constructor = DCPPowerModel



pms_path = joinpath(dirname(pathof(PowerModels)), "..")
data = PowerModels.parse_file("$(pms_path)/test/data/matpower/case5.m")
damage_items!(data, Dict("bus"=>[id for (id, bus) in data["bus"]]))
propagate_damage_status!(data)

# run_iterative_restoration(data, SOCWRPowerModel, optimizer, time_limit=1.0)

restoration_order,stats = rad_heuristic(data, model_constructor, optimizer)
display(stats["repair_list"])


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
# @show parition_repairs

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
