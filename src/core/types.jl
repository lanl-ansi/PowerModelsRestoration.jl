""
abstract type AbstractACRQModel <: _PM.AbstractACRModel end

""
mutable struct ACRQPowerModel <: AbstractACRQModel _PM.@pm_fields end