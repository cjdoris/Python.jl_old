unsafe_pycomplex(x::Real) =
    unsafe_pycomplex(x, 0.0)
unsafe_pycomplex(x::CPy_complex) =
    unsafe_pycomplex(x.real, x.imag)
unsafe_pycomplex(x::Complex) =
    unsafe_pycomplex(real(x), imag(x))

function unsafe_pycomplex_ascomplex(o::AbstractPyRef)
    R = VE{Complex{Cdouble}}
    x = unsafe_pycomplex_realasdouble(o)
    x.iserr && return R()
    y = unsafe_pycomplex_imagasdouble(o)
    y.iserr && return R()
    return R(Complex(x.value, y.value))
end

function unsafe_pycomplex_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    r = unsafe_pycomplex_ascomplex(o)::VE{Complex{Cdouble}}
    if T >: Complex{Cdouble}
        return convert(VNE, r)
    elseif T <: Complex{<:PyFloatLike}
        return convert(VNE{T}, r)
    else
        return tryconvert(T, r)
    end
end
