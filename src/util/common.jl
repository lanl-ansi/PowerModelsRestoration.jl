# "combine data into multinetwork summary"
# function process_network(network_data)

#     if haskey(network_data, "nw")
#         nw = sort(collect(keys(network_data["nw"])))
#         sol = Dict{String,Any}(
#             "multinetwork" => true,
#             "per_unit" => network_data["per_unit"],
#             "nw" => Dict{String,Any}(n => network_data["nw"][n]["solution"]["solution"] for n in nw)
#         )
#         data = Dict{String,Any}(
#             "name" => string(network_data["name"]),
#             "nw" => Dict{String,Any}(n => network_data["nw"][n]["solution"]["data"] for n in nw)
#         )

#         objective = sum(network_data["nw"][n]["solution"]["objective"] for n in nw)
#         objective_lb = sum(network_data["nw"][n]["solution"]["objective_lb"] for n in nw)
#         solve_time = sum(network_data["nw"][n]["solution"]["solve_time"] for n in nw)

#         solution = Dict{String, Any}(
#             "solve_time" => solve_time::Float64,
#             "optimizer" => network_data["nw"][nw[1]]["solution"]["optimizer"],
#             "termination_status" => network_data["nw"][nw[1]]["solution"]["termination_status"],
#             "dual_status" => network_data["nw"][nw[1]]["solution"]["dual_status"],
#             "primal_status" => network_data["nw"][nw[1]]["solution"]["primal_status"],
#             "objective" => objective::Float64,
#             "solution" => sol,
#             "machine" => network_data["nw"][nw[1]]["solution"]["machine"],
#             "data" => data,
#             "objective_lb" => objective_lb::Float64,
#             "per_unit" => network_data["nw"][nw[1]]["per_unit"],
#             "baseMVA" => network_data["nw"][nw[1]]["baseMVA"],
#         )
#     else
#         #TODO make error message, data is not multinetwork
#     end

#     return solution
# end
