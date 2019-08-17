"required until storage for AbstractWRForm exists in PowerModels"
function _PMs.constraint_storage_loss(pm::_PMs.AbstractWModels, n::Int, i, bus, conductors, r, x, p_loss, q_loss)
    w = Dict(c => _PMs.var(pm, n, c, :w, bus) for c in conductors)
    ps = Dict(c => _PMs.var(pm, n, c, :ps, i) for c in conductors)
    qs = Dict(c => _PMs.var(pm, n, c, :qs, i) for c in conductors)
    sc = _PMs.var(pm, n, :sc, i)
    sd = _PMs.var(pm, n, :sd, i)

    JuMP.@constraint(pm.model, 
        sum(ps[c] for c in conductors) + (sd - sc)
        ==
        p_loss + sum(r[c]*(ps[c]^2 + qs[c]^2)/JuMP.upper_bound(w[c]) for c in conductors)
    )

    JuMP.@constraint(pm.model, 
        sum(qs[c] for c in conductors)
        ==
        q_loss + sum(x[c]*(ps[c]^2 + qs[c]^2)/JuMP.upper_bound(w[c]) for c in conductors)
    )
end
