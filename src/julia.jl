abstract type PySubclass end

pyjulia_supertype(::Type{T}) where {T} = supertype(T)
pyjulia_supertype(::Type{T}) where {T<:PySubclass} = fieldtype(T, 1)

pyjulia_isconcrete(::Type{T}) where {T} = isconcretetype(T)
pyjulia_isconcrete(::Type{T}) where {T<:PySubclass} = true

pyjulia_unwrap(x::T) where {T} = x
pyjulia_unwrap(x::T) where {T<:PySubclass} = pyjulia_unwrap(getfield(x, 1))

pyjulia_unwrappedtype(::Type{T}) where {T} = T
pyjulia_unwrappedtype(::Type{T}) where {T<:PySubclass} = pyjulia_unwrappedtype(pyjulia_supertype(T))

struct AsPyRawIO{T<:IO} <: PySubclass
    io :: T
end
struct AsPyBufferedIO{T<:IO} <: PySubclass
    io :: T
end
struct AsPyTextIO{T<:IO} <: PySubclass
    io :: T
end

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

The stored value is of type `pyjulia_unwrappedtype(T)`, which is `T` unless `T<:PySubclass`.
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
        base = T === Any ? unsafe_pyobjecttype() : T===DataType ? unsafe_pyjuliatype(Type) : unsafe_pyjuliatype(pyjulia_supertype(T)),
    )
    isnull(opts.base) && return PYNULL
    if pyjulia_isconcrete(T)
        # only concrete types have instances and therefore require methods
        nb_opts = (
            bool = pyjulia_specialattr(Val(:__bool__), T),
            int = pyjulia_specialattr(Val(:__int__), T),
            float = pyjulia_specialattr(Val(:__float__), T),
            index = pyjulia_specialattr(Val(:__index__), T),
            negative = pyjulia_specialattr(Val(:__neg__), T),
            positive = pyjulia_specialattr(Val(:__pos__), T),
            absolute = pyjulia_specialattr(Val(:__abs__), T),
            invert = pyjulia_specialattr(Val(:__invert__), T),
        )
        all(b==C_NULL for (a,b) in pairs(nb_opts)) && (nb_opts = C_NULL)
        mp_opts = (
            length = pyjulia_specialattr(Val(:__len__), T),
            subscript = pyjulia_specialattr(Val(:__getitem__), T),
            ass_subscript = pyjulia_specialattr(Val(:__setitem__), T),
        )
        all(b==C_NULL for (a,b) in pairs(mp_opts)) && (mp_opts = C_NULL)
        sq_opts = (
            length = pyjulia_specialattr(Val(:__len__), T),
            item = pyjulia_specialattr(Val(:__getitem_int__), T),
            ass_item = pyjulia_specialattr(Val(:__setitem_int__), T),
            contains = pyjulia_specialattr(Val(:__contains__), T),
            concat = pyjulia_specialattr(Val(:__concat__), T),
            inplace_concat = pyjulia_specialattr(Val(:__iconcat__), T),
            repeat = pyjulia_specialattr(Val(:__repeat__), T),
            inplace_repeat = pyjulia_specialattr(Val(:__irepeat__), T),
        )
        all(a==:length || b==C_NULL for (a,b) in pairs(sq_opts)) && (sq_opts = C_NULL)
        methods = pyjulia_methodattrs(T)
        isempty(methods) && (methods = C_NULL)
        getset = pyjulia_propertyattrs(T)
        isempty(getset) && (getset = C_NULL)
        opts = (opts...,
            basicsize = sizeof(CPyJuliaObject{T}),
            dealloc = pyjulia_specialattr(Val(:__dealloc__), T),
            hash = pyjulia_specialattr(Val(:__hash__), T),
            repr = pyjulia_specialattr(Val(:__repr__), T),
            str = pyjulia_specialattr(Val(:__str__), T),
            iter = pyjulia_specialattr(Val(:__iter__), T),
            iternext = pyjulia_specialattr(Val(:__next__), T),
            getattr = pyjulia_specialattr(Val(:__getattr_str__), T),
            setattr = pyjulia_specialattr(Val(:__setattr_str__), T),
            getattro = pyjulia_specialattr(Val(:__getattr__), T),
            setattro = pyjulia_specialattr(Val(:__setattr__), T),
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
    flags = (versiontag=true, getcharbuffer=true, sequencein=true, inplaceops=true, richcompare=true, weakrefs=true, iter=true, class=true, index=true, basetype=true)
    # make the type
    t, c = newpytype(; flags=flags, opts...)
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
    # register ABC
    abc = pyjulia_abc(T)
    if abc !== nothing
        e = unsafe_pyabc_register(abc, r)
        iserr(e) && return PYNULL
    end
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
    uptr(p).value[], PYJLGCCACHE[PyPtr(p)] = pointer_from_obj(pyjulia_unwrap(x))
    # done
    return o
end
pyjulia(args...; kwargs...) = safe(unsafe_pyjulia(args...; kwargs...))
export pyjulia

pyisjulia(o) = unsafe_pytype_check(o, pyjuliatype(Any))

unsafe_pyjulia_tryconvert(::Type{T}, o::AbstractPyRef) where {T} =
    tryconvert(T, unsafe_pyjulia_getvalue(o))

_unsafe_pyjulia_getvalue(o::Union{Ref{CPyJuliaObject{T}}, AbstractPyRef{CPyJuliaObject{T}}}) where {T} =
    Base.unsafe_pointer_to_objref(uptr(o).value[Ptr]) :: pyjulia_unwrappedtype(T)
_unsafe_pyjulia_getvalue(o::AbstractPyRef) =
    Base.GC.@preserve o _unsafe_pyjulia_getvalue(Ptr{CPyJuliaObject{Any}}(ptr(o)))

function unsafe_pyjulia_getvalue(o)
    R = ValueOrError{Any}
    if !isa(o, AbstractPyRef)
        o = unsafe_pyobj(o)
        isnull(o) && return R()
    end
    if !pyisjulia(o)
        pyerror_set_TypeError("expecting a julia type")
        return R()
    end
    R(_unsafe_pyjulia_getvalue(o))
end
pyjulia_getvalue(o) = safe(unsafe_pyjulia_getvalue(o))
export pyjulia_getvalue


pyjulia_attrkind(::Val, ::Type) = nothing

function pyjulia_attrdef end

function pyjulia_attrlist(T::Type)
    r = Symbol[]
    for m in methods(pyjulia_attrkind, Tuple{Val, Type{T}}).ms
        v = Base.tuple_type_head(Base.tuple_type_tail(m.sig))
        if isconcretetype(v)
            name = v.parameters[1]
            if pyjulia_attrkind(v(), T) !== nothing
                push!(r, name)
            end
        end
    end
    return r
end

pyjulia_attrlistofkind(T::Type, k::Symbol) =
    filter(name -> pyjulia_attrkind(Val(name), T) == k, pyjulia_attrlist(T))

pyjulia_specialattr(::Val{name}, ::Type{T}) where {name, T} =
    if pyjulia_attrkind(Val(name), T) == :special
        pyjulia_attrdef(Val(name), T)
    else
        C_NULL
    end

pyjulia_methodattr(::Val{name}, ::Type{T}) where {name, T} =
    if pyjulia_attrkind(Val(name), T) == :method
        pyjulia_attrdef(Val(name), T)
    else
        nothing
    end

pyjulia_methodattrs(::Type{T}) where {T} =
    [pyjulia_methodattr(Val(name), T) for name in pyjulia_attrlistofkind(T, :method)]

pyjulia_propertyattr(::Val{name}, ::Type{T}) where {name, T} =
    if pyjulia_attrkind(Val(name), T) == :property
        pyjulia_attrdef(Val(name), T)
    else
        nothing
    end

pyjulia_propertyattrs(::Type{T}) where {T} =
    [pyjulia_propertyattr(Val(name), T) for name in pyjulia_attrlistofkind(T, :property)]





mutable struct Iterator{T}
    source :: T
    state :: Union{Nothing,Some}
end

Iterator(x) = Iterator(x, nothing)

"""
    PairSet(dict::AbstractDict{K,V}) :: AbstractSet{Pair{K,V}}

The set of key-value pairs of `dict`.
"""
struct PairSet{K, V, D<:AbstractDict{K, V}} <: AbstractSet{Pair{K, V}}
    dict :: D
end

Base.length(x::PairSet) = length(x.dict)

Base.iterate(x::PairSet) = iterate(x.dict)
Base.iterate(x::PairSet, st) = iterate(x.dict, st)

Base.in(v, x::PairSet) = (v isa Pair) ? (v in x.dict) : false

### GENERATED RULES

const JL_ATTR_TOML = joinpath(@__DIR__, "julia_attrs.toml")
const JL_ATTR_JL = joinpath(@__DIR__, "julia_attrs.jl")

open(JL_ATTR_JL, "w") do io
    function printmethod(io, mname, data, key, rettype, nargs; dropargs=[])
        fname = "_$(mname)"
        println(io, "const $fname = $(data[key])")
        unwrap = get(data, "unwrap", true)
        exc = get(data, "catch", true)
        argnames = ["x$i" for i in 1:nargs]
        lines = ["r::$rettype = pyjulia_retval($fname($(join([n for (i,n) in enumerate(argnames) if !in(i,dropargs)], ", "))))", "return r"]
        if exc
            errval =
                rettype in ("Cint", "CPy_hash_t", "CPy_ssize_t") ? "(zero($rettype) - one($rettype))" :
                rettype == "PyPtr" ? "$rettype(C_NULL)" :
                rettype == "Cvoid" ? "nothing" :
                error("don't know the error value for return type $errval")
            lines = [
                "try";
                ["    $line" for line in lines];
                "catch err";
                "    perr = unsafe_pyobj(err)";
                "    pyerror_set(pyexc_JuliaException_type(), perr)";
                "    return $errval";
                "end";
            ]
        end
        if unwrap
            argnames2 = ["y$i" for i in 1:nargs]
            lines = [
                ["$x = pyjulia_argval($y)" for (x,y) in zip(argnames, argnames2)];
                lines;
            ]
            argnames = argnames2
        end
        println(io, "function $mname($(join(argnames, ", ")))")
        for line in lines
            println(io, "    $line")
        end
        println(io, "end")
    end
    println(io, "# *** THIS FILE IS AUTOMATICALLY GENERATED ***")
    println(io)
    seen = Dict{String, Int}()
    for (S, Sdata) in open(Pkg.TOML.parse, JL_ATTR_TOML)
        for (name, datas) in Sdata
            println(io, "### $S.$name")
            println(io)
            n = seen[name] = get(seen, name, 0) + 1

            # each data in datas is an alternative implementation
            datas isa AbstractVector || (datas = [datas])

            # the kind of each implementation
            kinds = map(datas) do data
                haskey(data, "kind") ? data["kind"] :
                haskey(data, "smeth") ? "special" :
                haskey(data, "meth") ? "method" :
                haskey(data, "get") ? "property" :
                haskey(data, "set") ? "property" :
                error("cannot determine kind")
            end

            # the conditions on each implementation
            all(data->haskey(data,"if"), datas[1:end-1]) || error("all but the final implementation of an attr must have an `if` entry ($S.$name)")
            conds = map(datas) do data
                get(data, "if", nothing)
            end

            # attrkind
            println(io, "pyjulia_attrkind(::Val{:$name}, ::Type{T}) where {T<:$S} =")
            for (cond, kind) in zip(conds, kinds)
                if cond === nothing
                    println(io, "    :$kind")
                else
                    println(io, "    ($cond) ? :$kind :")
                end
            end
            if conds[end] !== nothing
                # if all conditions fail, defer to the supertype, and return nothing at the top type
                if S == "Any"
                    println(io, "    nothing")
                else
                    println(io, "    invoke(pyjulia_attrkind, Tuple{Val{:$name}, Type{_T}} where {_T<:supertype($S)}, Val(:$name), T)")
                end
            end
            println(io)

            # attrdef
            println(io, "pyjulia_attrdef(::Val{:$name}, ::Type{T}) where {T<:$S} =")
            for (i,cond) in enumerate(conds)
                f = "pyjulia_attrdef(Val(:$name), T, $S, Val($i))"
                if cond === nothing
                    println(io, "    $f")
                else
                    println(io, "    ($cond) ? $f :")
                end
            end
            if conds[end] !== nothing
                if S == "Any"
                    println(io, "    error(\"no matching attr\")")
                else
                    println(io, "    invoke(pyjulia_attrdef, Tuple{Val{:$name}, Type{_T}} where {_T<:supertype($S)}, Val(:$name), T)")
                end
            end
            println(io)

            # details of each implementation
            for (i, (data, kind)) in enumerate(zip(datas, kinds))
                attrdefsig = "pyjulia_attrdef(::Val{:$name}, ::Type{T}, ::Type{$S}, ::Val{$i}) where {T<:$S}"
                suffix = "$(name)_$(n)_$(i)"

                if kind == "special"
                    # get fixed information about the attr
                    rettype, argtypes =
                        # destructor
                        if name in ("__dealloc__",)
                            "Cvoid", ("Ptr{CPyJuliaObject{T}}",)
                        # unaryfunc
                        elseif name in ("__repr__", "__str__", "__iter__", "__next__", "__int__", "__float__", "__index__", "__neg__", "__pos__", "__abs__", "__invert__")
                            "PyPtr", ("Ptr{CPyJuliaObject{T}}",)
                        # binaryfunc, getattrofunc
                        elseif name in ("__getitem__", "__concat__", "__iconcat__", "__getattr__")
                            "PyPtr", ("Ptr{CPyJuliaObject{T}}", "PyPtr",)
                        # binaryfunc (self can be anywhere)
                        elseif name in ("__add__",)
                            "PyPtr", ("PyPtr", "PyPtr")
                        # ternaryfunc (self can be anywhere)
                        elseif name in ("__pow__", "__ipow__")
                            "PyPtr", ("PyPtr", "PyPtr", "PyPtr")
                        # ssizeargfunc
                        elseif name in ("__getitem_int__", "__repeat__", "__irepeat__")
                            "PyPtr", ("Ptr{CPyJuliaObject{T}}", "CPy_ssize_t",)
                        # getattrfunc
                        elseif name in ("__getattr_str__",)
                            "PyPtr", ("Ptr{CPyJuliaObject{T}}", "Cstring",)
                        # inquiry
                        elseif name in ("__bool__",)
                            "Cint", ("Ptr{CPyJuliaObject{T}}",)
                        elseif name in ("__contains__",)
                            "Cint", ("Ptr{CPyJuliaObject{T}}", "PyPtr")
                        # objobjargproc, setattrofunc
                        elseif name in ("__setitem__", "__setattr__")
                            "Cint", ("Ptr{CPyJuliaObject{T}}", "PyPtr", "PyPtr")
                        # ssizeobjargproc
                        elseif name in ("__setitem_int__",)
                            "Cint", ("Ptr{CPyJuliaObject{T}}", "CPy_ssize_t", "PyPtr")
                        # setattrfunc
                        elseif name in ("__setattr_str__",)
                            "Cint", ("Ptr{CPyJuliaObject{T}}", "Cstring", "PyPtr")
                        # hashfunc
                        elseif name in ("__hash__",)
                            "CPy_hash_t", ("Ptr{CPyJuliaObject{T}}",)
                        # lenfunc
                        elseif name in ("__len__",)
                            "CPy_ssize_t", ("Ptr{CPyJuliaObject{T}}",)
                        else
                            error("unrecognized special attr: $name")
                        end

                    mname = "pyjulia_implmethod_$suffix"
                    printmethod(io, mname, data, "smeth", rettype, length(argtypes))
                    println(io)
                    println(io, "$attrdefsig =")
                    println(io, "    @cfunction($mname, $rettype, ($(join(argtypes, ", "))$(length(argtypes)==1 ? "," : "")))")
                    println(io)

                elseif kind == "method"
                    flags = zero(UInt)
                    args = missing
                    for flag in get(data, "flags", [])
                        if flag == "class"
                            error("class methods not implemented")
                            flags |= CPy_METH_CLASS
                        elseif flag == "static"
                            error("static methods not implemented")
                            flags |= CPy_METH_STATIC
                        elseif flag in ("noargs", "onearg", "varargs", "kwargs")
                            args = flag
                        else
                            error("invalid flag: $args")
                        end
                    end
                    args === missing && error("number of arguments not specified")
                    argtypes = ("Ptr{CPyJuliaObject{T}}", "PyPtr")
                    dropargs = Int[]
                    if args == "noargs"
                        flags |= CPy_METH_NOARGS
                        push!(dropargs, 2)
                    elseif args == "onearg"
                        flags |= CPy_METH_O
                    elseif args == "varargs"
                        flags |= CPy_METH_VARARGS
                    elseif args == "kwargs"
                        flags |= CPy_METH_KEYWORDS
                        argtypes = (argtypes..., "PyPtr")
                    else
                        error("invalid args specification")
                    end
                    mname = "pyjulia_implmethod_$suffix"
                    printmethod(io, mname, data, "meth", "PyPtr", length(argtypes), dropargs=dropargs)
                    println(io)
                    lines = [
                        "name = $(repr(name))",
                        "meth = @cfunction($mname, PyPtr, ($(join(argtypes, ", "))))",
                        "flags = $(repr(flags))",
                    ]
                    if haskey(data, "doc")
                        push!(lines, "doc = $(repr(data["doc"]))")
                    end
                    println(io, "$attrdefsig = (")
                    for line in lines
                        println(io, "    $line,")
                    end
                    println(io, ")")
                    println(io)

                elseif kind == "property"
                    lines = [
                        "name = $(repr(name))"
                    ]
                    if haskey(data, "get")
                        gname = "pyjulia_implgetter_$suffix"
                        printmethod(io, gname, data, "get", "PyPtr", 2, dropargs=2)
                        println(io)
                        push!(lines, "get = @cfunction($gname, PyPtr, (Ptr{CPyJuliaObject{T}}, Ptr{Cvoid}))")
                    end
                    if haskey(data, "set")
                        sname = "pyjulia_implsetter_$suffix"
                        printmethod(io, sname, data, "set", "PyPtr", 3, dropargs=3)
                        println(io)
                        push!(lines, "set = @cfunction($sname, PyPtr, (Ptr{CPyJuliaObject{T}}, PyPtr, Ptr{Cvoid}))")
                    end
                    if haskey(data, "doc")
                        push!(lines, "doc = $(repr(data["doc"]))")
                    end
                    println(io, "$attrdefsig = (")
                    for line in lines
                        println(io, "    $line,")
                    end
                    println(io, ")")
                    println(io)
                else
                    error("unknown kind: $kind")
                end
            end
            println(io)
        end
    end
end

include_dependency("julia_attrs.toml")
include("julia_attrs.jl")

pyjulia_retval(x) = x
pyjulia_retval(x::AbstractPyRef) = (incref!(x); ptr(x))
pyjulia_retval(x::AbstractPyObject) = pyjulia_retval(PyRef(x))

pyjulia_argval(x) = x
pyjulia_argval(x::Ptr{<:AbstractCPyObject}) = PyBorrowedRef(x)
pyjulia_argval(x::Ptr{<:CPyJuliaObject}) = _unsafe_pyjulia_getvalue(PyBorrowedRef(x))

### NUMPY

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
            # TODO
        end
    end
    return unsafe_pystr(typestr), descr, sz

    @label err
    return PYNULL, PYNULL, 0
end

### ABCs
pyjulia_abc(::Type) = nothing

### Numeric ABCs
pyjulia_abc(::Type{Number}) = "numbers.Number"
pyjulia_abc(::Type{Complex}) = "numbers.Complex"
pyjulia_abc(::Type{Real}) = "numbers.Real"
pyjulia_abc(::Type{Rational{T}}) where {T} = "numbers.Rational"
pyjulia_abc(::Type{Integer}) = "numbers.Integral"

### IO ABCs
# We wrap IO as RawIOBase and have subclasses for RawIOBase, BufferedIOBase and TextIOBase. By default we use TextIOWrapper (NOT AsPyTextIO) to create TextIO objects.
pyjulia_abc(::Type{IO}) = "io.IOBase"
pyjulia_abc(::Type{AsPyRawIO{T}}) where {T} = "io.RawIOBase"
pyjulia_abc(::Type{AsPyBufferedIO{T}}) where {T} = "io.BufferedIOBase"
pyjulia_abc(::Type{AsPyTextIO{T}}) where {T} = "io.TextIOBase"

### Container ABCs
pyjulia_abc(::Type{AbstractVector{T}}) where {T} = "collections.abc.Sequence"
pyjulia_abc(::Type{AbstractArray{T,N}}) where {T,N} = "collections.abc.Collection"
pyjulia_abc(::Type{AbstractDict{K,V}}) where {K,V} = "collections.abc.Mapping"
pyjulia_abc(::Type{AbstractSet{T}}) where {T} = "collections.abc.Set"
pyjulia_abc(::Type{Base.KeySet{K,D}}) where {K,D} = "collections.abc.KeysView"
pyjulia_abc(::Type{Base.ValueIterator{D}}) where {D} = "collections.abc.ValuesView"
pyjulia_abc(::Type{PairSet{K,V,D}}) where {K,V,D} = "collections.abc.ItemsView"
