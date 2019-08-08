"required until storage for AbstractWRForm exists in PowerModels"
function _PMs.constraint_storage_loss(pm::_PMs.GenericPowerModel{T}, n::Int, i, bus, r, x, standby_loss) where T <: _PMs.AbstractWRForm
    w = _PMs.var(pm, n, pm.ccnd, :w, bus)
    ps = _PMs.var(pm, n, pm.ccnd, :ps, i)
    qs = _PMs.var(pm, n, pm.ccnd, :qs, i)
    sc = _PMs.var(pm, n, :sc, i)
    sd = _PMs.var(pm, n, :sd, i)

    JuMP.@constraint(pm.model, ps + (sd - sc) >= standby_loss + r*(ps^2 + qs^2)/JuMP.upper_bound(w))
end
