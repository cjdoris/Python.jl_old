const _pyinttype = pynulltype()
unsafe_pyinttype() = @unsafe_cacheget_object _pyinttype :PyLong_Type
pyinttype() = safe(unsafe_pyinttype())
export pyinttype

for T in [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128]
    u = T <: Unsigned
    fromfunc = QuoteNode(u ? :PyLong_FromUnsignedLongLong : :PyLong_FromLongLong)
    asfunc = QuoteNode(u ? :PyLong_AsUnsignedLongLong : :PyLong_AsLongLong)
    ctype = u ? Culonglong : Clonglong
    if sizeof(T) ≤ sizeof(Clonglong)
        @eval unsafe_pyint(x::$T) = @cpycall $fromfunc(x::$ctype)::CPyNewPtr
        @eval function unsafe_pyint_convert(::Type{$T}, o::PyObject)
            r = @cpycall $asfunc(o::CPyPtr)::CPyInteger{$ctype}
            if iserr(r)
                if $(sizeof(T) > sizeof(ctype))
                    error("not implemented")
                else
                    return CPyInteger{$T}()
                end
            elseif $(typemin(T)) ≤ value(r) ≤ $(typemax(T))
                return CPyInteger{$T}(convert($T, value(r)))
            else
                pyerror_set(pyerror_OverflowError())
                return CPyInteger{$T}()
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
    if iserr(x)
        return CPyInteger{T}()
    elseif typemin(T) ≤ value(x) ≤ typemax(T)
        return CPyInteger{T}(convert(T, value(x)))
    else
        pyerror_set(pyerror_OverflowError())
        return CPyInteger{T}()
    end
end
function unsafe_pyint_convert(::Type{BigInt}, o::PyObject)
    x = unsafe_pystr(String, o)
    if iserr(x)
        return CPyInteger{BigInt}()
    else
        return CPyInteger{BigInt}(parse(BigInt, value(x)))
    end
end
unsafe_pyint_convert(T::Type, o) = unsafe_pyint_convert(T, unsafe_pyobj(o))
pyint_convert(args...) = safe(unsafe_pyint_convert(args...))
export pyint_convert
