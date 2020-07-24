unsafe_pycomplex(x::Real) =
    unsafe_pycomplex(x, 0.0)
unsafe_pycomplex(x::CPy_complex) =
    unsafe_pycomplex(x.real, x.imag)
unsafe_pycomplex(x::Complex) =
    unsafe_pycomplex(real(x), imag(x))

function unsafe_pycomplex_convert(::Type{Complex{Cdouble}}, o::PyObject)
    R = ValueOrError{Complex{Cdouble}}
    x = unsafe_pycomplex_realasdouble(o)
    iserr(x) && return R()
    y = unsafe_pycomplex_imagasdouble(o)
    iserr(y) && return R()
    return R(Complex(value(x), value(y)))
end
function unsafe_pycomplex_convert(::Type{T}, o::PyObject) where {T<:Number}
    R = ValueOrError{T}
    x = unsafe_pycomplex_convert(Complex{Cdouble}, o)
    iserr(x) ? R() : R(convert(T, value(x)))
end
pycomplex_convert(::Type{T}, o::PyObject) where {T} =
    safe(unsafe_pycomplex_convert(T, o))
export pycomplex_convert
