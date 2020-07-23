abstract type AbstractCPyFloatObject <: AbstractCPyObject end

Base.@kwdef struct CPyFloatObject <: AbstractCPyFloatObject
    base :: CPyObject
    value :: Cdouble
end

const _pyfloattype = pynulltype()
unsafe_pyfloattype() = @unsafe_cacheget_object _pyfloattype :PyFloat_Type
pyfloattype() = safe(unsafe_pyfloattype())
export pyfloattype

unsafe_pyfloat(o::Real) =
    @cpycall :PyFloat_FromDouble(o::Cdouble)::CPyNewPtr
unsafe_pyfloat(args...; kwargs...) = unsafe_pycall_args(unsafe_pyfloattype(), args, kwargs)
pyfloat(args...; kwargs...) = safe(unsafe_pyfloat(args...; kwargs...))
export pyfloat

unsafe_pyfloat_convert(::Type{Cdouble}, o::PyObject) =
    @cpycall :PyFloat_AsDouble(o::CPyPtr)::CPyAmbigNumber{Cdouble}
function unsafe_pyfloat_convert(::Type{T}, o::PyObject) where {T<:Number}
    x = unsafe_pyfloat_convert(Cdouble, o)
    R = CPyAmbigNumber{T}
    return iserr(x) ? R() : R(convert(T, value(x)))
end
pyfloat_convert(T::Type, o::PyObject) = safe(unsafe_pyfloat_convert(T, o))
export pyfloat_convert
