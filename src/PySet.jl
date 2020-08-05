"""
    PySet{T=PyObject}(o=pylist()) :: AbstractSet{T}

A Julia set wrapping the Python set `o` (or anything satisfying the set interface).
"""
struct PySet{T} <: AbstractSet{T}
    parent :: PyObject
end
PySet{T}() where {T} = PySet{T}(pyset())
PySet(o=pyset()) = PySet{PyObject}(o)
export PySet

unsafe_pyobj(x::PySet) = x.parent

Base.convert(::Type{PySet}, d::PySet) = d
Base.convert(::Type{PySet{T}}, d::PySet) where {T} = PySet{T}(d)

### SET INTERFACE

Base.length(x::PySet) = length(x.parent)

function Base.iterate(x::PySet{T}, st...) where {T}
    z = iterate(x.parent, st...)
    z === nothing && return nothing
    vo, newst = z
    (pyconvert(T, vo), newst)
end

### CONVERSIONS

unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Set")}, o) where {T<:PySet} =
    VNE{T}(T(o))
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Set")}, o) where {T>:PySet} =
    unsafe_pyconvert_rule(PySet, Val(Symbol("collections.abc.Set")), o)
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Set")}, o) where {V, T>:PySet{V}} =
    unsafe_pyconvert_rule(PySet{V}, Val(Symbol("collections.abc.Set")), o)
