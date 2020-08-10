ptr(p::Ptr) = p
ptr(p::UnsafePtr) = ptr(pointer(p))

uptr(T::Type, p) = UnsafePtr{T}(ptr(p))
uptr(p) = UnsafePtr(ptr(p))

isnull(p) = ptr(p) == C_NULL

struct ValueOrError{T}
    iserr :: Bool
    value :: T
    ValueOrError{T}() where {T} = new{T}(true)
    ValueOrError{T}(value) where {T} = new{T}(false, convert(T, value))
end

const VE = ValueOrError

iserr(o::ValueOrError) = o.iserr
value(o::ValueOrError) = o.value

Base.convert(::Type{ValueOrError}, x::ValueOrError) = x
Base.convert(::Type{ValueOrError{T}}, x::ValueOrError{T}) where {T} = x
Base.convert(::Type{ValueOrError{T}}, x::ValueOrError) where {T} =
    x.iserr ? ValueOrError{T}() : ValueOrError{T}(x.value)

"""
    @safe unsafe_expr [on_error]

Evaluate `x=unsafe_expr`. If `iserr(x)` then do `on_error` (which defaults to `@goto error`), otherwise evaluate `value(x)`.
"""
macro safe(o, err=:(@goto error))
    :(let o=$(esc(o)); iserr(o) ? $(esc(err)) : value(o); end)
end

"""
    safe(o)

If `iserr(o)` then `pythrow()`, else return `value(o)`.
"""
safe(o) = @safe o pythrow()

"""
    @su f(...) [on_error]

Equivalent to `@safe unsafe_f(...) on_error`. That is, it prefixes `unsafe_` to the function call.
"""
macro su(o, err=:(@goto error))
    if o isa Expr && o.head == :call
        u = Expr(:call, Symbol(:unsafe_, o.args[1]), o.args[2:end]...)
    else
        error("@su expects a function call")
    end
    return :(@safe $(esc(u)) $(esc(err)))
end



struct ValueOrNothing{T}
    isnothing :: Bool
    value :: T
    ValueOrNothing{T}() where {T} = new{T}(true)
    ValueOrNothing{T}(value) where {T} = new{T}(false, convert(T, value))
end

const VN = ValueOrNothing

struct ValueOrNothingOrError{T}
    iserr :: Bool
    isnothing :: Bool
    value :: T
    ValueOrNothingOrError{T}() where {T} = new{T}(true, false)
    ValueOrNothingOrError{T}(::Nothing) where {T} = new{T}(false, true)
    ValueOrNothingOrError{T}(value) where {T} = new{T}(false, false, convert(T, something(value)))
end

const VNE = ValueOrNothingOrError

Base.convert(::Type{ValueOrNothingOrError}, x::ValueOrError{T}) where {T} =
    Base.convert(ValueOrNothingOrError{T}, x)
Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrError) where {T} =
    iserr(x) ? ValueOrNothingOrError{T}() : ValueOrNothingOrError{T}(Some(x.value))

Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrNothingOrError{T}) where {T} =
    x
Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrNothingOrError) where {T} =
    x.iserr ? ValueOrNothingOrError{T}() : x.isnothing ? ValueOrNothingOrError{T}(nothing) : ValueOrNothingOrError{T}(Some(x.value))

Base.convert(::Type{ValueOrNothingOrError}, x::ValueOrNothing{T}) where {T} =
    convert(ValueOrNothingOrError{T}, x)
Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrNothing) where {T} =
    x.isnothing ? ValueOrNothingOrError{T}(nothing) : ValueOrNothingOrError{T}(Some(x.value))

iserr(o::ValueOrNothingOrError) = o.iserr
value(o::ValueOrNothingOrError{T}) where {T} = o.isnothing ? nothing : Some{T}(o.value)

function nothingtoerror(f, r::ValueOrNothingOrError{T}) where {T}
    R = ValueOrError{T}
    if r.iserr
        return R()
    elseif r.isnothing
        f()
        return R()
    else
        return R(r.value)
    end
end

nothingtoerror(r::ValueOrNothingOrError) = nothingtoerror(()->nothing, r)


"""
    pointer_from_obj(o)

A pair `(p,c)` so that `Base.unsafe_pointer_to_objref(p)===o`, provided that `c` is not garbage collected.
"""
function pointer_from_obj(o::T) where {T}
    if T.mutable
        c = o
        p = Base.pointer_from_objref(o)
    else
        c = Ref{Any}(o)
        p = unsafe_load(Ptr{Ptr{Cvoid}}(Base.pointer_from_objref(c)))
    end
    p, c
end

# @generated function cfunction(func, ::Type{R}, ::Type{T}) where {R,T}
#     :(@cfunction($(Expr(:$, :func)), $R, ($(T.parameters...),)))
# end

"""
    tryconvert(T, x)

A `ValueOrNothing{T}` containing the value `x` converted to a `T` if possible, otherwise containing `nothing`.

If `x` is a `ValueOrNothing`, `ValueOrError` or `ValueOrNothingOrError`, then nothings and errors are passed through and `tryconvert` is called on any value.

The default implementation calls `convert(T, x)`, interprets any exceptions `e` such that `isfailedconversion(e, T, x)` as a failed conversion, and rethrows any other exceptions.
"""
tryconvert(::Type{T}, x) where {T} =
    try
        VN{T}(convert(T, x))
    catch err
        if isfailedconversion(err, T, x)
            return VN{T}()
        else
            rethrow()
        end
    end

tryconvert(::Type{T}, x::ValueOrNothingOrError) where {T} =
    x.iserr ? VNE{T}() : x.isnothing ? VNE{T}(nothing) : convert(VNE{T}, tryconvert(T, x.value))
tryconvert(::Type{T}, x::ValueOrError) where {T} =
    x.iserr ? VNE{T}() : convert(VNE{T}, tryconvert(T, x.value))
tryconvert(::Type{T}, x::ValueOrNothing) where {T} =
    x.isnothing ? VN{T}() : tryconvert(T, x.value)

tryconvert(::Type{T}, x::S) where {T, S<:T} = VN{T}(x)

for T in (Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Int128, UInt128)
    @eval tryconvert(::Type{$T}, x::Integer) =
        $(typemin(T)) ≤ x ≤ $(typemax(T)) ? VN{$T}(x) : VN{$T}()
    @eval tryconvert(::Type{$T}, x::$T) = VN{$T}(x)
end

tryconvert(::Type{BigInt}, x::Integer) = VN{BigInt}(x)

isfailedconversion(err, ::Type{T}, x) where {T} =
    isfailedconversion(err, T, T, x)

isfailedconversion(err, ::Type{T}, ::Type{Any}, x) where {T} =
    err isa MethodError && err.f === convert && err.args === (T, x)
isfailedconversion(err, ::Type{T}, ::Type{S}, x) where {T,S} =
    isfailedconversion(err, T, supertype(S), x)

isfailedconversion(err, ::Type{T}, ::Type{Number}, x::Number) where {T} =
    err isa InexactError || isfailedconversion(err, T, supertype(Number), x)


islittleendian() =
    Base.ENDIAN_BOM == 0x04030201 ? true  :
    Base.ENDIAN_BOM == 0x01020304 ? false :
    error("cannot determine endianness")

make_f_contig_strides(elsz) = ()
make_f_contig_strides(elsz, sz1, sz...) = (elsz, (sz1 .* make_f_contig_strides(elsz, sz...))...)

make_c_contig_strides(elsz, sz...) = reverse(make_f_contig_strides(elsz, reverse(sz)...))

"""
    PaddingBytes{N}

An object of size `N` representing nothing. Used to represent the padding between elements of a struct.
"""
struct PaddingBytes{N}
    bytes :: NTuple{N,UInt8}
end

"""
    ByteReversed{T}

A `T` but whose bytes are reversed.
"""
struct ByteReversed{T}
    reversed :: T
end

"""
    PascalString{N}

A Pascal-style string of length at most `N-1`.

The first byte is the length of the string and the remaining bytes are the contents.
"""
struct PascalString{N}
    bytes :: NTuple{N,UInt8}
end

"""
    NumpyDatetime64{unit}

A `numpy.datetime64` with the given `unit` (e.g. `:D` for days or `:ns` for nanoseconds).
"""
struct NumpyDatetime64{unit}
    value :: Int64
end

"""
    NumpyTimedelta64{unit}

A `numpy.timedelta64` with the given `unit` (e.g. `:D` for days or `:ns` for nanoseconds).
"""
struct NumpyTimedelta64{unit}
    value :: Int64
end

@generated function unwrap_unionall(::Type{T}) where T
    # unwrap type variables
    vars = []
    S = T
    while S isa UnionAll
        push!(vars, S.var)
        S = S.body
    end
    return S, Tuple(reverse(vars))
end

@generated function extract_union(::Type{T}) where T
    S, vars = unwrap_unionall(T)
    if S isa Union
        A = S.a
        B = S.b
        for v in vars
            A = UnionAll(v, A)
            B = UnionAll(v, B)
        end
        return Union{A, B}
    end
    return T
end

@generated function extract_pairtype(::Type{T}) where T
    S, vars = unwrap_unionall(T)
    A, B = S.parameters
    for v in vars
        A = UnionAll(v, A)
        B = UnionAll(v, B)
    end
    return Pair{A,B}
end

@generated function extract_tupletype(::Type{T}) where T
    S, vars = unwrap_unionall(T)
    params = S.parameters
    for v in vars
        params = [UnionAll(v, p) for p in params]
    end
    return Tuple{params...}
end

@generated function extract_unitrangetype(::Type{T}) where T
    S, vars = unwrap_unionall(T)
    A = S.parameters[1]
    for v in vars
        A = UnionAll(v, A)
    end
    return UnitRange{A}
end

@generated function extract_steprangetype(::Type{T}) where T
    S, vars = unwrap_unionall(T)
    A = S.parameters[1]
    B = S.parameters[2]
    for v in vars
        A = UnionAll(v, A)
        B = UnionAll(v, B)
    end
    return StepRange{A, B}
end
