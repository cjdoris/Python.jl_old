function unsafe_pyint(x::T) where {T<:Integer}
    # see if it fits in a longlong or ulonglong
    if T <: Unsigned
        typemin(Culonglong) ≤ x ≤ typemax(Culonglong) && return unsafe_pyint_fromulonglong(x)
    else
        typemin(Clonglong) ≤ x ≤ typemax(Clonglong) && return unsafe_pyint_fromlonglong(x)
    end
    # otherwise, convert to a string
    if T <: Union{Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Int128, UInt128, BigInt}
        return unsafe_pyint(string(x))
    else
        return unsafe_pyint(string(convert(BigInt, x)))
    end
end

function unsafe_pyint_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    if T >: BigInt
        # try to convert to a longlong
        rl = unsafe_pyint_aslonglong(o)
        if !iserr(rl)
            VNE{BigInt}(Some(convert(BigInt, rl.value)))
        elseif !pyerror_occurred_OverflowError()
            return VNE{BigInt}()
        end
        # otherwise, print it to a string
        rs = unsafe_pystr(String, o)
        if !iserr(rs)
            return VNE{BigInt}(Some(parse(BigInt, rs.value)))
        else
            return VNE{BigInt}()
        end
    elseif T <: Integer
        if T <: Unsigned
            # if it fits in a ulonglong, use that
            rl = unsafe_pyint_asulonglong(o)
            if !iserr(rl)
                return convert(VNE{T}, tryconvert(T, rl.value))
            elseif !pyerror_occurred_OverflowError()
                return VNE{T}()
            elseif T in (UInt8, UInt16, UInt32, UInt64, UInt128) && sizeof(T) ≤ sizeof(Culonglong)
                pyerror_clear()
                return VNE{T}(nothing)
            end
        else
            # if it fits in a longlong, use that
            rl = unsafe_pyint_aslonglong(o)
            if !iserr(rl)
                return convert(VNE{T}, tryconvert(T, rl.value))
            elseif !pyerror_occurred_OverflowError()
                return VNE{T}()
            elseif T in (Int8, Int16, Int32, Int64, Int128) && sizeof(T) ≤ sizeof(Clonglong)
                pyerror_clear()
                return VNE{T}(nothing)
            end
        end
        # otherwise, print it to a string
        rs = unsafe_pystr(String, o)
        if !iserr(rl)
            return convert(VNE{T}, tryconvert(T, parse(BigInt, rs.value)))
        else
            return VNE{T}()
        end
    else
        return tryconvert(T, unsafe_pyint_convert(BigInt, o))
    end
end
unsafe_pyint_convert(::Type{T}, o::AbstractPyRef) where {T} =
    tryconvtoconv(o, unsafe_pyint_tryconvert(T, o))
pyint_tryconvert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pyint_tryconvert(T, o))
pyint_convert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pyint_convert(T, o))
export pyint_tryconvert, pyint_convert
