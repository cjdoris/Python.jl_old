"""
    PyDict{K,V}(o=pydict()) :: AbstractDict{K,V}

A Julia dictionary wrapping the Python dictionary `o` (or anything satisfying the mapping interface).
"""
struct PyDict{K,V} <: AbstractDict{K,V}
    parent :: PyObject
end
PyDict{K,V}() where {K,V} = PyDict{K,V}(pydict())
PyDict{K}(o=pydict()) where {K} = PyDict{K,PyObject}(o)
PyDict(o=pydict()) = PyDict{PyObject,PyObject}(o)
export PyDict

unsafe_pyobj(d::PyDict) = d.parent

Base.convert(::Type{PyDict}, d::PyDict) = d
Base.convert(::Type{PyDict{K}}, d::PyDict) where {K} = PyDict{K,valtype(d)}(d)
Base.convert(::Type{PyDict{K,V}}, d::PyDict) where {K,V} = PyDict{K,V}(d)

### DICT INTERFACE

Base.length(d::PyDict) = Base.length(d.parent)

function Base.iterate(d::PyDict{K,V}, it=nothing) where {K,V}
    if it===nothing
        it = pyiter(d.parent.items())
    end
    o = unsafe_pyiter_next(it)
    if !isnull(o)
        ko, vo = o
        k = pyconvert(K, ko)
        v = pyconvert(V, vo)
        return (k => v), it
    elseif pyerror_occurred()
        pythrow()
    else
        return nothing
    end
end

function Base.get(d::PyDict{K,V}, k, dflt) where {K,V}
    ko = PyObject(convert(K, k))
    vo = unsafe_pygetitem(d.parent, ko)
    if !isnull(vo)
        return pyconvert(V, vo)
    elseif pyerror_occurred_KeyError()
        pyerror_clear()
        return dflt
    else
        pythrow()
    end
end

function Base.setindex!(d::PyDict{K,V}, v, k) where {K,V}
    ko = PyObject(convert(K, k))
    vo = PyObject(convert(V, v))
    pysetitem(d.parent, ko, vo)
    d
end

### CONVERSIONS

unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Mapping")}, o) where {T<:PyDict} =
    VNE{T}(T(o))
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Mapping")}, o) where {T>:PyDict} =
    unsafe_pyconvert_rule(PyDict, Val(Symbol("collections.abc.Mapping")), o)
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Mapping")}, o) where {K, T>:PyDict{K}} =
    unsafe_pyconvert_rule(PyDict{K}, Val(Symbol("collections.abc.Mapping")), o)
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Mapping")}, o) where {K, V, T>:PyDict{K,V}} =
    unsafe_pyconvert_rule(PyDict{K,V}, Val(Symbol("collections.abc.Mapping")), o)
