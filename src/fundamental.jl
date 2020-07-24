### PyObject

struct PyObject{T<:AbstractCPyObject}
    ref :: PyObjRef
    function PyObject{T}(ref::PyObjRef, check::Bool=true) where {T<:AbstractCPyObject}
        check && isnull(ref) && pythrow()
        new{T}(ref)
    end
end
export PyObject

const ConcretePyObject = PyObject{CPyObject}

PyObjRef(o::PyObject) = getfield(o, :ref)

Base.cconvert(::Type{<:Ptr}, o::PyObject) = PyObjRef(o)

ptr(o::PyObject) = ptr(PyObjRef(o))

refcnt(o::PyObject) = refcnt(PyObjRef(o))

pynull(::Type{T}=CPyObject) where {T<:AbstractCPyObject} = PyObject{T}(PyObjRef(), false)

iserr(o::PyObject) = isnull(o)

pynulltype() = pynull(CPyTypeObject)

const PYNULL = pynull()
const PYNULLTYPE = pynulltype()

function unsafe_cacheget!(f, o::PyObject)
    if isnull(o)
        p = f()
        setptr!(PyObjRef(o), ptr(p), true)
    end
    return o
end

safe(o::PyObject) = isnull(o) ? pythrow() : o

### DEFAULT CONVERSION

const PyFloatLike = Union{Float16,Float32,Float64}
const PyComplexLike = Complex{T} where {T<:PyFloatLike}

unsafe_pyobj(T::Type, o::PyObjRef) = PyObject{T}(PyObjRef(o), false)
unsafe_pyobj(T::Type, o) = unsafe_pyobj(T, unsafe_pyobj(o))

unsafe_pyobj(o::PyObjRef) = unsafe_pyobj(CPyObject, o)
unsafe_pyobj(o::PyObject) = o
unsafe_pyobj(o::Nothing) = unsafe_pynone()
unsafe_pyobj(o::Bool) = unsafe_pybool(o)
unsafe_pyobj(o::AbstractString) = unsafe_pystr(o)
unsafe_pyobj(o::Tuple) = unsafe_pytuple_fromiter(o)
unsafe_pyobj(o::Integer) = unsafe_pyint(o)
unsafe_pyobj(o::PyFloatLike) = unsafe_pyfloat(o)
unsafe_pyobj(o::PyComplexLike) = unsafe_pycomplex(o)
unsafe_pyobj(o::AbstractRange{<:Integer}) = unsafe_pyrange(o)
unsafe_pyobj(o::Time) = unsafe_pytime(o)
unsafe_pyobj(o::Date) = unsafe_pydate(o)
unsafe_pyobj(o::DateTime) = unsafe_pydatetime(o)

PyObject(o::PyObject) = o
PyObject(o) = safe(unsafe_pyobj(o))

Base.convert(::Type{T}, o::PyObject) where {T<:PyObject} = T(PyObjRef(o), false)
Base.convert(::Type{T}, o::T) where {T<:PyObject} = o
Base.convert(::Type{PyObject}, o::PyObject) = o
Base.convert(::Type{T}, o) where {T<:PyObject} = Base.convert(T, PyObject(o))
