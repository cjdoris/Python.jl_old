Base.@kwdef struct CPy_complex
    real :: Cdouble = 0
    imag :: Cdouble = 0
end

abstract type AbstractCPyComplexObject <: AbstractCPyObject end

Base.@kwdef struct CPyComplexObject <: AbstractCPyComplexObject
    base :: CPyObject
    value :: CPy_complex
end

const _pycomplextype = pynulltype()
unsafe_pycomplextype() = @unsafe_cacheget_object _pycomplextype :PyComplex_Type
pycomplextype() = safe(unsafe_pycomplextype())
export pycomplextype

unsafe_pycomplex(x::Real, y::Real=0.0) =
    @cpycall :PyComplex_FromDoubles(x::Cdouble, y::Cdouble)::CPyNewPtr
unsafe_pycomplex(x::CPy_complex) =
    unsafe_pycomplex(x.real, x.imag)
unsafe_pycomplex(x::Complex) =
    unsafe_pycomplex(real(x), imag(x))
unsafe_pycomplex(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pycomplextype(), args, kwargs)
pycomplex(args...; kwargs...) =
    safe(unsafe_pycomplex(args...; kwargs...))
export pycomplex

function unsafe_pycomplex_convert(::Type{Complex{Cdouble}}, o::PyObject)
    R = CPyAmbigNumber{Complex{Cdouble}}
    x = @cpycall :PyComplex_RealAsDouble(o::CPyPtr)::CPyAmbigNumber{Cdouble}
    iserr(x) && return R()
    y = @cpycall :PyComplex_ImagAsDouble(o::CPyPtr)::CPyAmbigNumber{Cdouble}
    iserr(y) && return R()
    return R(Complex(value(x), value(y)))
end
function unsafe_pycomplex_convert(::Type{T}, o::PyObject) where {T<:Number}
    R = CPyAmbigNumber{T}
    x = unsafe_pycomplex_convert(Complex{Cdouble}, o)
    iserr(x) ? R() : R(convert(T, value(x)))
end
pycomplex_convert(::Type{T}, o::PyObject) where {T} =
    safe(unsafe_pycomplex_convert(T, o))
export pycomplex_convert
