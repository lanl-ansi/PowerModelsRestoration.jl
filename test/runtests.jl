using PowerModelsRestoration
using Test

import InfrastructureModels
import PowerModels
import PowerModelsMLD
import Memento

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

import Cbc
import Ipopt
import Juniper

# default setup for solvers
cbc_solver = with_optimizer(Cbc.Optimizer, logLevel=0)
ipopt_solver = with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
juniper_solver = with_optimizer(Juniper.Optimizer, nl_solver=PowerModels.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), mip_solver=cbc_solver, log_levels=[])

include("common.jl")

@testset "PowerModelsRestoration" begin

include("rop.jl")
include("hueristic.jl")
include("util.jl")

end

