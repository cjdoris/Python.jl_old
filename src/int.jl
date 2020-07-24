for T in [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128]
    u = T <: Unsigned
    fromfunc = u ? :unsafe_pyint_fromulonglong : :unsafe_pyint_fromlonglong
    asfunc = u ? :unsafe_pyint_asulonglong : :unsafe_pyint_aslonglong
    ctype = u ? Culonglong : Clonglong
    if sizeof(T) ≤ sizeof(Clonglong)
        @eval unsafe_pyint(x::$T) = $fromfunc(x)
        @eval function unsafe_pyint_convert(::Type{$T}, o::PyObject)
            R = ValueOrError{$T}
            r = $asfunc(o)
            if iserr(r)
                if $(sizeof(T) > sizeof(ctype)) && pyerror_occurred_OverflowError()
                    x = unsafe_pyint_convert(BigInt, o)
                    if iserr(x)
                        return R()
                    else
                        return R(convert($T, value(x)))
                    end
                else
                    return R()
                end
            else
                return R(convert($T, value(r)))
            end
        end
    end
end

unsafe_pyint(x::Integer) = unsafe_pyint(convert(BigInt, x))
unsafe_pyint(x::BigInt) = unsafe_pyint(string(x))

function unsafe_pyint_convert(::Type{T}, o::PyObject) where {T<:Integer}
    x = unsafe_pyint_convert(BigInt, o)
    R = ValueOrError{T}
    if iserr(x)
        return R()
    else
        return R(convert(T, value(x)))
    end
end
function unsafe_pyint_convert(::Type{BigInt}, o::PyObject)
    x = unsafe_pystr(String, o)
    R = ValueOrError{BigInt}
    if iserr(x)
        return R()
    else
        return R(parse(BigInt, value(x)))
    end
end
function unsafe_pyint_convert(::Type{T}, o::PyObject) where {T<:Number}
    R = ValueOrError{T}
    x = unsafe_pyint_convert(Int, o)
    if !iserr(x)
        return R(convert(T, value(x)))
    elseif !pyerror_occurred_OverflowError()
        return R()
    end
    pyerror_clear()
    x = unsafe_pyint_convert(BigInt, o)
    if !iserr(x)
        return R(convert(T, value(x)))
    else
        return R()
    end
end
pyint_convert(args...) = safe(unsafe_pyint_convert(args...))
export pyint_convert
