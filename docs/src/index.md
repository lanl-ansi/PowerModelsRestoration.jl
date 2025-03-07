# PowerModelsRestoration.jl Documentation

```@meta
CurrentModule = PowerModelsRestoration
```

## Overview


## Installation

The latest stable release of PowerModelsRestoration can be installed using the Julia package manager with

```julia
] add PowerModelsRestoration
```

For the current development version, "checkout" this package with

```julia
] add PowerModelsRestoration#master
```

At least one solver is required for running PowerModelsRestoration.  The open-source solver Ipopt is recommended, as it is fast, scalable and can be used to solve a wide variety of the problems and network formulations provided in PowerModels.  The Ipopt solver can be installed via the package manager with

```julia
] add Ipopt
```

Test that the package works by running

```julia
] test PowerModelsRestoration
```

## Maximum Load Delivery Quick Start

The primary entry point of the Maximum Load Delivery (MLD) problem is the `PowerModelsRestoration.run_ac_mld_uc` function, which provides a scalable heuristic for solving the AC-MLD problem.
The following example illustrates how to load a network, damage components and solve the AC-MLD problem.
```
using PowerModels; using PowerModelsRestoration; using Ipopt
network_file = joinpath(dirname(pathof(PowerModels)), "../test/data/matpower/case5.m")
case = PowerModels.parse_file(network_file)

case["bus"]["2"]["bus_type"] = 4
case["gen"]["2"]["gen_status"] = 0
case["branch"]["7"]["br_status"] = 0

result = PowerModelsRestoration.run_ac_mld_uc(case, Ipopt.Optimizer)
```
The result data indicates that only 700 of the 1000 MWs can be delivered given the removal of bus 2, generator 2 and branch 7.
