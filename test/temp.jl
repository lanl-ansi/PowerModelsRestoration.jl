Pkg.activate("./")
using PowerModels, PowerModelsRestoration, InfrastructureModels
using Gurobi, JuMP, Ipopt, Juniper
_PM = PowerModels
_IM = InfrastructureModels

network = parse_file("./test/data/case5_restoration_iterative.m")
pglib_path = "C:/Users/noahx/Documents/PowerDev/pglib-opf/"
# network=parse_file(string(pglib_path,"pglib_opf_case118_ieee.m"))
# network=parse_file(string(pglib_path,"pglib_opf_case14_ieee.m"))



juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer,
"nl_solver"=>PowerModels.optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-4, "print_level"=>0),
"log_levels"=>[], "time_limit"=>5.0)


# # damage_items = Dict{String,Array{String,1}}("bus"=>collect(keys(network["bus"])))
# damage_items = Dict{String,Array{String,1}}("bus"=>collect(keys(network["bus"])))
# damage_items!(network,damage_items)
# propagate_damage_status!(network)
# repair_periods = 2
# model_constructor = DCPPowerModel

# const GRB_ENV = Gurobi.Env()
# gurobi_solver = JuMP.optimizer_with_attributes(()->Gurobi.Optimizer(GRB_ENV), "OutputFlag"=>0)

# repair_count = count_repairable_items(network)
# # t = calc_time_periods(repair_count, repair_periods)

# # ## replicate network, set repairs per period
# # mn_network = replicate_network(network, repair_periods, _PM._pm_global_keys)
# # apply_repair_limits!(mn_network, t)

# # for (id,net) in mn_network["nw"]
# #     @show id
# #     println(net["repaired_total"])
# # end

# solution_iter = run_iter_res(network, DCPPowerModel, Gurobi.Optimizer)
# solution_rop = run_rop(replicate_restoration_network(network, count=count_damaged_items(network)),DCPPowerModel,Gurobi.Optimizer)

# for (nwid, net) in solution_iter["solution"]["nw"]
#     if !haskey(net,"load")
#         net["load"] = Dict()
#     end
# end

# print_summary_restoration(solution_iter["solution"])

# mn_iter = replicate_network(network, length(keys(solution_iter["solution"]["nw"])), _PM._pm_global_keys)
# update_data!(mn_iter,solution_iter["solution"])
# delete!(mn_iter["nw"],"0")

# using VegaLite, PowerPlots
# df_iter = PowerModelsDataFrame(mn_iter)

# p1 = @vlplot(
#     data=df_iter.load,
#     title="Iter",
#     :line,
#     x="nw_id:q",
#     y=:pd,
#     color={"index:o", title="Loads"}
# )

# mn_rop = replicate_network(network, length(keys(solution_rop["solution"]["nw"])), _PM._pm_global_keys)
# update_data!(mn_rop,solution_rop["solution"])
# delete!(mn_rop["nw"],"0")

# df_rop = PowerModelsDataFrame(mn_rop)
# p2 = @vlplot(
#     data=df_rop.load,
#     title="ROP",
#     :line,
#     x="nw_id:q",
#     y=:pd,
#     color={"index:o", title="Loads"}
# )

# hcat(p1,p2)


# function load_power(sol)
#     loads = []
#     for (nw_id, net) in sol["solution"]["nw"]
#         push!(loads, nw_id=>sum(load["pd"] for (load_id, load) in get(net, "load", Dict("0"=>Dict("pd"=>0))) ))
#     end
#     return loads
# end
# load_ids = collect(keys(network["load"]))
# sum(l for (_,l) in load_power(solution_iter))
# sum(l for (_,l) in load_power(solution_rop))

# using Plots
# delete!(solution_rop["solution"]["nw"],"0")
# l_iter = load_power(solution_iter)
# l_rop = load_power(solution_rop)
# ti = [parse(Int,i.first) for i in l_iter]
# li = [i.second for i in l_iter]
# tr = [parse(Int,i.first) for i in l_rop]
# lr = [i.second for i in l_rop]
# plot(scatter(ti,li), scatter(tr,lr))

# nwid in 1:19
# loadid in 1:3
# iter_loads = [get(get(get(solution_iter["solution"]["nw"]["$(nwid)"],"load", Dict()),"$(loadid)",Dict()),"pd",0) for nwid in 1:19,loadid in 1:3]
# rop_loads = [get(get(get(solution_rop["solution"]["nw"]["$(nwid)"],"load", Dict()),"$(loadid)",Dict()),"pd",0) for nwid in 1:19,loadid in 1:3]
# plot(plot(iter_loads),plot(rop_loads)



# clean_status!(solution["solution"]) # replace stauts with bus_type for buses

# get_repairs(solution)
# apply_repairs()
# count_repairs(solution)

# repair_count = count_repairable_items(network)
# t = calc_time_periods(repair_count, repair_periods)

# ## replicate network, set repairs per period
# mn_network = replicate_network(network, repair_periods, _PM._pm_global_keys)
# apply_repair_limits!(mn_network, t)

# ## solve ROP
# solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer;)
# clean_status!(solution["solution"]) # replace status with bus_type for buses
# apply_repairs!(mn_network, get_repairs(solution))

# repairables = get_repairable_items(mn_network)
# count_repairable_items(mn_network["nw"]["1"])



# repair_count = count_repairable_items(network)
# t = calc_time_periods(repair_count, repair_periods)

# ## replicate network, set repairs per period
# mn_network = replicate_network(network, repair_periods, _PM._pm_global_keys)
# apply_repair_limits!(mn_network, t)

# ## solve ROP
# solution = PowerModelsRestoration._run_rop_ir(mn_network, model_constructor, optimizer;)
# clean_status!(solution["solution"]) # replace stauts with bus_type for buses
# apply_repairs!(mn_network, get_repairs(solution))

# ## temp
# delete!(mn_network["nw"],"0")


# # ## calc subproblem
# # for (nw_id, net) in mn_network["nw"]
#     nw_id = "1"; net = mn_data["nw"][nw_id]

#     t_sub = t[parse(Int,nw_id)]
#     repairable_count = count_repairable_items(net)

#     # # check termination conditions
#     # if !(length(t_sub) == 1 || repairable_count == 1)
#     #     sub_net = deepcopy(net)
#     #     for key in _PM._pm_global_keys
#     #         if haskey(network, key)
#     #             sub_net[key] = network[key]
#     #         end
#     #     end

#     #     sub_sol = run_iter_res(sub_net, model_constructor, optimizer; repair_periods, kwargs...)
#     # end
# # end

# repair_count = 7
# repair_periods = 2
# t = collect(4:8)
# # t_split = split_time_periods(t, repair_count, repair_periods)
# repair_count=length(t)
# repairs_per_period = repair_count/repair_periods
# t_index = [[i for i in (p-1)*ceil(Int,repairs_per_period)+1:ceil(Int,repairs_per_period)*p if i <= repair_count] for p in 1:repair_periods]

# t_split = [[t[index] for index in period] for period in t_index]

# open("file.csv","w") do io
#     summary_restoration(io,solution_iter["solution"])
# end



# repair order
# case = network
# data = network

# d_comps = get_damaged_items(data)
# d_count = count_damaged_items(data)

# repair_order = Dict(
#     "1" => Dict("branch"=>["1"],),
#     "2" => Dict("gen"=>["1"],),
#     "3" => Dict("gen"=>["2"],),
#     "4" => Dict("gen"=>["3"],),
#     "5" => Dict("storage"=>["1"]),
#     "6" => Dict("bus"=>["1"],),
# )
# data_mn = replicate_restoration_network(data, count=6)
# PowerModelsRestoration.apply_restoration_sequence!(data_mn,repair_order)
# data_mn["nw"]["3"]["gen"]["1"]


data=parse_file(string(pglib_path,"pglib_opf_case57_ieee.m"))
damage_items!(data, Dict("bus"=>["$id" for id in 1:10]))
propagate_damage_status!(data)

restoration_order = utilization_heuristic_restoration(data)

data_mn = replicate_restoration_network(data, count=length(keys(restoration_order)))
apply_restoration_sequence!(data_mn, restoration_order)

run_restoration_redispatch(data_mn, ACPPowerModel, juniper_solver)





d_comp_vec = vcat([[(comp_type,comp_id) for comp_id in comp_ids] for (comp_type,comp_ids) in get_damaged_items(data)]...)
    d_comp_cost = [util_value(data,comp_type,comp_id) for (comp_type,comp_id) in d_comp_vec]
    d_comp_vec = [d_comp_vec[i] for i in sortperm(d_comp_cost)] # reordered damaged component vector


    restoration_period = Dict{Tuple{String, String},Any}(
        (d_comp_vec[id])=>id for id in 1:length(d_comp_vec)
    )

    # Create precedent repair requirements
    repair_constraints = calculate_repair_precedance(data)
    # apply precendet repair requirments
    updated = true
    while updated
        updated = false
        for (r_comp, precedance_comps) in repair_constraints
            precendent_repair_periods = [get(restoration_period,pr_comp,0) for pr_comp in precedance_comps]
            @show precendent_repair_periods
            if !isempty(precendent_repair_periods)
                final_precedent_repair = maximum(precendent_repair_periods)
            else
                final_precedent_repair = 0
            end
            @show final_precedent_repair
            if restoration_period[r_comp] < final_precedent_repair
                println("Changing $r_comp repair from $(restoration_period[r_comp]) to $final_precedent_repair")
                updated = true
                restoration_period[r_comp] = final_precedent_repair
            end
        end
    end

    # create repair order structure
    restoration_order = Dict{String,Any}("$nwid"=>Dict{String,Any}(comp_type=>String[] for comp_type in restoration_comps) for nwid in 1:length(d_comp_vec))
    for ((comp_type,comp_id),nwid) in restoration_period
        push!(restoration_order["$(nwid)"][comp_type], comp_id)
        # push!(restoration_order["$(nwid)"], comp)
    end

