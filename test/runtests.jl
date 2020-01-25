using PowerModelsRestoration
using Test

import InfrastructureModels
import PowerModels
import Memento
import JuMP

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

import Cbc
import Ipopt
import Juniper
import SCS

# default setup for solvers
cbc_solver = with_optimizer(Cbc.Optimizer, logLevel=0)
ipopt_solver = with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
#juniper_solver = with_optimizer(Juniper.Optimizer, nl_solver=PowerModels.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), mip_solver=cbc_solver, log_levels=[])
juniper_solver = with_optimizer(Juniper.Optimizer, nl_solver=PowerModels.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), log_levels=[])
#juniper_solver = with_optimizer(Juniper.Optimizer, nl_solver=PowerModels.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), branch_strategy=:PseudoCost)
scs_solver = with_optimizer(SCS.Optimizer, max_iters=100000, eps=1e-5, verbose=0)

case3_mld = PowerModels.parse_file("../test/data/case3_mld.m")
case3_mld_s = PowerModels.parse_file("../test/data/case3_mld_s.m")
case3_mld_uc = PowerModels.parse_file("../test/data/case3_mld_uc.m")
case3_mld_lc = PowerModels.parse_file("../test/data/case3_mld_lc.m")
case5_mld_ft = PowerModels.parse_file("../test/data/case5_mld_ft.m")
case5_mld_strg = PowerModels.parse_file("../test/data/case5_mld_strg.m")
case5_mld_strg_uc = PowerModels.parse_file("../test/data/case5_mld_strg_uc.m")
case5_mld_strg_only = PowerModels.parse_file("../test/data/case5_mld_strg_only.m")
case5_pti = PowerModels.parse_file("../test/data/case5.raw")

pms_path = joinpath(dirname(pathof(PowerModels)), "..")
case24 = PowerModels.parse_file("$(pms_path)/test/data/matpower/case24.m")

case5_mld_uc = PowerModels.parse_file("../test/data/case5_mld_strg_uc.m")
case5_mld_uc["storage"] = Dict{String,Any}()

opt_gap_tol = 1e-3 # in the case of max, throw error if ub/lb < 1 - opt_gap_tol (note, non-SCS solvers are more accurate)


include("common.jl")

@testset "PowerModelsRestoration" begin

include("mld_output.jl")
include("mld_data.jl")
include("mld.jl")
include("mld_uc.jl")
include("mld_smpl.jl")
include("mld_strg.jl")

include("mrsp.jl")
include("rop.jl")
include("hueristic.jl")
include("iterative.jl")
include("restoration_simulation.jl")

include("util.jl")

end

