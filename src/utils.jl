ptr(p::Ptr) = p
ptr(p::UnsafePtr) = ptr(pointer(p))

uptr(T::Type, p::UnsafePtr) = UnsafePtr(T, p)
uptr(T::Type, p) = UnsafePtr(T, ptr(p))

isnull(p::Ptr) = p == C_NULL
isnull(p) = isnull(ptr(p))

macro cpycall(ex)
    ex isa Expr && ex.head == :(::) && length(ex.args) == 2 || @goto err
    ex, rettype = ex.args
    rettype = esc(rettype)
    ex isa Expr && ex.head == :call || @goto err
    fname = esc(ex.args[1])
    args = []
    for ex in ex.args[2:end]
        ex isa Expr && ex.head == :(::) && length(ex.args) == 2 || @goto err
        x, t = ex.args
        push!(args, (gensym(), gensym(), esc(x), esc(t)))
    end
    return quote
        let $([:($n = Base.cconvert($t, $x)) for (n,u,x,t) in args]...)
            Base.GC.@preserve $([n for (n,u,x,t) in args]...) begin
                let $([:($u = Base.unsafe_convert($t, $n)) for (n,u,x,t) in args]...)
                    a = ccall(($fname, PYLIB), $rettype, ($([t for (n,u,x,t) in args]...),), $([u for (n,u,x,t) in args]...))
                    if iserr(a)
                        $([:(cpycall_errhook($u)) for (n,u,x,t) in args]...)
                    end
                    cpycall_returnhook(a)
                end
            end
        end
    end
    @label err
    error("expecting `@cpycall PyFunction(x::T, ...)::R`")
end

macro cpyobject(name)
    quote
        CPyBorrowedPtr(cglobal(($(esc(name)), PYLIB), CPyObject))
    end
end

macro unsafe_cacheget_object(cache, name)
    quote
        unsafe_cacheget!($(esc(cache))) do
            @cpyobject $(esc(name))
        end
    end
end

macro cpyobjectptr(name)
    quote
        CPyBorrowedPtr(unsafe_load(cglobal(($(esc(name)), PYLIB), Ptr{CPyObject})))
    end
end

macro unsafe_cacheget_objectptr(cache, name)
    quote
        unsafe_cacheget!($(esc(cache))) do
            @cpyobjectptr $(esc(name))
        end
    end
end
