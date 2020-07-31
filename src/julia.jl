abstract type PySubclass end

pyjuliaimpl_supertype(::Type{T}) where {T} = supertype(T)
pyjuliaimpl_supertype(::Type{T}) where {T<:PySubclass} = fieldtype(T, 1)

pyjuliaimpl_isconcrete(::Type{T}) where {T} = isconcretetype(T)
pyjuliaimpl_isconcrete(::Type{T}) where {T<:PySubclass} = true

pyjuliaimpl_unwrap(x::T) where {T} = x
pyjuliaimpl_unwrap(x::T) where {T<:PySubclass} = pyjuliaimpl_unwrap(getfield(x, 1))

pyjuliaimpl_unwrappedtype(::Type{T}) where {T} = T
pyjuliaimpl_unwrappedtype(::Type{T}) where {T<:PySubclass} = pyjuliaimpl_unwrappedtype(pyjuliaimpl_supertype(T))

"""
    CPyJuliaTypeObject{T}

The Python object structure for the Python type objects corresponding to T. That is, the Python type of `unsafe_pyjulia(::T)`.
"""
Base.@kwdef struct CPyJuliaTypeObject{T} <: AbstractCPyTypeObject
    base :: CPyTypeObject = CPyTypeObject()
end

"""
    CPyJuliaObject{T}

The Python object structure for wrapped Julia objects of type `T`.

The stored value is of type `PyJuliaImpl_UnwrappedType(T)`, which is `T` unless `T<:PySubclass`.
"""
Base.@kwdef struct CPyJuliaObject{T} <: AbstractCPyObject
    base :: CPyObject = CPyObject()
    value :: Ptr{Cvoid} = C_NULL
    weaklist :: PyPtr = C_NULL
end

# Used to ensure there is a single Python type for each Julia type.
const PYJLTYPECACHE = Base.IdDict{Type, PyObject}()
const _pyjulia_Any_type = pynull()

# Stores Julia object that must not be garbage-collected while the Python object is alive.
# It is the responsibility of the Python object to clear its entry when deallocated.
const PYJLGCCACHE = Base.IdDict{PyPtr, Any}()

const _pyexc_JuliaException_type = pynull()
unsafe_pyexc_JuliaException_type() =
    unsafe_cacheget!(_pyexc_JuliaException_type) do
        # make the type
        t, c = newpytype(; name="julia.JuliaException", base=pyexc_Exception_type(), basicsize=0)
        # put in into a 0-dim array and take a pointer
        t = fill(t)
        r = pointer(t)
        # ready the type
        e = ccall((:PyType_Ready, PYLIB), Cint, (PyPtr,), r)
        e == 0 || return PYNULL
        # success
        r = PyRef(r, true)
        PYJLGCCACHE[ptr(r)] = push!(c, t)
        return r
    end
pyexc_JuliaException_type() = safe(unsafe_pyexc_JuliaException_type())
export pyexc_JuliaException_type

function unsafe_pyjuliatype(::Type{T}) where {T}
    # if the type is cached, return that
    r = T===Any ? _pyjulia_Any_type : get(PYJLTYPECACHE, T, PYNULL)
    isnull(r) || return r
    # otherwise, make a new type
    opts = (
        name = "julia.$T",
        # `supertype(DataType)` is `Type{T}` (NOT `Type`) which causes wierdness!
        base = T === Any ? pyobjecttype() : T===DataType ? pyjuliatype(Type) : pyjuliatype(pyjuliaimpl_supertype(T)),
    )
    opts.base == C_NULL && return oftype(r, C_NULL)
    if pyjuliaimpl_isconcrete(T)
        # only concrete types have instances and therefore require methods
        nb_opts = (
            bool = pyjuliaimpl_getspecialattr(Val(:__bool__), T),
            int = pyjuliaimpl_getspecialattr(Val(:__int__), T),
            float = pyjuliaimpl_getspecialattr(Val(:__float__), T),
            index = pyjuliaimpl_getspecialattr(Val(:__index__), T),
            negative = pyjuliaimpl_getspecialattr(Val(:__neg__), T),
            positive = pyjuliaimpl_getspecialattr(Val(:__pos__), T),
            absolute = pyjuliaimpl_getspecialattr(Val(:__abs__), T),
            invert = pyjuliaimpl_getspecialattr(Val(:__invert__), T),
        )
        all(b==C_NULL for (a,b) in pairs(nb_opts)) && (nb_opts = C_NULL)
        mp_opts = (
            length = pyjuliaimpl_getspecialattr(Val(:__len__), T),
            subscript = pyjuliaimpl_getspecialattr(Val(:__getitem__), T),
            ass_subscript = pyjuliaimpl_getspecialattr(Val(:__setitem__), T),
        )
        all(b==C_NULL for (a,b) in pairs(mp_opts)) && (mp_opts = C_NULL)
        sq_opts = (
            length = pyjuliaimpl_getspecialattr(Val(:__len__), T),
            item = pyjuliaimpl_getspecialattr(Val(:__getitem_int__), T),
            ass_item = pyjuliaimpl_getspecialattr(Val(:__setitem_int__), T),
            contains = pyjuliaimpl_getspecialattr(Val(:__contains__), T),
            concat = pyjuliaimpl_getspecialattr(Val(:__concat__), T),
            inplace_concat = pyjuliaimpl_getspecialattr(Val(:__iconcat__), T),
            repeat = pyjuliaimpl_getspecialattr(Val(:__repeat__), T),
            inplace_repeat = pyjuliaimpl_getspecialattr(Val(:__irepeat__), T),
        )
        all(a==:length || b==C_NULL for (a,b) in pairs(sq_opts)) && (sq_opts = C_NULL)
        methods = [pyjuliaimpl_getmethodattr(Val(v), T) for v in pyjuliaimpl_attrlistofkind(T, :method)]
        isempty(methods) && (methods = C_NULL)
        getset = [pyjuliaimpl_getpropertyattr(Val(v), T) for v in pyjuliaimpl_attrlistofkind(T, :property)]
        isempty(getset) && (getset = C_NULL)
        opts = (opts...,
            basicsize = sizeof(CPyJuliaObject{T}),
            dealloc = pyjuliaimpl_getspecialattr(Val(:__dealloc__), T),
            hash = pyjuliaimpl_getspecialattr(Val(:__hash__), T),
            repr = pyjuliaimpl_getspecialattr(Val(:__repr__), T),
            str = pyjuliaimpl_getspecialattr(Val(:__str__), T),
            iter = pyjuliaimpl_getspecialattr(Val(:__iter__), T),
            iternext = pyjuliaimpl_getspecialattr(Val(:__next__), T),
            getattr = pyjuliaimpl_getspecialattr(Val(:__getattr_str__), T),
            setattr = pyjuliaimpl_getspecialattr(Val(:__setattr_str__), T),
            getattro = pyjuliaimpl_getspecialattr(Val(:__getattr__), T),
            setattro = pyjuliaimpl_getspecialattr(Val(:__setattr__), T),
            as_number = nb_opts,
            as_mapping = mp_opts,
            as_sequence = sq_opts,
            methods = methods,
            getset = getset,
        )
    else
        opts = (opts...,
            basicsize = 0,
        )
    end
    # make the type
    t, c = newpytype(; opts...)
    t = CPyJuliaTypeObject{T}(base=t)
    # put into a 0-dim array and take a pointer
    t = fill(t)
    r = pointer(t)
    # ready the type
    e = ccall((:PyType_Ready, PYLIB), Cint, (PyPtr,), r)
    e == 0 || return PYNULL
    # make a reference and cache
    r = unsafe_pyobj(PyRef(r, true))
    PYJLTYPECACHE[T] = r
    PYJLGCCACHE[ptr(r)] = push!(c, t)
    if T === Any
        setptr!(PyRef(_pyjulia_Any_type), ptr(r), true)
    end
    # # register with abstract base classes
    # superT = T
    # while true
    #     abc = pyjuliaimpl_abc(superT)
    #     if abc !== nothing
    #         reg = PyObject_GetAttrString(abc, "register")
    #         Py_DecRef(abc)
    #         reg == PyNULL && return oftype(r, C_NULL)
    #         ans = PyObject_NiceCall(reg, r)
    #         Py_DecRef(reg)
    #         ans == PyNULL && return oftype(r, C_NULL)
    #         Py_DecRef(ans)
    #     end
    #     superT === Any && break
    #     superT = supertype(superT)
    # end
    # done
    return r
end
pyjuliatype(T) = safe(unsafe_pyjuliatype(T))
export pyjuliatype

function unsafe_pyjulia(x::T) where {T}
    t = unsafe_pyjuliatype(T)
    isnull(t) && return PYNULL
    # allocate an object
    p = ccall((:_PyObject_New, PYLIB), Ptr{CPyJuliaObject{T}}, (PyPtr,), t)
    p == C_NULL && return PYNULL
    o = unsafe_pyobj(PyRef(p, false))
    # set weakrefs and value
    uptr(p).weaklist[] = C_NULL
    uptr(p).value[], PYJLGCCACHE[PyPtr(p)] = pointer_from_obj(pyjuliaimpl_unwrap(x))
    # done
    return o
end
pyjulia(args...; kwargs...) = safe(unsafe_pyjulia(args...; kwargs...))
export pyjulia

unsafe_pyjuliacheck(o) = unsafe_pytype_check(o, unsafe_pyjuliatype(Any))

_unsafe_pyjulia_getvalue(o::Union{Ref{CPyJuliaObject{T}}, AbstractPyRef{CPyJuliaObject{T}}}) where {T} =
    Base.unsafe_pointer_to_objref(uptr(o).value[Ptr]) :: T
function unsafe_pyjulia_getvalue(o)
    R = ValueOrError{Any}
    if !isa(o, AbstractPyRef)
        o = unsafe_pyobj(o)
        isnull(o) && return R()
    end
    if !unsafe_pyjuliacheck(o)
        pyerror_set_TypeError("expecting a julia type")
        return R()
    end
    Base.GC.@preserve o begin
        p = PyBorrowedRef{CPyJuliaObject{Any}}(ptr(o))
        return R(_unsafe_pyjulia_getvalue(p))
    end
end
pyjulia_getvalue(o) = safe(unsafe_pyjulia_getvalue(o))
export pyjulia_getvalue

function pyjuliaimpl_attrlist(T::Type)
    r = Symbol[]
    for m in methods(pyjuliaimpl_attrinfo, Tuple{Val, Type{T}}).ms
        v = Base.tuple_type_head(Base.tuple_type_tail(m.sig))
        if isconcretetype(v)
            name = v.parameters[1]
            if pyjuliaimpl_attrinfo(v(), T) !== nothing
                push!(r, v.parameters[1])
            end
        end
    end
    return r
end

function pyjuliaimpl_attrlistofkind(T::Type, k::Symbol)
    filter(pyjuliaimpl_attrlist(T)) do v
        info = pyjuliaimpl_attrinfo(Val(v), T)
        info===nothing || info[1]===k
    end
end

"""
    pyjuliaimpl_attrinfoofkind(Val(name), T, k)

If there is an attribute called `name` for type `T` of kind `k`, return its info with the leading kind `k` removed. Otherwise return `nothing`.
"""
function pyjuliaimpl_attrinfoofkind(v::Val{name}, T::Type, k::Symbol) where {name}
    a = pyjuliaimpl_attrinfo(v, T)
    a === nothing && return nothing
    a[1] === k || return nothing
    return a[2:end]
end

function pyjuliaimpl_getspecialattr(v::Val{name}, T::Type) where {name}
    SelfPtr = Ptr{CPyJuliaObject{T}}

    # get fixed information about the attr
    rettype, argtypes =
        # destructor
        if name in (:__dealloc__,)
            Cvoid, (SelfPtr,)
        # unaryfunc
        elseif name in (:__repr__, :__str__, :__iter__, :__next__, :__int__, :__float__, :__index__, :__neg__, :__pos__, :__abs__, :__invert__)
            PyPtr, (SelfPtr,)
        # binaryfunc, getattrofunc
        elseif name in (:__getitem__, :__contains__, :__concat__, :__iconcat__, :__getattr__)
            PyPtr, (SelfPtr, PyPtr,)
        # binaryfunc (self can be anywhere)
        elseif name in (:__add__,)
            PyPtr, (PyPtr, PyPtr)
        # ternaryfunc (self can be anywhere)
        elseif name in (:__pow__, :__ipow__)
            PyPtr, (PyPtr, PyPtr, PyPtr)
        # ssizeargfunc
        elseif name in (:__getitem_int__, :__repeat__, :__irepeat__)
            PyPtr, (SelfPtr, CPy_ssize_t,)
        # getattrfunc
        elseif name in (:__getattr_str__,)
            PyPtr, (SelfPtr, Cstring,)
        # inquiry
        elseif name in (:__bool__,)
            Cint, (SelfPtr,)
        # objobjargproc, setattrofunc
        elseif name in (:__setitem__, :__setattr__)
            Cint, (SelfPtr, PyPtr, PyPtr)
        # ssizeobjargproc
        elseif name in (:__setitem_int__,)
            Cint, (SelfPtr, CPy_ssize_t, PyPtr)
        # setattrfunc
        elseif name in (:__setattr_str__,)
            Cint, (SelfPtr, Cstring, PyPtr)
        # hashfunc
        elseif name in (:__hash__,)
            CPy_hash_t, (SelfPtr,)
        # lenfunc
        elseif name in (:__len__,)
            CPy_ssize_t, (SelfPtr,)
        else
            error("unrecognized special attr: $name")
        end

    # get the defining info
    a = pyjuliaimpl_attrinfoofkind(v, T, :special)
    a === nothing && return C_NULL
    unwrap = false
    func = missing
    for x in a
        if x === :unwrap
            unwrap = true
        elseif x isa Function
            func = x
        else
            error("invalid attr info: $(repr(x))")
        end
    end
    func === missing && error("missing function for $name")
    !unwrap || argtypes[1]==SelfPtr || error("unwrap not implemented for $name")

    # make the cfunction
    return pyjuliaimpl_definemethodfunc(Symbol(:pyjuliaimpl_method_,name), func, rettype, argtypes; unwrap=unwrap)
end

pyjuliaimpl_func_unwrap(f, ::Type{T}, ::Type{R}) where {T,R<:Union{Ptr,Integer,Cvoid}} =
    function (_o, args...)
        o = _unsafe_pyjulia_getvalue(_o) :: T
        try
            r = f(o, args...)
            convert(R, r)
        catch e
            _e = unsafe_pyjulia(e)
            pyerror_set(pyexc_JuliaException_type(), _e)
            return R<:Ptr ? R(C_NULL) : R<:Integer ? zero(R)-one(R) : nothing
        end
    end


function pyjuliaimpl_getmethodattr(v::Val{name}, T::Type) where {name}
    # get defining info
    a = pyjuliaimpl_attrinfoofkind(v, T, :method)
    a === nothing && return nothing
    # parse the info
    unwrap = false
    func = missing
    doc = nothing
    flags = UInt(0)
    args = missing
    kwargs = nothing
    for x in a
        if x===:unwrap
            unwrap = true
        elseif x===:class
            flags |= CPy_METH_CLASS
        elseif x===:static
            flags |= CPy_METH_STATIC
        elseif x in (:noargs, :onearg, :varargs, :kwargs)
            args = x
        elseif x isa Function
            func = x
        elseif x isa String
            doc = x
        else
            error("invalid attr info: $(repr(x))")
        end
    end
    args === missing && error("argument specification missing for $name")
    func === missing && error("function missing for $name")
    SelfPtr = Ptr{CPyJuliaObject{T}}
    if args === :noargs
        flags |= CPy_METH_NOARGS
        argtypes = (SelfPtr, PyPtr)
        func = let f=func
            @inline newfunc(a,b) = f(a)
            newfunc
        end
    elseif args === :onearg
        flags |= CPy_METH_O
        argtypes = (SelfPtr, PyPtr)
    elseif args === :varargs
        flags |= CPy_METH_VARARGS
        argtypes = (SelfPtr, PyPtr)
    elseif args === :kwargs
        flags |= CPy_METH_KEYWORDS
        argtypes = (SelfPtr, PyPtr, PyPtr)
    else
        @assert false
    end
    # make the C function
    fname = Symbol(:pyjuliaimpl_method_, name)
    rettype = PyPtr
    meth = pyjuliaimpl_definemethodfunc(fname, func, rettype, argtypes; unwrap=unwrap)
    # done
    (name=string(name), meth=meth, doc=doc, flags=flags)
end

function pyjuliaimpl_getpropertyattr(v::Val{name}, T::Type) where {name}
    # get defining info
    a = pyjuliaimpl_attrinfoofkind(v, T, :property)
    a === nothing && return nothing
    # parse the info
    unwrap = false
    getfunc = missing
    setfunc = missing
    doc = nothing
    for x in a
        if x===:unwrap
            unwrap = true
        elseif x isa Function
            if getfunc === missing
                getfunc = x
            else
                setfunc = x
            end
        elseif x isa String
            doc = x
        else
            error("invalid attr info: $(repr(x))")
        end
    end
    # make the C getter function
    SelfPtr = Ptr{CPyJuliaObject{T}}
    getfunc === missing && error("getter function missing for $name")
    getfname = Symbol(:pyjuliaimpl_getter_,name)
    getfunc2 = let oldgetfunc=getfunc
        @inline newgetfunc(a,b) = oldgetfunc(a)
        newgetfunc
    end
    get = pyjuliaimpl_definemethodfunc(getfname, getfunc2, PyPtr, (SelfPtr, Ptr{Cvoid}), unwrap=unwrap)
    # make the C setter function
    if setfunc === missing
        set = C_NULL
    else
        setfname = Symbol(:pyjuliaimpl_setter_,name)
        setfunc2 = let oldsetfunc=setfunc
            @inline newsetfunc(a,b,c) = oldsetfunc(a,b)
            newsetfunc
        end
        set = pyjuliaimpl_definemethodfunc(setfname, setfunc2, Cint, (SelfPtr, PyPtr, Ptr{Cvoid}), unwrap=unwrap)
    end
    # done
    (name=string(name), get=get, set=set, doc=doc)
end

pyjuliaimpl_retval(x) = x
pyjuliaimpl_retval(x::PyRef) = (incref(x); ptr(x))
pyjuliaimpl_retval(x::AbstractPyObject) = pyjuliaimpl_retval(PyRef(x))

pyjuliaimpl_argval(x) = x
pyjuliaimpl_argval(x::Ptr{<:AbstractCPyObject}) = PyBorrowedRef(x)
pyjuliaimpl_argval(x::Ptr{<:CPyJuliaObject}) = _unsafe_pyjulia_getvalue(PyBorrowedRef(x))

function pyjuliaimpl_definemethodfunc(name, func, rettype, argtypes; unwrap=false)
    errval = rettype<:Ptr ? convert(rettype,C_NULL) : rettype<:Integer ? zero(rettype)-one(rettype) : rettype<:Nothing ? nothing : error("not implemented")
    argnames = [gensym() for a in argtypes]
    fargs = [:($n :: $t) for (n,t) in zip(argnames, argtypes)]
    fbody =
        if unwrap
            argnames2 = [gensym() for a in argtypes]
            quote
                r :: $rettype = $errval
                $([:($b = pyjuliaimpl_argval($a)) for (a,b) in zip(argnames, argnames2)]...)
                try
                    r = pyjuliaimpl_retval($func($(argnames2...)))
                catch err
                    perr = unsafe_pyjulia(err)
                    pyerror_set(pyexc_JuliaException_type(), perr)
                end
                return r
            end
        else
            quote
                r :: $rettype = pyjuliaimpl_retval($func($(argnames...)))
                return r
            end
        end
    @eval $name($(fargs...)) = $fbody
    @eval @cfunction($name, $rettype, ($(argtypes...),))
end



mutable struct Iterator{T}
    source :: T
    state :: Union{Nothing,Some}
end

Iterator(x) = Iterator(x, nothing)





"""
    pyjuliaimpl_attrinfo(attr, T::Type)
    pyjuliaimpl_attrinfo(::Val{attr}, T::Type)

Information about the attribute `attr` of Python wrapped Julia objects of type `T` (i.e. attributes of `unsafe_pyjulia(::T)`).

Returns `nothing` if there is no such attribute, otherwise a tuple of information.

The first entry is one of:
* `:special`: Special methods with named fields in `PyTypeObjectStruct`.
* `:method`: Generic methods.
* `:property`: Getter/setter properties.

Remaining entries specify additional infomation, such as:
* `f::Function`: These define the behaviour of the attribute, such as the implementation of a method. For properties, the first function encountered is the getter, the second is the setter. The required signature of the function depends on the kind of the attribute, plus the other information.
* `d::String`: The documentation string.
* `:unwrap`: Indicates that the "self" value (which is a wrapped `T`) should be unwrapped first, so that the first argument to the function is a `T`.
* Method argument specification:
  * `:noargs`: Signature of `f` is `f(self)`.
  * `:onearg`: Signature of `f` is `f(self, arg)` where `arg` is the argument.
  * `:varargs`: Signature of `f` is `f(self, args)` where `args` is the Python tuple of arguments.
  * `:kwargs`: Signature of `f` is `f(self, args, kwargs)` where `kwargs` is the Python dict of keyword arguments.
* Method kind: `:instance` (default), `:class`, or `:static`.

# Adding attributes

To add a new attribute to a type, overload the second form of this function.

For example, the following definition adds a `append` method to any wrapped `AbstractVector`s.

```julia
pyjuliaimpl_attrinfo(::Val{:append}, ::Type{T}) where {T<:AbstractVector} =
    :method,
    :unwrap,
    function (o, _v)
        v = PyObject_Convert((eltype(o), Any), _v)
        v === Py_ERRFLAG && return PyNULL
        push!(o, v)
        Py_IncRef(Py_None())
    end
```
"""
pyjuliaimpl_attrinfo(a::Symbol, ::Type{T}) where {T} =
    pyjuliaimpl_attrinfo(Val(a), T)

pyjuliaimpl_attrinfo(::Val, ::Type) =
    nothing



# """
#     pyjuliaimpl_abc(T)

# Return `nothing` or (a new reference to) an abstract base class to register `T`.
# """
# pyjuliaimpl_abc(::Type{T}) where {T} = nothing


### GENERIC RULES

pyjuliaimpl_attrinfo(::Val{:__dealloc__}, ::Type) =
    :special,
    function (o)
        uptr(o).weaklist[] != C_NULL || ccall((:PyObject_ClearWeakRefs, PYLIB), Cvoid, (PyPtr,), o)
        delete!(PYJLGCCACHE, ptr(o))
        nothing
    end

pyjuliaimpl_attrinfo(::Val{:__hash__}, ::Type) =
    :special,
    o -> zero(CPy_hash_t)

pyjuliaimpl_attrinfo(::Val{:__repr__}, ::Type) =
    :special, :unwrap,
    o -> unsafe_pystr("$(repr(o)) (Julia)")

pyjuliaimpl_attrinfo(::Val{:__str__}, ::Type) =
    :special, :unwrap,
    o -> unsafe_pystr(string(o))

pyjuliaimpl_attrinfo(::Val{:__iter__}, ::Type{T}) where {T} =
    if hasmethod(iterate, Tuple{T})
        :special, :unwrap,
        o -> unsafe_pyjulia(Iterator(o))
    end

pyjuliaimpl_attrinfo(::Val{:__len__}, ::Type{T}) where {T} =
    if hasmethod(length, Tuple{T})
        :special, :unwrap,
        o -> length(o)
    end

pyjuliaimpl_attrinfo(::Val{:__getattr__}, ::Type{T}) where {T} =
    :special,
    function (__o, __k)
        _o = PyBorrowedRef(__o)
        _k = PyBorrowedRef(__k)
        # generic lookup
        r = unsafe_pygenericgetattr(_o, _k)
        if !isnull(r) || !pyerror_occurred_AttributeError()
            return r
        end
        # julia property
        o = _unsafe_pyjulia_getvalue(_o)
        k = unsafe_pystr_asjuliastring(_k)
        iserr(k) && return PYNULL
        k = Symbol(value(k))
        try
            if hasproperty(o, k)
                pyerror_clear()
                return unsafe_pyobj(getproperty(o, k))
            end
        catch err
            pyerror_set(pyexc_JuliaException_type(), unsafe_pyobj(err))
            return PYNULL
        end
        # give up
        return r
    end

pyjuliaimpl_attrinfo(::Val{:__dir__}, ::Type{T}) where {T} =
    :method, :noargs,
    function (_o)
        # call the generic __dir__
        d = @safe unsafe_pyobjecttype()
        d = @safe unsafe_pygetattr(d, "__dir__")
        d = @safe unsafe_pycall(d, _o)
        # add properties of o
        o = _unsafe_pyjulia_getvalue(_o)
        for a in propertynames(o)
            k = @safe unsafe_pystr(string(a))
            @safe unsafe_pylist_append(d, k)
        end
        return d

        @label error
        return PYNULL
    end

pyjuliaimpl_attrinfo(::Val{:__getitem__}, ::Type{T}) where {T} =
    :special, :unwrap,
    function (o, _k)
        k = @safe unsafe_pyconvertkey(o, _k)
        return unsafe_pyobj(getindex(o, k))
        @label error
        return PYNULL
    end

pyjuliaimpl_attrinfo(::Val{:__setitem__}, ::Type{T}) where {T} =
    :special, :unwrap,
    function (o, _k, _v)
        k = @safe unsafe_pyconvertkey(o, _k)
        v = @safe unsafe_pyconvertvalue(o, k, _v)
        setindex!(o, v, k)
        return unsafe_pynone()
        @label error
        return PYNULL
    end

### ITERATOR

pyjuliaimpl_attrinfo(::Val{:__next__}, ::Type{T}) where {T<:Iterator} =
    :special, :unwrap,
    function (o)
        source = o.source
        state = o.state
        x = state === nothing ? iterate(source) : iterate(source, something(state))
        if x === nothing
            pyerror_set_StopIteration()
            return PYNULL
        else
            val, state = x
            o.state = Some(state)
            return unsafe_pyobj(val)
        end
    end

pyjuliaimpl_attrinfo(::Val{:__iter__}, ::Type{T}) where {T<:Iterator} =
    :special,
    o -> incref(o)

### ABSTRACT ARRAY

# pyjuliaimpl_attrinfo(::Val{:__getitem__}, ::Type{T}) where {T<:AbstractArray} =
#     :special, :unwrap,
#     function (o, i)
#         @info "getitem" o typeof(o) PyObject_Repr_Julia(i)
#         error("__getitem__ not implemented for $T")
#     end

function numpy_typestr_descr(::Type{T}) where {T}
    sz = Base.aligned_sizeof(T)
    descr = PYNULL
    typestr = "|V$(sz)"
    ec = Base.ENDIAN_BOM == 0x04030201 ? '<' : Base.ENDIAN_BOM == 0x01020304 ? '>' : error("can't determine endianness")
    if Base.allocatedinline(T)
        if T == Bool
            @assert sz == sizeof(T)
            typestr = "$(ec)b$(sz)"
        elseif T in (Int8, Int16, Int32, Int64)
            @assert sz == sizeof(T)
            typestr = "$(ec)i$(sz)"
        elseif T in (UInt8, UInt16, UInt32, UInt64)
            @assert sz == sizeof(T)
            typestr = "$(ec)u$(sz)"
        elseif T in (Float16, Float32, Float64)
            @assert sz == sizeof(T)
            typestr = "$(ec)f$(sz)"
        elseif T in (ComplexF16, ComplexF32, ComplexF64)
            @assert sz == sizeof(T)
            typestr = "$(ec)c$(sz)"
        elseif isstructtype(T)
            error("not implemented")
            # TODO: this can be tidied up by computing the all the field names and padding up-front
            # TODO: use the (real_name, python_name) form for the name
            fns = fieldnames(T)
            if all(x->x isa Integer, fns)
                fns = map(x->Symbol(:f, x-1), fns)
            end
            @assert all(x->x isa Symbol, fns)
            descr = PyList_New(0)
            descr == PyNULL && @goto err
            csz = 0
            for (i,fn) in enumerate(fns)
                t, d, s = numpy_typestr_descr(fieldtype(T, i))
                t == PyNULL && @goto err
                if d != PyNULL
                    Py_DecRef(t)
                    t = d
                end
                x = PyTuple_FromIter(o -> o isa String ? PyUnicode_From(o) : Py_IncRef(o), (string(fn), t))
                Py_DecRef(t)
                x == PyNULL && @goto err
                e = PyList_Append(descr, x)
                Py_DecRef(x)
                e == -1 && @goto err
                csz += s
                # deal with padding
                off = i == length(fns) ? sz : fieldoffset(T, i+1)
                @assert csz ≤ off
                if csz < off
                    x = PyTuple_FromIter(PyUnicode_From, ("_padding$i", "|V$(off-csz)"))
                    x == PyNULL && @goto err
                    e = PyList_Append(descr, x)
                    Py_DecRef(x)
                    e == -1 && @goto err
                    csz = off
                end
            end
        end
    end
    return unsafe_pystr(typestr), descr, sz

    @label err
    return PYNULL, PYNULL, 0
end

# numpy array interface
pyjuliaimpl_attrinfo(::Val{:__array_interface__}, ::Type{T}) where {T<:StridedArray} =
    :property, :unwrap,
    function (o)
        d = unsafe_pydict()
        isnull(d) && return PYNULL

        # shape
        x = unsafe_pytuple_fromiter(size(o))
        isnull(x) && return PYNULL
        e = unsafe_pydict_setitem_string(d, "shape", x)
        iserr(e) && return PYNULL

        # descr & elsize
        x, y, elsz = numpy_typestr_descr(eltype(o))
        isnull(x) && return PYNULL
        e = unsafe_pydict_setitem_string(d, "typestr", x)
        iserr(e) && return PYNULL
        if !isnull(y)
            e = unsafe_pydict_setitem_string(d, "descr", y)
            iserr(e) && return PYNULL
        end

        # data
        x = unsafe_pytuple_fromiter((convert(Integer, Base.unsafe_convert(Ptr{T}, o)), isimmutable(o)))
        isnull(x) && return PYNULL
        e = unsafe_pydict_setitem_string(d, "data", x)
        iserr(e) && return PYNULL

        # strides
        x = unsafe_pytuple_fromiter(strides(o) .* elsz)
        isnull(x) && return PYNULL
        e = unsafe_pydict_setitem_string(d, "strides", x)
        iserr(e) && return PYNULL

        # version
        x = unsafe_pyint(3)
        isnull(x) && return PYNULL
        e = unsafe_pydict_setitem_string(d, "version", x)
        iserr(e) && return PYNULL

        # done
        return d
    end

# ### ABSTRACT VECTOR

pyjuliaimpl_attrinfo(::Val{:__getitem_int__}, ::Type{T}) where {T<:AbstractVector} =
    :special, :unwrap,
    (o, i) -> unsafe_pyobj(getindex(o, i+1))

pyjuliaimpl_attrinfo(::Val{:__setitem_int__}, ::Type{T}) where {T<:AbstractVector} =
    :special, :unwrap,
    (o, i, v) -> (setindex!(o, v, i+1); 0)

pyjuliaimpl_attrinfo(::Val{:reverse}, ::Type{T}) where {T<:AbstractVector} =
    if T.mutable && hasmethod(reverse!, Tuple{T})
        :method, :noargs, :unwrap,
        o -> (reverse!(o); unsafe_pynone())
    end

pyjuliaimpl_attrinfo(::Val{:sort}, ::Type{T}) where {T<:AbstractVector} =
    if T.mutable && hasmethod(sort!, Tuple{T})
        :method, :noargs, :unwrap,
        o -> (sort!(o); unsafe_pynone())
    end

# ### NUMBER

# pyjuliaimpl_abc(::Type{T}) where {T<:Number} = Py_NumberABC()

# pyjuliaimpl_attrinfo(::Val{:__bool__}, ::Type{T}) where {T<:Number} =
#     if hasmethod(iszero, Tuple{T})
#         :special,
#         :unwrap,
#         o -> !iszero(o)
#     end

# pyjuliaimpl_attrinfo(::Val{:__neg__}, ::Type{T}) where {T<:Number} =
#     if hasmethod(-, Tuple{T})
#         :special,
#         :unwrap,
#         o -> unsafe_pyjulia(-o)
#     end

# pyjuliaimpl_attrinfo(::Val{:__pos__}, ::Type{T}) where {T<:Number} =
#     if hasmethod(+, Tuple{T})
#         :special,
#         :unwrap,
#         o -> unsafe_pyjulia(+o)
#     end

# pyjuliaimpl_attrinfo(::Val{:__abs__}, ::Type{T}) where {T<:Number} =
#     if hasmethod(abs, Tuple{T})
#         :special,
#         :unwrap,
#         o -> unsafe_pyjulia(abs(o))
#     end

# pyjuliaimpl_attrinfo(::Val{:__int__}, ::Type{T}) where {T<:Number} =
#     if hasmethod(convert, Tuple{Type{Integer}, T})
#         :special,
#         :unwrap,
#         o -> PyLong_From(convert(Integer, o))
#     end

# pyjuliaimpl_attrinfo(::Val{:__float__}, ::Type{T}) where {T<:Number} =
#     if hasmethod(convert, Tuple{Type{Real}, T})
#         :special,
#         :unwrap,
#         o -> PyFloat_From(convert(Real, o))
#     end

# ### COMPLEX

# const PYCOMPLEX = Union{Real, Complex}

# pyjuliaimpl_abc(::Type{T}) where {T<:PYCOMPLEX} = Py_ComplexABC()

# pyjuliaimpl_attrinfo(::Val{:conjugate}, ::Type{T}) where {T<:PYCOMPLEX} =
#     :method, :noargs, :unwrap,
#     o -> unsafe_pyjulia(conj(o))

# pyjuliaimpl_attrinfo(::Val{:real}, ::Type{T}) where {T<:PYCOMPLEX} =
#     :property, :unwrap,
#     o -> unsafe_pyjulia(real(o))

# pyjuliaimpl_attrinfo(::Val{:imag}, ::Type{T}) where {T<:PYCOMPLEX} =
#     :property, :unwrap,
#     o -> unsafe_pyjulia(imag(o))

# ### REAL

# pyjuliaimpl_abc(::Type{T}) where {T<:Real} = Py_RealABC()

# pyjuliaimpl_attrinfo(::Val{:__float__}, ::Type{T}) where {T<:Real} =
#     :special,
#     :unwrap,
#     o -> PyFloat_From(o)

# pyjuliaimpl_attrinfo(::Val{:__int__}, ::Type{T}) where {T<:Real} =
#     if hasmethod(round, Tuple{Type{Integer}, T})
#         :special,
#         :unwrap,
#         o -> PyLong_From(round(Integer, o))
#     else
#         invoke(pyjuliaimpl_attrinfo, Tuple{Val{:__int__}, Type{supertype(T)}}, Val(:__int__), T)
#     end

# pyjuliaimpl_attrinfo(::Val{:__trunc__}, ::Type{T}) where {T<:Real} =
#     if hasmethod(trunc, Tuple{Type{Integer}, T})
#         :method, :noargs, :unwrap,
#         o -> PyLong_From(trunc(Integer, o))
#     end

# pyjuliaimpl_attrinfo(::Val{:__floor__}, ::Type{T}) where {T<:Real} =
#     if hasmethod(floor, Tuple{Type{Integer}, T})
#         :method, :noargs, :unwrap,
#         o -> PyLong_From(floor(Integer, o))
#     end

# pyjuliaimpl_attrinfo(::Val{:__ceil__}, ::Type{T}) where {T<:Real} =
#     if hasmethod(ceil, Tuple{Type{Integer}, T})
#         :method, :noargs, :unwrap,
#         o -> PyLong_From(ceil(Integer, o))
#     end

# pyjuliaimpl_attrinfo(::Val{:__round__}, ::Type{T}) where {T<:Real} =
#     if hasmethod(round, Tuple{Type{Integer}, T}) && hasmethod(round, Tuple{T})
#         :method, :varargs, :unwrap,
#         function (o, _args)
#             args = @PyArg_Parse _args (digits::Union{Int,Nothing}=nothing,)
#             args === Py_ERRFLAG && return PyNULL
#             if args.digits === nothing
#                 return PyLong_From(round(Integer, o))
#             else
#                 return unsafe_pyjulia(oftype(o, round(o, digits=args.digits)))
#             end
#         end
#     end

# ### RATIONAL

# const PYRATIONAL = Union{Rational, Integer}

# pyjuliaimpl_abc(::Type{T}) where {T<:PYRATIONAL} = Py_RationalABC()

# pyjuliaimpl_attrinfo(::Val{:numerator}, ::Type{T}) where {T<:PYRATIONAL} =
#     :property, :unwrap,
#     o -> unsafe_pyjulia(numerator(o))

# pyjuliaimpl_attrinfo(::Val{:denominator}, ::Type{T}) where {T<:PYRATIONAL} =
#     :property, :unwrap,
#     o -> unsafe_pyjulia(denominator(o))

# ### INTEGER

# pyjuliaimpl_abc(::Type{T}) where {T<:Integer} = Py_IntegralABC()

# pyjuliaimpl_attrinfo(::Val{:__index__}, ::Type{T}) where {T<:Integer} =
#     :special,
#     :unwrap,
#     o -> PyLong_From(o)

# pyjuliaimpl_attrinfo(::Val{:__invert__}, ::Type{T}) where {T<:Integer} =
#     if hasmethod(~, Tuple{T})
#         :special,
#         :unwrap,
#         o -> unsafe_pyjulia(~o)
#     end

# ### IO
# # We wrap IO as a Python IOBase, and use PySubclass to create Python subclasses that wrap IO as RawIO, BufferedIO and TextIO.

# pyjuliaimpl_abc(::Type{T}) where {T<:IO} = Py_IOBaseABC()

# pyjuliaimpl_attrinfo(::Val{:close}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     o -> (close(o); Py_IncRef(Py_None()))

# pyjuliaimpl_attrinfo(::Val{:closed}, ::Type{T}) where {T<:IO} =
#     :property, :unwrap,
#     o -> PyBool_From(!isopen(o))

# pyjuliaimpl_attrinfo(::Val{:fileno}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     if hasmethod(fd, Tuple{T})
#         o -> PyLong_From(fd(o))
#     else
#         o -> (PyErr_SetNone(PyExc_OSError()); PyNULL)
#     end

# pyjuliaimpl_attrinfo(::Val{:flush}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     o -> (flush(o); Py_IncRef(Py_None()))

# pyjuliaimpl_attrinfo(::Val{:isatty}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     if T <: Base.TTY
#         o -> PyBool_From(true)
#     else
#         o -> PyBool_From(false)
#     end

# pyjuliaimpl_attrinfo(::Val{:readable}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     if hasmethod(isreadable, Tuple{T})
#         o -> PyBool_From(isreadable(o))
#     else
#         o -> (PyErr_SetNone(PyExc_UnsupportedOperation()); PyNULL)
#     end

# pyjuliaimpl_attrinfo(::Val{:seek}, ::Type{T}) where {T<:IO} =
#     :method, :varargs, :unwrap,
#     if hasmethod(position, Tuple{T}) && hasmethod(seek, Tuple{T,Int}) && hasmethod(seekstart, Tuple{T}) && hasmethod(seekend, Tuple{T})
#         function (o, _args)
#             args = @PyArg_Parse _args (offset::Int, whence::Int=0)
#             args === Py_ERRFLAG && return PyNULL
#             if args.whence == 0
#                 seekstart(o)
#                 seek(o, position(o) + args.offset)
#             elseif args.whence == 1
#                 seek(o, args.offset)
#             elseif args.whence == 2
#                 seekend(o)
#                 seek(o, position(o) + args.offset)
#             else
#                 PyErr_SetString(PyExc_UnsupportedOperation(), "seek with whence = $(args.whence)")
#                 return PyNULL
#             end
#             return Py_IncRef(Py_None())
#         end
#     else
#         o -> (PyErr_SetNone(PyExc_OSError()); PyNULL)
#     end

# pyjuliaimpl_attrinfo(::Val{:seekable}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     if hasmethod(position, Tuple{T}) && hasmethod(seek, Tuple{T,Int}) && hasmethod(seekstart, Tuple{T}) && hasmethod(seekend, Tuple{T})
#         o -> PyBool_From(true)
#     else
#         o -> PyBool_From(false)
#     end

# pyjuliaimpl_attrinfo(::Val{:tell}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     if hasmethod(position, Tuple{T})
#         o -> PyLong_From(position(o))
#     else
#         o -> (PyErr_SetNone(PyExc_OSError()); PyNULL)
#     end

# pyjuliaimpl_attrinfo(::Val{:truncate}, ::Type{T}) where {T<:IO} =
#     :method, :varargs, :unwrap,
#     if hasmethod(truncate, Tuple{T,Int})
#         function (o, _args)
#             args = @PyArg_Parse _args (size::Union{Int,Nothing}=nothing,)
#             args === Py_ERRFLAG && return PyNULL
#             size == args.size === nothing ? position(o) : args.size
#             truncate(o, size)
#             return Py_IncRef(Py_None())
#         end
#     else
#         o -> (PyErr_SetNone(PyExc_OSError()); PyNULL)
#     end

# pyjuliaimpl_attrinfo(::Val{:writable}, ::Type{T}) where {T<:IO} =
#     :method, :noargs, :unwrap,
#     if hasmethod(iswritable, Tuple{T})
#         o -> PyBool_From(iswritable(o))
#     else
#         o -> (PyErr_SetNone(PyExc_UnsupportedOperation()); PyNULL)
#     end

# ### RawIO

# struct RawIO{T<:IO} <: PySubclass
#     super :: T
# end

# pyjuliaimpl_abc(::Type{T}) where {T<:RawIO} = Py_RawIOBaseABC()

# ### BufferedIO

# struct BufferedIO{T<:IO} <: PySubclass
#     super :: T
# end

# pyjuliaimpl_abc(::Type{T}) where {T<:BufferedIO} = Py_BufferedIOBaseABC()

# ### TextIO

# struct TextIO{T<:IO} <: PySubclass
#     super :: T
# end

# pyjuliaimpl_abc(::Type{T}) where {T<:TextIO} = Py_TextIOBaseABC()

# pyjuliaimpl_attrinfo(::Val{:encoding}, ::Type{T}) where {T<:TextIO} =
#     :property, :unwrap,
#     o -> PyUnicode_From("utf-8")

# pyjuliaimpl_attrinfo(::Val{:errors}, ::Type{T}) where {T<:TextIO} =
#     :property, :unwrap,
#     o -> PyUnicode_From("strict")

# pyjuliaimpl_attrinfo(::Val{:detach}, ::Type{T}) where {T<:TextIO} =
#     :method, :noargs, :unwrap,
#     o -> (PyErr_SetNone(PyExc_UnsupportedOperation()); PyNULL)

# pyjuliaimpl_attrinfo(::Val{:read}, ::Type{T}) where {T<:TextIO} =
#     :method, :varargs, :unwrap,
#     function (o, _args)
#         args = @PyArg_Parse _args (size::Union{Int,Nothing}=nothing,)
#         args === Py_ERRFLAG && return PyNULL
#         if args.size === nothing || args.size < 0
#             r = read(o, String)
#         else
#             # TODO: how to read a given number of characters?
#             PyErr_SetNone(PyExc_UnsupportedOperation())
#             return PyNULL
#         end
#         return PyUnicode_From(r)
#     end

# pyjuliaimpl_attrinfo(::Val{:readline}, ::Type{T}) where {T<:TextIO} =
#     :method, :varargs, :unwrap,
#     function (o, _args)
#         args = @PyArg_Parse _args (size::Union{Int,Nothing}=nothing,)
#         args === Py_ERRFLAG && return PyNULL
#         if args.size === nothing || args.size < 0
#             r = readline(o, keep=true)
#         else
#             # TODO: how to read a given number of characters?
#             PyErr_SetNone(PyExc_UnsupportedOperation())
#             return PyNULL
#         end
#         return PyUnicode_From(r)
#     end

# pyjuliaimpl_attrinfo(::Val{:write}, ::Type{T}) where {T<:TextIO} =
#     :method, :varargs, :unwrap,
#     function (o, _args)
#         args = @PyArg_Parse _args (str::String,)
#         args === Py_ERRFLAG && return PyNULL
#         write(o, args.str)
#         return PyLong_From(length(args.str))
#     end
