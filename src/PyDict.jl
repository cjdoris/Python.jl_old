"""
    PyDict([[K, [V,]] [o])

A Julia dictionary wrapping the Python dictionary `o` (or anything satisfying the mapping interface).

`K` and `V` can be types or `AbstractPyConverter`s, and specify the key and value types and conversion policy.
"""
struct PyDict{K, V, KC<:AbstractPyConverter{K}, VC<:AbstractPyConverter{V}} <: AbstractDict{K, V}
    keyconverter :: KC
    valconverter :: VC
    parent :: ConcretePyObject
end
PyDict(K=PyObject, V=PyObject, o::PyObject=pydict()) =
    PyDict(AbstractPyConverter(K), AbstractPyConverter(V), o)
PyDict(K, o::PyObject) =
    PyDict(K, PyObject, o)
PyDict(o::PyObject) =
    PyDict(PyObject, PyObject, o)
export PyDict

unsafe_pyobj(d::PyDict) = d.parent

Base.length(d::PyDict) = Base.length(d.parent)

function Base.iterate(d::PyDict, it=nothing)
    if it===nothing
        it = pyiter(d.parent.items())
    end
    o = unsafe_pyiter_next(it)
    if !isnull(o)
        ko, vo = o
        k = pyconvert(d.keyconverter, ko)
        v = pyconvert(d.valconverter, vo)
        return (k => v), it
    elseif pyerror_occurred()
        pythrow()
    else
        return nothing
    end
end

function Base.get(d::PyDict, k, dflt)
    ko = PyObject(d.keyconverter, k)
    vo = unsafe_pygetitem(d.parent, ko)
    if !isnull(vo)
        return pyconvert(d.valconverter, vo)
    elseif pyerror_occurred_KeyError()
        pyerror_clear()
        return dflt
    else
        pythrow()
    end
end

function Base.setindex!(d::PyDict, v, k)
    ko = PyObject(d.keyconverter, k)
    vo = PyObject(d.valconverter, v)
    pysetitem(d, ko, vo)
    d
end
