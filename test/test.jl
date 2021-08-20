Pkg.activate(".")
# Pkg.develop("PowerModels")
# Pkg.add("JuMP")
# Pkg.add("Gurobi")
# Pkg.develop("PowerModelsRestoration")
# Pkg.add("DataStructures")
# Pkg.add("Setfield")
# Pkg.add("VegaLite")

using PowerModelsRestoration
using DataStructures
using PowerModels
using Gurobi
using JuMP
# using Combinatorics
# using ProgressMeter

optimizer = optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag"=>0, "MIPGap"=>0.001)
model_constructor = DCPPowerModel

##

# pms_path = joinpath(dirname(pathof(PowerModels)), "..")
pglib_path = "$(homedir())/Documents/PowerDev/pglib-opf"
data = PowerModels.parse_file("$(pglib_path)/pglib_opf_case14_ieee.m")
damage_items!(data, Dict("branch"=>[id for (id, branch) in data["branch"]]))
# damage_items!(data, Dict("branch"=>["$id" for id in 1:50]))
propagate_damage_status!(data)

# solution = run_iterative_restoration(data, DCPPowerModel, optimizer, time_limit=10.0)

# data = PowerModels.parse_file("../../../Documents\\PowerDev\\RestorationCLI\\data\\experiment_data\\case240api_50.m")
# data = PowerModels.parse_file("../../../Documents\\PowerDev\\RestorationCLI\\data\\simple_data.m")
# solution = rad_restoration(data, model_constructor, optimizer; time_limit = 1000.0)
solution = run_iterative_restoration(data, model_constructor, optimizer; time_limit=120.0)
# display(solution["stats"]["solve_time"])
# sum(sum(load["pd"] for (id,load) in net["load"]) for (nwid,net) in solution["solution"]["nw"])


# display(solution["stats"]["repair_list"])

# # SortedDict(parse(Int,k)=>v for (k,v) in restoration_order)
# data_mn = PowerModelsRestoration._new_replicate_restoration_network(data, 2, PowerModels._pm_global_keys)

# data_mn = replicate_restoration_network(data, count=count_damaged_items(data))
# sol = PowerModelsRestoration.run_rop(data_mn, DCPPowerModel, Gurobi.Optimizer)
# print_summary_restoration(solution["solution"])

using VegaLite
atl = solution["stats"]["average_termination_time_limit"]
afi = solution["stats"]["average_fail_to_improve"]
ens = solution["stats"]["ENS"]
stl = solution["stats"]["solver_time_limit"]
mps = solution["stats"]["partition_max"]

p1 = @vlplot(:line, x=1:length(atl), y=atl, title="Termination: Time Limit")    #|> save("termination_time_limit.pdf")
p2 = @vlplot(:line, x=1:length(afi), y=afi, title="Fail to Improve")            #|> save("fail_to_improve.pdf")
p3 = @vlplot(:line, x=1:length(ens), y=ens, title="ENS")                        #|> save("ENS.pdf")
p3 = @vlplot(:line, x=1:length(stl), y=stl, title="Solver Time Limit")          #|> save("solver_time_limit.pdf")
p3 = @vlplot(:line, x=1:length(mps), y=mps, title="Maximum Partition Size")     #|> save("maximum_partition_size.pdf")


# data_mn = replicate_restoration_network(data, count=maximum(parse.(Int,collect(keys(solution["repair_ordering"])))))
# apply_restoration_sequence!(data_mn, solution["repair_ordering"])
print_summary_restoration(solution["solution"])

##
pglib_path = ""
data = parse_file(string(pglib_path,"/pglib_opf_case240_ieee__api.m"))
damage_items!(data, Dict("branch"=>[id for (id, branch) in data["branch"]]))
# damage_items!(data, Dict("bus"=>["1","2","3"]))
propagate_damage_status!(data)

solution = rad_heuristic(data, model_constructor, optimizer)
display(solution["stats"]["repair_list"])
print_summary_restoration(solution["solution"])

solution["stats"]["ENS"]


# ##
# # Random partition sizing
# repair_ordering = utilization_heuristic_restoration(data)
# repair_ordering = final_period_restoration(data)

# network_count=length(keys(repair_ordering))
# partition_min = 3
# partition_max = 5

# partitions = Int[]
# partition_count = 0
# while partition_count < network_count
#     partition_range = min((network_count-partition_count),partition_min):min((network_count-partition_count),partition_max)
#     push!(partitions,rand(partition_range))
#     partition_count = sum(partitions)
# end
# partitions
# sum(partitions)

# nwids = sort([parse(Int,k) for k in keys(repair_ordering)], rev=true)

# partition_repairs = Dict{Int,Any}()
# partition_networks = Dict{Int,Any}()
# for  i in eachindex(partitions)
#     partition_size = partitions[i]
#     partition_networks[i] = [pop!(nwids) for j in 1:partition_size]

#     partition_repairs[i] = Dict(k=>String[] for k in restoration_comps)
#     for nw_id in partition_networks[i]
#         for (comp_type,comp_data) in partition_repairs[i]
#             append!(comp_data, repair_ordering["$nw_id"][comp_type])
#         end
#     end
# end
# partition_repairs
# partition_networks

# ##

# data_mn = replicate_restoration_network(data, count=maximum(parse.(Int,collect(keys(restoration_order)))))
# apply_restoration_sequence!(data_mn, restoration_order)
# print_summary_restoration(data_mn)


# solution = run_iterative_restoration(data, model_constructor, optimizer)

# repair_ordering = utilization_heuristic_restoration(data)
# partition_count = 3
# items_per_partition = length(repair_ordering)/partition_count

# partition_repairs = Dict{Int,Any}()
# partition_networks = Dict{Int,Any}()
# for r_id in 1:partition_count
#     nw_ids = round(Int,(r_id-1)*items_per_partition)+1:round(Int,(r_id)*items_per_partition)
#     r_dict = Dict(k=>String[] for (k,v) in repair_ordering["1"])
#     for nw_id in nw_ids
#         for (comp_type,comp_data) in r_dict
#             append!(comp_data, repair_ordering["$nw_id"][comp_type])
#         end
#     end
#     partition_repairs[r_id]=r_dict
#     partition_networks[r_id]=collect(nw_ids)
# end
# # @show partition_repairs

# ## Solve subperiod ROP problems
# new_repair_ordering = deepcopy(repair_ordering)
# for (nwid, nw) in new_repair_ordering
#     for (comp_type,comp_ids) in nw
#         empty!(comp_ids)
#     end
# end
# new_repair_ordering
# # data_mn = replicate_restoration_network(data, count=partition_count)
# # apply_restoration_sequence!(data_mn,partition_repairs)


# ## Solve a subperiod ROP problem
# new_repair_ordering = Dict{String,Any}()
# for (r_id, repairs) in partition_repairs
#     r_data = deepcopy(data)

#     # apply repair orders approraityle
#     for (r_id_it, repairs_it) in partition_repairs
#         if r_id_it < r_id #repaired before r_id, then status =1 damage = 0
#             for (comp_type, comp_ids) in repairs_it
#                 for comp_id in comp_ids
#                     r_data[comp_type][comp_id]["damaged"] = 0
#                 end
#             end
#         elseif r_id_it > r_id # repaired after r_id status = 0
#             for (comp_type, comp_ids) in repairs_it
#                 comp_status_key = PowerModels.pm_component_status[comp_type]
#                 comp_status_inactive = PowerModels.pm_component_status_inactive[comp_type]
#                 for comp_id in comp_ids
#                     r_data[comp_type][comp_id][comp_status_key] = comp_status_inactive
#                 end
#             end
#         else
#              # repairs to be order in this stage
#         end
#     end

#     # solve ROP
#     repair_periods=count_repairable_items(r_data)
#     mn_network = replicate_restoration_network(r_data, repair_periods, PowerModels._pm_global_keys)
#     solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer; )
#     clean_status!(solution["solution"])

#     # insert reordered reapirs into  reapirs
#     r_repairs =  get_repairs(solution)
#     for (rr_id, repairs) in r_repairs
#         if rr_id != "0"
#             nw_id = round(Int,(r_id-1)*items_per_partition)+parse(Int,rr_id)

#             @show r_id
#             @show rr_id
#             @show nw_id

#             new_repair_ordering["$nw_id"] = Dict(comp_type=>String[] for comp_type in restoration_comps)
#             for (comp_type,comp_id) in repairs
#                 push!(new_repair_ordering["$nw_id"][comp_type],comp_id)
#             end
#         end
#     end


#     # println(r_id)
#     # get_repairable_items(r_data) |> println
#     # get_repairs(solution) |> println
# end
# @show new_repair_ordering



# ## Test out infeasilibty of -brx rop problems


# using PowerModels, Gurobi, PowerModelsRestoration

# optimizer = optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag"=>0)


# # data["branch"]["2"]["br_x"] = -data["branch"]["2"]["br_x"]
# data["branch"]["1"]["damaged"] = 1
# # data["branch"]["2"]["damaged"] = 1

# data_mn = replicate_restoration_network(data,count=2)
# solution = run_rop(data_mn,DCPPowerModel,optimizer)


# run_mn_opf(data_mn,DCPPowerModel,optimizer)

# using Random

# br_id = 5
# br_id = 2
# br_id = 1
# data = PowerModels.parse_file("C:\\Users\\noahx\\Documents\\PowerDev/pglib-opf/api/pglib_opf_case60_c__api.m")
# # data["branch"]["$br_id"]["br_x"] = -data["branch"]["$br_id"]["br_x"]
# scen = 1.0
# branch_count = length(keys(data["branch"]))
# branch_ids = collect(keys(data["branch"]))
# permutated_ids = branch_ids[randperm(length(branch_ids))]
# damaged_ids = permutated_ids[1:round(Int,branch_count*scen)]
# damage_items!(data,Dict("branch"=>damaged_ids))
# count_repairable_items(data)

# run_opf(data,DCPPowerModel,optimizer) #negative br_x is feasible

# data["branch"]["$br_id"]["br_status"] = 0
# run_opf(data,DCPPowerModel,optimizer) # removing branch 1 is feasible

# # ROP with damaged branch 1 is infeasible
# data["branch"]["$br_id"]["br_status"] = 1
# data["branch"]["$br_id"]["damaged"] = 1
# data_mn = replicate_restoration_network(data,count=count_repairable_items(data))
# solution = run_rop(data_mn,DCPPowerModel,optimizer)

# solution = run_ots(data, DCPPowerModel,optimizer)


# silence()
# br_ids = 5:20
# combos = collect(combinations(br_ids))

# @progress for i ∈  size(combos)[1]
#     br_set
#     data = PowerModels.parse_file("C:\\Users\\noahx\\Documents\\PowerDev/pglib-opf/pglib_opf_case14_ieee.m")
#     for id ∈ br_set
#         data["branch"]["$id"]["br_x"] = -data["branch"]["$id"]["br_x"]
#     end
#     solution = run_ots(data, DCPPowerModel,optimizer)
#     branch_off = false
#     for id ∈ br_set
#         if solution["primal_status"]==FEASIBLE_POINT && solution["solution"]["branch"]["$id"]["br_status"]==0
#             println(br_set)
#             push!(result, string(br_set))
#         else
#             println("fail")
#             push!(result,"fail")
#         end
#     end
# end
# [k for k in result if k != "fail"] |> println

# using ProgressLogging

# silence()
# br_ids = 5:20
# combos = collect(combinations(br_ids))
# result = Vector{Vector{Int}}(undef, size(combos)[1])
# @progress for i in 1:size(combos)[1]
#     br_set = combos[i]
#     data = PowerModels.parse_file("C:\\Users\\noahx\\Documents\\PowerDev/pglib-opf/pglib_opf_case14_ieee.m")
#     for id ∈ br_set
#         data["branch"]["$id"]["br_x"] = -data["branch"]["$id"]["br_x"]
#     end
#     solution = run_ots(data, DCPPowerModel,optimizer)
#     if solution["primal_status"]==FEASIBLE_POINT
#         off = [br_id for  (br_id, branch) in solution["solution"]["branch"] if branch["br_status"]==0]
#     end
#     println(br_set)
#     println(off)
#     result[i] = intersect(br_set,off)
# end
# [k for k in result if !isempty(k)]


# b = 1
# va_fr = 1
# va_to = 0.5
# vad_max = 2
# vad_min = -2
# z = 0




## Test heuristic result and redispatch results
# data = PowerModels.parse_file("C:\\Users\\noahx\\Documents\\PowerDev\\RestorationCLI\\data\\experiment_data\\case39api_50.m")

# solution = rad_restoration(data, model_constructor, optimizer; time_limit = 1000.0)
# load = sum(sum(load["pd"] for (id,load) in net["load"] ) for (nwid,net) in solution["solution"]["nw"])

# case = deepcopy(data)
# clean_status!(data)
# case_mn = replicate_restoration_network(case, count=length(keys(solution["solution"]["nw"])))
# update_status!(case_mn, solution["solution"])

# sol2 = run_restoration_redispatch(case_mn, DCPPowerModel, optimizer)
# load2 = sum(sum(load["pd"] for (id,load) in net["load"] ) for (nwid,net) in solution["solution"]["nw"])
# load_diff = load-load2



# solution = run_iterative_restoration(data, model_constructor, optimizer; time_limit = 1000.0)
# load = sum(sum(load["pd"] for (id,load) in net["load"] ) for (nwid,net) in solution["solution"]["nw"])

# case = deepcopy(data)
# clean_solution!(solution)
# clean_status!(data)
# case_mn = replicate_restoration_network(case, count=length(keys(solution["solution"]["nw"])))
# update_status!(case_mn, solution["solution"])

# sol2 = run_restoration_redispatch(case_mn, DCPPowerModel, optimizer)
# load2 = sum(sum(load["pd"] for (id,load) in net["load"] ) for (nwid,net) in solution["solution"]["nw"])
# load_diff = load-load2


## Test util 2 period problem
network = data
util_restoration_order = utilization_heuristic_restoration(network)

restoration_order = Dict{String,Any}("$nwid"=>Dict{String,Any}(comp_type=>String[] for comp_type in restoration_comps) for nwid in 1:2)
l = maximum(parse.(Int,collect(keys(util_restoration_order))))
m = round(Int,l/2)
net_keys = [1:m,m:l]
for r_id in axes(net_keys,1)
    for nw_id in net_keys[r_id]
        for comp_type in keys(restoration_order["$r_id"])
            append!(restoration_order["$r_id"][comp_type],util_restoration_order["$nw_id"][comp_type])
        end
    end
end
restoration_order