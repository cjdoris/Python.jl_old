"""
    PyList{T=PyObject}(o=pylist()) :: AbstractVector{T}

A Julia vector wrapping the Python list `o` (or anything satisfying the sequence interface).
"""
struct PyList{T} <: AbstractVector{T}
    parent :: PyObject
end
PyList{T}() where {T} = PyList{T}(pylist())
PyList(o=pylist()) = PyList{PyObject}(o)
export PyList

unsafe_pyobj(x::PyList) = x.parent

Base.convert(::Type{PyList}, d::PyList) = d
Base.convert(::Type{PyList{T}}, d::PyList) where {T} = PyList{T}(d)

### VECTOR INTERFACE

Base.length(x::PyList) = length(x.parent)

Base.size(x::PyList) = (length(x),)

function Base.getindex(x::PyList{T}, i::Integer) where {T}
    checkbounds(x, i)
    pyconvert(T, pygetitem(x, i-1))
end

function Base.setindex!(x::PyList{T}, v, i::Integer) where {T}
    vo = PyObject(convert(T, v))
    checkbounds(x, i)
    pysetitem(x.parent, i-1, vo)
    x
end

function Base.resize!(x::PyList, m::Integer)
    n = length(x)
    while n > m
        x.parent.pop()
        n -= 1
    end
    while n < m
        x.parent.append(pynone())
        n += 1
    end
    @assert length(x) == m
    x
end

function Base.push!(x::PyList{T}, v) where {T}
    vo = PyObject(convert(T, v))
    x.parent.append(vo)
    x
end

function Base.pop!(x::PyList{T}, i::Integer=length(x)) where {T}
    checkbounds(x, i)
    vo = x.parent.pop(i-1)
    pyconvert(T, vo)
end

Base.popfirst!(x::PyList) = pop!(x, 1)

function Base.insert!(x::PyList{T}, i::Integer, v) where {T}
    1 ≤ i ≤ length(x)+1 || throw(BoundsError(x, i))
    vo = PyObject(convert(T, v))
    x.parent.insert(i-1, v)
    x
end

Base.pushfirst!(x::PyList, v) = insert!(x, 1, v)

### CONVERSIONS

unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Sequence")}, o) where {T<:PyList} =
    VNE{T}(T(o))
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Sequence")}, o) where {T>:PyList} =
    unsafe_pyconvert_rule(PyList, Val(Symbol("collections.abc.Sequence")), o)
unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("collections.abc.Sequence")}, o) where {V, T>:PyList{V}} =
    unsafe_pyconvert_rule(PyList{V}, Val(Symbol("collections.abc.Sequence")), o)
