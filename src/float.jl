abstract type AbstractCPyFloatObject <: AbstractCPyObject end

Base.@kwdef struct CPyFloatObject <: AbstractCPyFloatObject
    base :: CPyObject
    value :: Cdouble
end

unsafe_pyfloat_convert(::Type{Cdouble}, o::PyObject) =
    unsafe_pyfloat_asdouble(o)
function unsafe_pyfloat_convert(::Type{T}, o::PyObject) where {T<:Number}
    x = unsafe_pyfloat_convert(Cdouble, o)
    R = ValueOrError{T}
    return iserr(x) ? R() : R(convert(T, value(x)))
end
pyfloat_convert(T::Type, o::PyObject) = safe(unsafe_pyfloat_convert(T, o))
export pyfloat_convert
