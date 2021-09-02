
"""
How to structure a  "repair order" dictionary?

repair_order= Dict{String,Any}(
    "1" => Dict{String,Any}("branch"=>["1","2"],"bus"=>[])
    "2" => Dict{String,Any}("branch"=>["4"],"bus"=>[])
)

## Current implementation ##
repair_order= Dict{String,Any}(
    "1" => Dict{String,Any}([("branch","1"),("bus","1")])
    "2" => Dict{String,Any}([("branch","4")])
)

repair_order= Dict(
    "branch"=>Dict("1"=> nw_id, "2" => nw_id)
    "bus"=>Dict("1"=> 2, "2" => 4)
)
"""


"Just change status, or also change damage field?"
# """
#     update device status and remove damaged indicator if item was repaired in network 3
#     Before:
#     | nw_id   |  1  |  2  |  3  |  4  |
#     | ------- | --- | --- | --- | --- |
#     | status  |  1  |  1  |  1  |  1  |
#     | damaged |  1  |  1  |  1  |  1  |

#     Repaired in network 3
#     After:
#     | nw_id   |  1  |  2  |  3  |  4  |
#     | ------- | --- | --- | --- | --- |
#     | status  |  0  |  0  |  1  |  1  |
#     | damaged |  1  |  1  |  1  |  0  |
# """
function apply_restoration_sequence!(data::Dict{String,<:Any}, repair_order::Dict{String,<:Any})
    if !_IM.ismultinetwork(data)
        Memento.error(_PM._LOGGER, "Cannot apply restoration sequence.  Data is not a multinetwork")
    end

    for (repair_nw_id, comp_data) in repair_order
        for (comp_type, comp_ids) in comp_data
            status_key = _PM.pm_component_status[comp_type]
            for comp_id in comp_ids
                for (nw_id, net) in data["nw"]
                    if  parse(Int,nw_id) < parse(Int,repair_nw_id)
                        net[comp_type][comp_id][status_key] = _PM.pm_component_status_inactive[comp_type]
                    elseif nw_id >= repair_nw_id
                        net[comp_type][comp_id][status_key] = 1
                    end
                end
            end
        end
    end
    return data
end


# function apply_repairs!(data, repairs)
#     for (repair_nw_id, repair_list) in repairs
#         for (comp_type, comp_id) in repair_list
#             status_key = _PM.pm_component_status[comp_type]
#             for (nw_id, net) in data["nw"]
#                 if  nw_id < repair_nw_id
#                     net[comp_type][comp_id][status_key] = _PM.pm_component_status_inactive[comp_type]
#                 elseif nw_id > repair_nw_id
#                     net[comp_type][comp_id]["damaged"] = 0
#                 end
#             end
#         end
#     end
#     return data
# end
