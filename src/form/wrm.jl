

function variable_bus_voltage_on_off(pm::_PMs.AbstractWRMModel, nw::Int=pm.cnw, cnd::Int=pm.ccnd; bounded = true, kwargs...)
    wr_min, wr_max, wi_min, wi_max = _PMs.ref_calc_voltage_product_bounds(_PMs.ref(pm, nw, :buspairs))

    bus_count = length(_PMs.ref(pm, nw, :bus))
    w_index = 1:bus_count
    lookup_w_index = Dict([(bi, i) for (i,bi) in enumerate(keys(_PMs.ref(pm, nw, :bus)))])

    WR = _PMs.var(pm, nw, cnd)[:WR] = JuMP.@variable(pm.model, [1:bus_count, 1:bus_count], Symmetric, base_name="$(nw)_$(cnd)_WR")
    WI = _PMs.var(pm, nw, cnd)[:WI] = JuMP.@variable(pm.model, [1:bus_count, 1:bus_count], base_name="$(nw)_$(cnd)_WI")

    # bounds on diagonal
    for (i, bus) in _PMs.ref(pm, nw, :bus)
        w_idx = lookup_w_index[i]
        wr_ii = WR[w_idx,w_idx]
        wi_ii = WR[w_idx,w_idx]

        if bounded
            JuMP.set_lower_bound(wr_ii, min(0, bus["vmin"][cnd]^2))
            JuMP.set_upper_bound(wr_ii, max(0, bus["vmax"][cnd]^2))

            #this breaks SCS on the 3 bus exmple
            # JuMP.set_lower_bound(wi_ii, 0)
            # JuMP.set_upper_bound(wi_ii, 0)
        else
            JuMP.set_lower_bound(wr_ii, 0)
        end
    end

    # bounds on off-diagonal
    for (i,j) in _PMs.ids(pm, nw, :buspairs)
        wi_idx = lookup_w_index[i]
        wj_idx = lookup_w_index[j]

        if bounded
            JuMP.set_upper_bound(WR[wi_idx, wj_idx], max(0, wr_max[(i,j)]))
            JuMP.set_lower_bound(WR[wi_idx, wj_idx], min(0, wr_min[(i,j)]))

            JuMP.set_upper_bound(WI[wi_idx, wj_idx], max(0, wi_max[(i,j)]))
            JuMP.set_lower_bound(WI[wi_idx, wj_idx], min(0, wi_min[(i,j)]))
        end
    end

    _PMs.var(pm, nw, cnd)[:w] = Dict{Int,Any}()
    for (i, bus) in _PMs.ref(pm, nw, :bus)
        w_idx = lookup_w_index[i]
        _PMs.var(pm, nw, cnd, :w)[i] = WR[w_idx,w_idx]
    end

    _PMs.var(pm, nw, cnd)[:wr] = Dict{Tuple{Int,Int},Any}()
    _PMs.var(pm, nw, cnd)[:wi] = Dict{Tuple{Int,Int},Any}()
    for (i,j) in _PMs.ids(pm, nw, :buspairs)
        w_fr_index = lookup_w_index[i]
        w_to_index = lookup_w_index[j]

        _PMs.var(pm, nw, cnd, :wr)[(i,j)] = WR[w_fr_index, w_to_index]
        _PMs.var(pm, nw, cnd, :wi)[(i,j)] = WI[w_fr_index, w_to_index]
    end
end


function constraint_bus_voltage_on_off(pm::_PMs.AbstractWRMModel, n::Int, c::Int)
    WR = _PMs.var(pm, n, c, :WR)
    WI = _PMs.var(pm, n, c, :WI)
    z_voltage = _PMs.var(pm, n, :z_voltage)

    JuMP.@SDconstraint(pm.model, [WR WI; -WI WR] >= 0)

    for (i,bus) in _PMs.ref(pm, n, :bus)
        constraint_voltage_magnitude_sqr_on_off(pm, i; nw=n, cnd=c)
    end

    # is this correct?
    constraint_bus_voltage_product_on_off(pm; nw=n, cnd=c)
end


