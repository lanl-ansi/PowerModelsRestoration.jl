# PowerModelsRestoration.jl Change Log

## Staged
- Fixed bug in iterative restoration solution generation (#44)
- Add support for InfrastructureModels multi-infrastructure functions.

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
