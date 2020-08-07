abstract type AbstractCNumpyGenericObject <: AbstractCPyObject end

Base.@kwdef struct CNumpyGenericObject{T} <: AbstractCNumpyGenericObject
    base :: CPyObject = CPyObject()
    data :: T
end
