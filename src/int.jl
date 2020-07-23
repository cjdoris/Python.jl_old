const _pyinttype = pynulltype()
unsafe_pyinttype() = @unsafe_cacheget_object _pyinttype :PyLong_Type
pyinttype() = safe(unsafe_pyinttype())
export pyinttype

for T in [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128]
    u = T <: Unsigned
    fromfunc = QuoteNode(u ? :PyLong_FromUnsignedLongLong : :PyLong_FromLongLong)
    asfunc = QuoteNode(u ? :PyLong_AsUnsignedLongLong : :PyLong_AsLongLong)
    ctype = u ? Culonglong : Clonglong
    R = CPyAmbigNumber{T}
    if sizeof(T) ≤ sizeof(Clonglong)
        @eval unsafe_pyint(x::$T) = @cpycall $fromfunc(x::$ctype)::CPyNewPtr
        @eval function unsafe_pyint_convert(::Type{$T}, o::PyObject)
            r = @cpycall $asfunc(o::CPyPtr)::CPyAmbigNumber{$ctype}
            if iserr(r)
                if $(sizeof(T) > sizeof(ctype))
                    error("not implemented")
                else
                    return $R()
                end
            elseif $(typemin(T)) ≤ value(r) ≤ $(typemax(T))
                return $R(convert($T, value(r)))
            else
                pyerror_set(pyerror_OverflowError())
                return $R()
            end
        end
    end
end

unsafe_pyint(x::Integer) = unsafe_pyint(convert(BigInt, x))
function unsafe_pyint(x::BigInt)
    error("not implemented")
end
unsafe_pyint(args...; kwargs...) = unsafe_pycall_args(unsafe_pyinttype(), args, kwargs)
pyint(args...; kwargs...) = safe(unsafe_pyint(args...; kwargs...))
export pyint

function unsafe_pyint_convert(::Type{T}, o::PyObject) where {T<:Integer}
    x = unsafe_pyint_convert(BigInt, o)
    R = CPyAmbigNumber{T}
    if iserr(x)
        return R()
    elseif typemin(T) ≤ value(x) ≤ typemax(T)
        return R(convert(T, value(x)))
    else
        pyerror_set(pyerror_OverflowError())
        return R()
    end
end
function unsafe_pyint_convert(::Type{BigInt}, o::PyObject)
    x = unsafe_pystr(String, o)
    R = CPyAmbigNumber{BigInt}
    if iserr(x)
        return R()
    else
        return R(parse(BigInt, value(x)))
    end
end
function unsafe_pyint_convert(::Type{T}, o::PyObject) where {T<:Number}
    R = CPyAmbigNumber{T}
    x = unsafe_pyint_convert(Int, o)
    if !iserr(x)
        return R(convert(T, value(x)))
    elseif !pyerror_occurred(pyerror_OverflowError())
        return R()
    end
    x = unsafe_pyint_convert(BigInt, o)
    if !iserr(x)
        return R(convert(T, value(x)))
    else
        return R()
    end
end
pyint_convert(args...) = safe(unsafe_pyint_convert(args...))
export pyint_convert
