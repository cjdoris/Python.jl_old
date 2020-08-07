unsafe_pydict_setitem_string(o, k::Symbol, v) =
    unsafe_pydict_setitem_string(o, string(k), v)

function unsafe_pydict_frompairs(kvs)
    d = unsafe_pydict()
    isnull(d) && return PYNULL
    for (k,v) in kvs
        iserr(unsafe_pydict_setitem(d, k, v)) && return PYNULL
    end
    return d
end
pydict_frompairs(kvs) =
    safe(unsafe_pydict_frompairs(kvs))
export pydict_frompairs

function unsafe_pydict_fromstringpairs(kvs)
    d = unsafe_pydict()
    isnull(d) && return PYNULL
    for (k,v) in kvs
        iserr(unsafe_pydict_setitem_string(d, k, v)) && return PYNULL
    end
    return d
end
pydict_fromstringpairs(kvs) =
    safe(unsafe_pydict_fromstringpairs(kvs))
export pydict_fromstringpairs

unsafe_pydict_tryconvert(::Type{T}, o::AbstractPyRef) where {T} =
    unsafe_pyabstractmapping_tryconvert(T, o)
