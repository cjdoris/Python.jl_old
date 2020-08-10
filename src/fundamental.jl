### AbstractPyObject
# Abstract type for Python objects with Python semantics.
# They must have a `ref` field containing a `PyRef`.
# Currently there is only one subtype, `PyObject`, but other subtypes could
# implement other functionality, such as:
# - keeping track of the Python type
# - having conversion policies different from the default (e.g. prefer numpy types)

abstract type AbstractPyObject{T} <: AbstractPyRef{T} end

PyRef(o::AbstractPyObject) = getfield(o, :ref)
ptr(o::AbstractPyObject) = ptr(PyRef(o))
nullify!(o::AbstractPyObject) = (nullify!(PyRef(o)); o)

function unsafe_cacheget!(f, o::AbstractPyObject)
    if isnull(o)
        p = f()
        setptr!(PyRef(o), ptr(p), true)
    end
    return o
end

### PyObject

struct PyObject <: AbstractPyObject{CPyObject}
    ref :: PyRef
    function PyObject(ref::PyRef, check::Bool=true)
        check && isnull(ref) && pythrow()
        new(ref)
    end
end
export PyObject

pynull() = PyObject(PyRef(), false)

const PYNULL = pynull()



### DEFAULT CONVERSION

const PyFloatLike = Union{Float16,Float32,Float64}
const PyComplexLike = Complex{T} where {T<:PyFloatLike}

const AnyRational = Union{Rational, Integer}
const AnyComplex = Union{Complex, Real}

unsafe_pyobj(o::PyObject) = o
unsafe_pyobj(o::PyRef) = PyObject(o, false)
unsafe_pyobj(o::AbstractPyRef) = unsafe_pyobj(PyRef(o))
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
unsafe_pyobj(o::IO) = unsafe_pybufferedio(o)
unsafe_pyobj(o::NumpyDatetime64{unit}) where {unit} = unsafe_pyimportattrcall("numpy", "datetime64", o.value, string(unit))
unsafe_pyobj(o::NumpyTimedelta64{unit}) where {unit} = unsafe_pyimportattrcall("numpy", "timedelta64", o.value, string(unit))
unsafe_pyobj(o) = unsafe_pyjulia(o)

PyObject(o::PyObject) = o
PyObject(o) = safe(unsafe_pyobj(o))

Base.convert(::Type{PyObject}, o::PyObject) = o
Base.convert(::Type{PyObject}, o) = PyObject(o)
