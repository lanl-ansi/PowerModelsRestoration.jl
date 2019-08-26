""
function calc_equal_repairs_per_period(pm::_PMs.GenericPowerModel)
    gen = _PMs.ref(pm, pm.cnw, :gen_damaged)
    storage = _PMs.ref(pm, pm.cnw, :storage_damaged)
    branch = _PMs.ref(pm, pm.cnw, :branch_damaged)

    total_repairs = length(keys(gen)) + length(keys(storage)) + length(keys(branch))

    repair_periods = max(sum(length(_PMs.nws(pm)))-1, 1)
    repairs_per_period = ceil(Int, total_repairs/repair_periods)

    return repairs_per_period
end

function calc_cumulative_repairs_per_period(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw)
    repairs_per_period = calc_equal_repairs_per_period(pm)
    cumulative_repairs = repairs_per_period*(nw-1)
    return cumulative_repairs
end