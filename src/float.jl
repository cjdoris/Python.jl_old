abstract type AbstractCPyFloatObject <: AbstractCPyObject end

Base.@kwdef struct CPyFloatObject <: AbstractCPyFloatObject
    base :: CPyObject
    value :: Cdouble
end

function unsafe_pyfloat_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    r = unsafe_pyfloat_asdouble(o)::VE{Cdouble}
    if T >: Cdouble
        return convert(VNE, r)
    elseif T <: PyFloatLike
        return convert(VNE{T}, r)
    else
        return tryconvert(T, r)
    end
end

unsafe_pyfloat_convert(::Type{T}, o::AbstractPyRef) where {T<:Real} =
    tryconvtoconv(o, unsafe_pyfloat_tryconvert(T, o))
pyfloat_tryconvert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pyfloat_tryconvert(T, o))
pyfloat_convert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pyfloat_convert(T, o))
export pyfloat_tryconvert, pyfloat_convert
