abstract type AbstractCPyRangeObject <: AbstractCPyObject end

Base.@kwdef struct CPyRangeObject <: AbstractCPyRangeObject
    base :: CPyObject = CPyObject()
    start :: PyPtr = C_NULL
    stop :: PyPtr = C_NULL
    step :: PyPtr = C_NULL
end

_unsafe_pyrange_start(o::AbstractPyRef) = PyBorrowedRef(uptr(CPyRangeObject, o).start[])
_unsafe_pyrange_stop(o::AbstractPyRef) = PyBorrowedRef(uptr(CPyRangeObject, o).stop[])
_unsafe_pyrange_step(o::AbstractPyRef) = PyBorrowedRef(uptr(CPyRangeObject, o).step[])

function unsafe_pyrange_tryconvert(::Type{StepRange{T,S}}, o::AbstractPyRef) where {T<:Integer, S<:Integer}
    R = VNE{StepRange{T,S}}
    a = unsafe_pyint_tryconvert(T, _unsafe_pyrange_start(o))
    a.iserr ? (return R()) : a.isnothing ? (return R(nothing)) : nothing
    b = unsafe_pyint_tryconvert(T, _unsafe_pyrange_stop(o))
    b.iserr ? (return R()) : b.isnothing ? (return R(nothing)) : nothing
    c = unsafe_pyint_tryconvert(S, _unsafe_pyrange_step(o))
    c.iserr ? (return R()) : c.isnothing ? (return R(nothing)) : nothing
    return R(Some(StepRange{T,S}(a.value, c.value, b.value - oftype(b.value, sign(c.value)))))
end

unsafe_pyrange_tryconvert(::Type{T}, o::AbstractPyRef) where {T<:StepRange{<:Integer, <:Integer}} =
    convert(VNE{T}, unsafe_pyrange_tryconvert(extract_steprangetype(T), o))

function unsafe_pyrange_tryconvert(::Type{UnitRange{T}}, o::AbstractPyRef) where {T<:Integer}
    R = VNE{UnitRange{T}}
    r = unsafe_pyrange_tryconvert(StepRange{T,T}, o)
    if r.iserr
        R()
    elseif r.isnothing
        R(nothing)
    elseif isone(step(r.value))
        R(Some(UnitRange{T}(first(r.value), last(r.value))))
    else
        R(nothing)
    end
end

unsafe_pyrange_tryconvert(::Type{T}, o::AbstractPyRef) where {T<:UnitRange{<:Integer}} =
    convert(VNE{T}, unsafe_pyrange_tryconvert(extract_unitrangetype(T), o))

@generated _typeintersect(::Type{T}, ::Type{S}) where {T,S} = typeintersect(T, S)

function unsafe_pyrange_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    if (S = _typeintersect(T, StepRange{BigInt, BigInt})) !== Union{}
        return unsafe_pyrange_tryconvert(S, o)
    elseif (S = _typeintersect(T, StepRange{<:Integer, <:Integer})) !== Union{}
        return unsafe_pyrange_tryconvert(S, o)
    elseif (S = _typeintersect(T, UnitRange{BigInt})) !== Union{}
        return unsafe_pyrange_tryconvert(S, o)
    elseif (S = _typeintersect(T, UnitRange{<:Integer})) !== Union{}
        return unsafe_pyrange_tryconvert(S, o)
    elseif (S = _typeintersect(T, AbstractVector{BigInt})) !== Union{}
        return unsafe_pyabstractsequence_tryconvert(S, o)
    elseif (S = _typeintersect(T, AbstractVector{<:Integer})) !== Union{}
        return unsafe_pyabstractsequence_tryconvert(S, o)
    else
        return unsafe_pyabstractsequence_tryconvert(T, o)
    end
end
