"""
    PyList([T,] [o])

A Julia vector wrapping the Python list `o` (or anything satisfying the sequence interface).

`T` can be a type or a `AbstractPyConverter`, and specifies the element type and conversion policy.
"""
struct PyList{T, TC<:AbstractPyConverter{T}} <: AbstractVector{T}
    elconverter :: TC
    parent :: PyObject
end
PyList(T=PyObject, o::PyObject=pylist()) = PyList(AbstractPyConverter(T), o)
PyList(o::PyObject) = PyList(PyObject, o)
export PyList

unsafe_pyobj(x::PyList) = x.parent

Base.length(x::PyList) = length(x.parent)

Base.size(x::PyList) = (length(x),)

function Base.getindex(x::PyList, i::Integer)
    checkbounds(x, i)
    pyconvert(x.elconverter, pygetitem(x, i-1))
end

function Base.setindex!(x::PyList, v, i::Integer)
    vo = PyObject(x.elconverter, v)
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

function Base.push!(x::PyList, v)
    vo = PyObject(x.elconverter, v)
    x.parent.append(vo)
    x
end

function Base.pop!(x::PyList, i::Integer=length(x))
    checkbounds(x, i)
    vo = x.parent.pop(i-1)
    pyconvert(x.elconverter, vo)
end

Base.popfirst!(x::PyList) = pop!(x, 1)

function Base.insert!(x::PyList, i::Integer, v)
    1 ≤ i ≤ length(x)+1 || throw(BoundsError(x, i))
    vo = PyObject(x.elconverter, v)
    x.parent.insert(i-1, v)
    x
end

Base.pushfirst!(x::PyList, v) = insert!(x, 1, v)
