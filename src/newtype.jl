### HELPERS FOR CACHEING VALUES TO PREVENT GC

newcache() = []

function cache!(cache, T, x)
    # don't need to cache bits values
    isbits(x) && return x
    # cache the rest
    y = Base.cconvert(T, x)
    push!(cache, y)
    return Base.unsafe_convert(T, y)
end

cachestr!(cache, x) = cache!(cache, Cstring, x===nothing ? C_NULL : x)
cacheptr!(cache, x) = cache!(cache, Ptr{Cvoid}, x===nothing ? C_NULL : x)

mergecache!(x, y) = append!(x, y)

### METHOD DEF

function newpymethoddef(; name, meth, doc=nothing, opts...)
    cache = newcache()
    name = cachestr!(cache, name)
    doc  = cachestr!(cache, doc)
    meth = cacheptr!(cache, meth isa Union{Ptr, Base.CFunction} ? meth : @cfunction($meth, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid})))
    CPyMethodDefStruct(; name=name, doc=doc, meth=meth, opts...), cache
end
newpymethoddef(x::NamedTuple) = newpymethoddef(; x...)

### MEMBER DEF

function newpymemberdef(; name, typ, offset, doc=nothing, opts...)
    cache = newcache()
    name = cachestr!(cache, name)
    doc  = cachestr!(cache, doc)
    CPyMemberDefStruct(; name=name, doc=doc, typ=typ, offset=offset, opts...), cache
end
newpymemberdef(x::NamedTuple) = newpymemberdef(; x...)

### GETSET DEF

function newpygetsetdef(; name, get, set=C_NULL, doc=nothing, opts...)
    cache = newcache()
    name = cachestr!(cache, name)
    doc  = cachestr!(cache, doc)
    get  = cacheptr!(cache, get isa Union{Ptr, Base.CFunction} ? get : @cfunction($get, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid})))
    set  = cacheptr!(cache, set isa Union{Ptr, Base.CFunction} ? set : @cfunction($set, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})))
    CPyGetSetDefStruct(; name=name, doc=doc, get=get, set=set, opts...), cache
end
newpygetsetdef(x::NamedTuple) = newpygetsetdef(; x...)

### NUMBER METHODS

function newpynumbermethods(; opts...)
    c = newcache()
    newopts = Dict()
    for (n, x) in pairs(opts)
        y = x isa Union{Ptr, Base.CFunction} ? x :
            n in (:add, :subtract, :multiply, :remainder, :divmod, :lshift, :rshift, :and, :xor, :or, :inplace_add, :inplace_subtract, :inplace_multiply, :inplace_remainder, :inplace_divmod, :inplace_lshift, :inplace_rshift, :inplace_and, :inplace_xor, :inplace_or, :floordivide, :truedivide, :inplace_floordivide, :inplace_truedivide, :matrix_multiply, :inplace_matrix_multiply) ?
                @cfunction($x, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid})) :
            n in (:power, :inplace_power) ?
                @cfunction($x, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})) :
            n in (:negative, :positive, :absolute, :invert, :int, :float, :index) ?
                @cfunction($x, Ptr{Cvoid}, (Ptr{Cvoid},)) :
            n == :bool ?
                @cfunction($x, Cint, (Ptr{Cvoid},)) :
            error("invalid number method: $n")
        newopts[n] = cacheptr!(c, y)
    end
    CPyNumberMethodsStruct(; newopts...), c
end
newpynumbermethods(x::NamedTuple) = newpynumbermethods(; x...)

### SEQUENCE METHODS

function newpysequencemethods(; opts...)
    c = newcache()
    newopts = Dict()
    for (n, x) in pairs(opts)
        y = x isa Union{Ptr, Base.CFunction} ? x :
            n == :length ?
                @cfunction($x, CPy_ssize_t, (Ptr{Cvoid},)) :
            n in (:concat, :inplace_concat) ?
                @cfunction($x, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid})) :
            n in (:repeat, :inplace_repeat, :item) ?
                @cfunction($x, Ptr{Cvoid}, (Ptr{Cvoid}, CPy_ssize_t)) :
            n == :ass_item ?
                @cfunction($x, Cint, (Ptr{Cvoid}, CPy_ssize_t, Ptr{Cvoid})) :
            n == :contains ?
                @cfunction($x, Cint, (Ptr{Cvoid}, Ptr{Cvoid})) :
            error("invalid sequence method: $n")
        newopts[n] = cacheptr!(c, y)
    end
    CPySequenceMethodsStruct(; newopts...), c
end
newpysequencemethods(x::NamedTuple) = newpysequencemethods(; x...)

### MAPPING METHODS

function newpymappingmethods(; opts...)
    c = newcache()
    newopts = Dict()
    for (n, x) in pairs(opts)
        y = x isa Union{Ptr, Base.CFunction} ? x :
            n == :length ?
                @cfunction($x, CPy_ssize_t, (Ptr{Cvoid},)) :
            n == :subscript ?
                @cfunction($x, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid})) :
            n == :length ?
                @cfunction($x, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid})) :
            error("invalid mapping method: $n")
        newopts[n] = cacheptr!(c, y)
    end
    CPyMappingMethodsStruct(; newopts...), c
end
newpymappingmethods(x::NamedTuple) = newpymappingmethods(; x...)

### TYPE

function pytypeflags(; stackless=PYISSTACKLESS, versiontag=false, getcharbuffer=false, sequencein=false, inplaceops=false, richcompare=false, weakrefs=false, iter=false, class=false, index=false, basetype=false)
    flags = UInt64(0)
    if PYVERSION.major ≥ 3
        versiontag    && (flags |= Py_TPFLAGS_HAVE_VERSION_TAG)
    else
        getcharbuffer && (flags |= Py_TPFLAGS_HAVE_GETCHARBUFFER)
        sequencein    && (flags |= Py_TPFLAGS_HAVE_SEQUENCE_IN)
        inplaceops    && (flags |= Py_TPFLAGS_HAVE_INPLACEOPS)
        richcompare   && (flags |= Py_TPFLAGS_HAVE_RICHCOMPARE)
        weakrefs      && (flags |= Py_TPFLAGS_HAVE_WEAKREFS)
        iter          && (flags |= Py_TPFLAGS_HAVE_ITER)
        class         && (flags |= Py_TPFLAGS_HAVE_CLASS)
        index         && (flags |= Py_TPFLAGS_HAVE_INDEX)
    end
    basetype          && (flags |= Py_TPFLAGS_BASETYPE)
    stackless         && (flags |= Py_TPFLAGS_HAVE_STACKLESS_EXTENSION)
    return flags
end
pytypeflags(x::Integer) = x
pytypeflags(x::NamedTuple) = pytypeflags(;x...)

function newpytype(; type=C_NULL, name, basicsize, flags=pytypeflags(), new=cglobal((:PyType_GenericNew, PYLIB)), methods=C_NULL, members=C_NULL, getset=C_NULL, as_number=C_NULL, as_sequence=C_NULL, as_mapping=C_NULL, opts...)
    cache = newcache()
    name = cachestr!(cache, name)
    flags = pytypeflags(flags)
    type = cacheptr!(cache, type)
    methods =
        if methods isa Ptr
            methods
        else
            ms = CPyMethodDefStruct[]
            for m in methods
                m, c = newpymethoddef(m)
                push!(ms, m)
                mergecache!(cache, c)
            end
            push!(ms, CPyMethodDefStruct())
            cacheptr!(cache, ms)
        end
    members =
        if members isa Ptr
            members
        else
            ms = CPyMemberDefStruct[]
            for m in members
                m, c = newpymemberdef(m)
                push!(ms, m)
                mergecache!(cache, c)
            end
            push!(ms, CPyMemberDefStruct())
            cacheptr!(cache, ms)
        end
    getset =
        if getset isa Ptr
            getset
        else
            ms = CPyGetSetDefStruct[]
            for m in getset
                m, c = newpygetsetdef(m)
                push!(ms, m)
                mergecache!(cache, c)
            end
            push!(ms, CPyGetSetDefStruct())
            cacheptr!(cache, ms)
        end
    as_number =
        if as_number isa Ptr
            as_number
        else
            m, c = newpynumbermethods(as_number)
            mergecache!(cache, c)
            cacheptr!(cache, fill(m))
        end
    as_mapping =
        if as_mapping isa Ptr
            as_mapping
        else
            m, c = newpymappingmethods(as_mapping)
            mergecache!(cache, c)
            cacheptr!(cache, fill(m))
        end
    as_sequence =
        if as_sequence isa Ptr
            as_sequence
        else
            m, c = newpysequencemethods(as_sequence)
            mergecache!(cache, c)
            cacheptr!(cache, fill(m))
        end
    # generically deal with anything else
    newopts = Dict()
    for (n, x) in pairs(opts)
        if x isa Union{Base.CFunction, PyRef, PyObject, AbstractString}
            newopts[n] = cacheptr!(cache, x)
        else
            newopts[n] = x
        end
    end
    # make the type
    t = CPyTypeObject(; name=name, basicsize=basicsize, flags=flags, new=new,
        methods=methods, members=members, getset=getset, as_number=as_number,
        as_mapping=as_mapping, as_sequence=as_sequence,
        ob_base=CPyVarObject(base=CPyObject(type=type)), newopts...)
    return t, cache
end
