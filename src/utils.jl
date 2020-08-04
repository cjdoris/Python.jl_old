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

iserr(o::ValueOrError) = o.iserr
value(o::ValueOrError) = o.value

Base.convert(::Type{ValueOrError}, x::ValueOrError) = x
Base.convert(::Type{ValueOrError{T}}, x::ValueOrError{T}) where {T} = x
Base.convert(::Type{ValueOrError{T}}, x::ValueOrError) where {T} =
    x.iserr ? ValueOrError{T}() : ValueOrError{T}(x.value)

macro safeor(o, err)
    :(let o=$(esc(o)); iserr(o) ? $(esc(err)) : value(o); end)
end

macro safe(o)
    :(@safeor $(esc(o)) $(esc(:(@goto error))))
end

safe(o) = @safeor o pythrow()


struct ValueOrNothingOrError{T}
    iserr :: Bool
    isnothing :: Bool
    value :: T
    ValueOrNothingOrError{T}() where {T} = new{T}(true, false)
    ValueOrNothingOrError{T}(::Nothing) where {T} = new{T}(false, true)
    ValueOrNothingOrError{T}(value) where {T} = new{T}(false, false, convert(T, something(value)))
end

Base.convert(::Type{ValueOrNothingOrError}, x::ValueOrError{T}) where {T} =
    Base.convert(ValueOrNothingOrError{T}, x)
Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrError) where {T} =
    iserr(x) ? ValueOrNothingOrError{T}() : ValueOrNothingOrError{T}(Some(x.value))
Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrNothingOrError{T}) where {T} =
    x
Base.convert(::Type{ValueOrNothingOrError{T}}, x::ValueOrNothingOrError) where {T} =
    x.iserr ? ValueOrNothingOrError{T}() : x.isnothing ? ValueOrNothingOrError{T}(nothing) : ValueOrNothingOrError{T}(Some(x.value))

iserr(o::ValueOrNothingOrError) = o.iserr
value(o::ValueOrNothingOrError) = o.isnothing ? nothing : Some(o.value)

"""
    pointer_from_obj(o)

A pair `(p,c)` so that `Base.unsafe_pointer_to_objref(p)===o`, provided that `c` is not garbage collected.
"""
function pointer_from_obj(o)
    if isimmutable(o)
        c = Ref{Any}(o)
        p = unsafe_load(Ptr{Ptr{Cvoid}}(Base.pointer_from_objref(c)))
    else
        c = o
        p = Base.pointer_from_objref(o)
    end
    p, c
end

@generated function cfunction(func, ::Type{R}, ::Type{T}) where {R,T}
    :(@cfunction($(Expr(:$, :func)), $R, ($(T.parameters...),)))
end


# macro cpycall(ex)
#     ex isa Expr && ex.head == :(::) && length(ex.args) == 2 || @goto err
#     ex, rettype = ex.args
#     rettype = @eval($rettype)
#     ex isa Expr && ex.head == :call || @goto err
#     fname = esc(ex.args[1])
#     args = []
#     for ex in ex.args[2:end]
#         ex isa Expr && ex.head == :(::) && length(ex.args) == 2 || @goto err
#         x, t = ex.args
#         push!(args, (gensym(), gensym(), esc(x), @eval($t)))
#     end
#     return quote
#         let $([:($n = Base.cconvert($t, $x)) for (n,u,x,t) in args]...)
#             Base.GC.@preserve $([n for (n,u,x,t) in args]...) begin
#                 let $([:($u = Base.unsafe_convert($t, $n)) for (n,u,x,t) in args]...)
#                     a = ccall(($fname, PYLIB), $(cpycall_ctype(rettype)), ($([cpycall_ctype(t) for (n,u,x,t) in args]...),), $([:(cpycall_toc($u)) for (n,u,x,t) in args]...))
#                     a = cpycall_fromc($rettype, a)
#                     if iserr(a)
#                         $([:(cpycall_errhook($u)) for (n,u,x,t) in args]...)
#                     end
#                     cpycall_returnhook(a)
#                 end
#             end
#         end
#     end
#     @label err
#     error("expecting `@cpycall PyFunction(x::T, ...)::R`")
# end

# macro cpyobject(name)
#     quote
#         CPyBorrowedPtr(cglobal(($(esc(name)), PYLIB), CPyObject))
#     end
# end

# macro unsafe_cacheget_object(cache, name)
#     quote
#         unsafe_cacheget!($(esc(cache))) do
#             @cpyobject $(esc(name))
#         end
#     end
# end

# macro cpyobjectptr(name)
#     quote
#         CPyBorrowedPtr(unsafe_load(cglobal(($(esc(name)), PYLIB), PyPtr)))
#     end
# end

# macro unsafe_cacheget_objectptr(cache, name)
#     quote
#         unsafe_cacheget!($(esc(cache))) do
#             @cpyobjectptr $(esc(name))
#         end
#     end
# end
