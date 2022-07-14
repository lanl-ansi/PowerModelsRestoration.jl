# PowerModelsRestoration.jl Change Log

## v0.7.0
- Add heuristics for Restoration Ordering Problem `run_rop`
  -  Utilization (#62)
  -  Recursive Restoration Refinement (#63)
  -  Randomized Adaptive Decomposition (#63)
- Update for JuMP v1.0 (#65)

## v0.6.1
- Fixed bugs in `constraint_bus_energized` and `run_iterative_restoration` (#55,#57)

## v0.6.0
- Add support for InfrastructureModels multi-infrastructure functions (breaking)
- Update to PowerModels v0.17 (breaking)

## v0.5.1
- Fixed bug in iterative restoration solution generation (#44)
- Add const for supported components for repairs `restoration_comps`
- Update `get_repairable_items`, `get_damaged_items`, `clear_damage_indicator` to use `restoration_comps`

## v0.5.0
- Update to new function name convention of PowerModels v0.17 details in PR #40 (breaking)
- Update to PowerModels v0.17 (breaking)

## v0.4.0
- Update to PowerModels v0.16 (breaking)
- Add support for Memento v0.13, v1.0

## v0.3.0
- Update to PowerModels v0.15 (breaking)

## v0.2.1
- Minor fix to result building in run_iterative_restoration
- Add upper bound on test solver versions

## v0.2.0
- Added a subproblem for restoration simulation `iterative_rop` (#20)
- Changed `_clean_status!` to set status to the inactive value if it is approximately that value, instead of rounding (#20)
- Changed name of `solution_rop` to `solution_rop!` (#18) [breaking]
- Changed name of `solution_mrsp` to `solution_mrsp!` (#18) [breaking]
- Changed name of `run_restoration_simulation` to `run_restoration_redispatch` (#20) [breaking]

## v0.1.1
- Added support for InfrastructureModels v0.4

## v0.1.0
- initial implementation
