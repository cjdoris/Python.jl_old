function unsafe_pyiter_tryappend!(xs, o::AbstractPyRef)
    R = VNE{typeof(xs)}
    Base.GC.@preserve o while true
        xo = unsafe_pyiter_next(o)
        if !isnull(xo)
            x = unsafe_pytryconvertvalue(xs, xo)
            if x.iserr
                return R()
            elseif x.isnothing
                return R(nothing)
            else
                push!(xs, x.value)
            end
        elseif pyerror_occurred()
            return R()
        else
            return R(Some(xs))
        end
    end
end

@generated function unsafe_pyiter_tryconvert(::Type{T}, o::AbstractPyRef) where {T<:Tuple}
    # ts are the fixed types
    # if T is variable length, V is the variable type, otherwise V is nothing
    ts = extract_tupletype(T).parameters
    V = nothing
    if Base.isvarargtype(ts[end])
        isvar = true
        V0, vars = unwrap_unionall(ts[end])
        V = V0.parameters[1]
        for v in vars
            V = UnionAll(v, V)
        end
        ts = ts[1:end-1]
    end

    # generate code for the fixed types
    code = Expr[]
    syms = Symbol[]
    push!(code, :(R = VNE{T}))
    for t in ts
        x = gensym()
        y = gensym()
        push!(syms, y)
        push!(code, quote
            $x = unsafe_pyiter_next(o)
            if !isnull($x)
                $y = unsafe_pytryconvert($t, $x)
                if $y.iserr
                    return R()
                elseif $y.isnothing
                    return R(nothing)
                end
            elseif pyerror_occurred()
                return R()
            else
                return R(nothing)
            end
        end)
    end

    if V === nothing
        # no varargs
        # check there are no more items
        push!(code, quote
            x = unsafe_pyiter_next(o)
            if !isnull(x)
                return R(nothing)
            elseif pyerror_occurred()
                return R()
            end
            return R(Some(tuple($([:($x.value) for x in syms]...))))
        end)
    else
        # varargs
        push!(code, quote
            vs = $V[]
            while true
                x = unsafe_pyiter_next(o)
                if !isnull(x)
                    y = unsafe_pytryconvert($V, x)
                    if y.iserr
                        return R()
                    elseif y.isnothing
                        return R(nothing)
                    else
                        push!(vs, y.value)
                    end
                elseif pyerror_occurred()
                    return R()
                else
                    break
                end
            end
            return R(Some(tuple($([:($x.value) for x in syms]...), vs...)))
        end)
    end

    code = Expr(:block, code...)
    return code
end

function unsafe_pyiter_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    if (S = typeintersect(T, Vector)) !== Union{}
        return unsafe_pyiter_tryappend!(S(), o)
    elseif (S = typeintersect(T, Set)) !== Union{}
        return unsafe_pyiter_tryappend!(S(), o)
    elseif (S = typeintersect(T, Pair)) !== Union{}
        S0 = extract_pairtype(S)
        r = unsafe_pyiter_tryconvert(Tuple{S0.parameters[1], S0.parameters[2]}, o)
        return r.iserr ? VNE{S}() : r.isnothing ? VNE{S}(nothing) : VNE{S}(Some(Pair(r.value[1], r.value[2])))
    else
        return VNE{T}(nothing)
    end
end
