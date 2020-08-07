function unsafe_pyabstractiterable_tryconvert(::Type{T}, o::AbstractPyRef, subs::Bool=true) where {T}
    R = VNE{T}
    if subs
        if @safe unsafe_pyisabstractmapping(o)
            return convert(R, unsafe_pyabstractmapping_tryconvert(T, o))
        elseif @safe unsafe_pyisabstractsequence(o)
            return convert(R, unsafe_pyabstractsequence_tryconvert(T, o))
        elseif @safe unsafe_pyisabstractset(o)
            return convert(R, unsafe_pyabstractset_tryconvert(T, o))
        end
    end
    it = @safe unsafe_pyiter(o)
    return convert(R, unsafe_pyiter_tryconvert(T, it))
    @label error
    return R()
end

unsafe_pyabstractsequence_tryconvert(::Type{T}, o::AbstractPyRef, subs::Bool=true) where {T} =
    unsafe_pyabstractiterable_tryconvert(T, o, false)

unsafe_pyabstractset_tryconvert(::Type{T}, o::AbstractPyRef, subs::Bool=true) where {T} =
    unsafe_pyabstractiterable_tryconvert(T, o, false)

_keytype(::Type{T}) where {T} = keytype(T)
_keytype(::Type{T}) where {T<:AbstractDict} = Any
_keytype(::Type{T}) where {K, T<:AbstractDict{K}} = K

_valtype(::Type{T}) where {T} = valtype(T)
_valtype(::Type{T}) where {T<:AbstractDict} = Any
_valtype(::Type{T}) where {V, T<:AbstractDict{K,V} where K} = V

_eltype(::Type{T}) where {T} = eltype(T)
_eltype(::Type{T}) where {T<:AbstractDict} = (K=_keytype(T); V=_valtype(T); isconcretetype(K) ? isconcretetype(V) ? Pair{K,V} : Pair{K,<:V} : isconcretetype(V) ? Pair{<:K,V} : Pair{<:K,<:V})

function unsafe_pyabstractmapping_tryconvert(::Type{T}, o::AbstractPyRef, subs::Bool=true) where {T}
    R = VNE{T}
    if (S = typeintersect(T, Dict)) !== Union{}
        return unsafe_pyiter_tryappend!(S(), @su pyiter(@su pycall(@su pygetattr(o, "items"))))
    else
        # TODO: tryconvert
        return R(nothing)
    end
    @label error
    return R()
end
