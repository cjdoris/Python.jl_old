ptr(p::Ptr) = p
ptr(p::UnsafePtr) = ptr(pointer(p))

uptr(T::Type, p) = UnsafePtr(T, ptr(p))
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

safe(o) = iserr(o) ? pythrow() : value(o)

struct ValueOrNothingOrError{T}
    iserr :: Bool
    isnothing :: Bool
    value :: T
    ValueOrNothingOrError{T}() where {T} = new{T}(true, false)
    ValueOrNothingOrError{T}(::Nothing) where {T} = new{T}(false, true)
    ValueOrNothingOrError{T}(value) where {T} = new{T}(false, false, convert(T, something(value)))
end

iserr(o::ValueOrNothingOrError) = o.iserr
value(o::ValueOrNothingOrError) = o.isnothing ? nothing : Some(o.value)


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
#         CPyBorrowedPtr(unsafe_load(cglobal(($(esc(name)), PYLIB), Ptr{CPyObject})))
#     end
# end

# macro unsafe_cacheget_objectptr(cache, name)
#     quote
#         unsafe_cacheget!($(esc(cache))) do
#             @cpyobjectptr $(esc(name))
#         end
#     end
# end
