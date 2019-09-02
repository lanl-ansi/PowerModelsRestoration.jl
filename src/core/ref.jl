""
function calc_equal_repairs_per_period(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw)
    gen = _PMs.ref(pm, nw, :gen_damaged)
    storage = _PMs.ref(pm, nw, :storage_damaged)
    branch = _PMs.ref(pm, nw, :branch_damaged)

    total_repairs = length(keys(gen)) + length(keys(storage)) + length(keys(branch))

    repair_periods = max(maximum(collect(keys(_PMs.nws(pm)))), 1)
    repairs_per_period = ceil(Int, total_repairs/repair_periods)

    return repairs_per_period
end

""
function calc_repair_time_elapsed(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw)
    gen = _PMs.ref(pm, nw, :gen_damaged)
    storage = _PMs.ref(pm, nw, :storage_damaged)
    branch = _PMs.ref(pm, nw, :branch_damaged)

    total_repairs = length(keys(gen)) + length(keys(storage)) + length(keys(branch))

    repair_periods = max(maximum(collect(keys(_PMs.nws(pm)))), 1)
    repairs_per_period = ceil(Int, total_repairs/repair_periods)

    repairs_per_period*(nw+1)
    if repairs_per_period*(nw+1) < total_repairs 
        time_elapsed = repairs_per_period
    else
        time_elapsed = total_repairs - repairs_per_period*(nw)
    end

    return time_elapsed
end

function calc_cumulative_repairs_per_period(pm::_PMs.GenericPowerModel; nw::Int=pm.cnw)
    gen = _PMs.ref(pm, nw, :gen_damaged)
    storage = _PMs.ref(pm, nw, :storage_damaged)
    branch = _PMs.ref(pm, nw, :branch_damaged)

    nw
    total_repairs = length(keys(gen)) + length(keys(storage)) + length(keys(branch))

    repair_periods = max(maximum(collect(keys(_PMs.nws(pm)))), 1)
    repairs_per_period = ceil(Int, total_repairs/repair_periods)

    if repairs_per_period*(nw) < total_repairs 
        cumulative_repairs = repairs_per_period*nw
    else
        cumulative_repairs = total_repairs
    end

    return cumulative_repairs
end