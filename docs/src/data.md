# Data

PowerModelsRestoration extends the base PowerModels data format by supporting a `damaged` key to components that need to be repaired.
Currently supported components for restoration are:

```@example
using PowerModelsRestoration #hide
PowerModelsRestoration.restoration_components
```

To specify a damaged component,  sets its `damaged` value to 1.
```julia
case["gen"]["1"]["damaged"]==1
```



## Terminology
There are three terms related to the status of components:
- active (inactive)
- damaged
- repairable

The component status value, e.g. `gen["gen_status"]=1` determines that a component is active.
The damaged status is determined by `gen["damaged"]=1`.
A component is repairable if is it active and damaged, `gen["gen_status"]==1 && gen["damaged"]==1`.

Why? if a component is not active, it is filtered out of the network by the powermodels functions that create an optimization problem. When determining how many repairs can be done, this must be accounted for.

In addition, this allows heuristic problems like RAD to only consider repairing subsets of items that are active, i.e. a component that is damaged but not active is for future restoration problems.


## Data Functions
The following functions are responsible for handling the data dictionary used in PowerModelsRestoration:

```@autodocs
Modules = [PowerModelsRestoration]
Pages   = ["core/data.jl"]
Order   = [:function]
Private  = true
```
