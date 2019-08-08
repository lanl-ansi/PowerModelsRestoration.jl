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
] add PowerModels#master
```

At least one solver is required for running PowerModels.  The open-source solver Ipopt is recommended, as it is fast, scaleable and can be used to solve a wide variety of the problems and network formulations provided in PowerModels.  The Ipopt solver can be installed via the package manager with

```julia
] add Ipopt
```

Test that the package works by running

```julia
] test PowerModelsRestoration
```
