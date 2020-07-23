_pydicttype = pynulltype()
unsafe_pydicttype() =
    @unsafe_cacheget_object _pydicttype :PyDict_Type
pydicttype() = safe(unsafe_pydicttype())
export pydicttype

unsafe_pydict_new() =
    @cpycall :PyDict_New()::CPyNewPtr

unsafe_pydict_setitem(o::PyObject, k::PyObject, v::PyObject) =
    (isnull(o) || isnull(k) || isnull(v)) ? CPyVoidInt() :
    @cpycall :PyDict_SetItem(o::CPyPtr, k::CPyPtr, v::CPyPtr)::CPyVoidInt
unsafe_pydict_setitem(o, k, v) =
    unsafe_pydict_setitem(unsafe_pyobj(o), unsafe_pyobj(k), unsafe_pyobj(v))

unsafe_pydict_setitem_string(o::PyObject, k::AbstractString, v::PyObject) =
    (isnull(o) || isnull(v)) ? CPyVoidInt() :
    @cpycall :PyDict_SetItemString(o::CPyPtr, k::Cstring, v::CPyPtr)::CPyVoidInt
unsafe_pydict_setitem_string(o, k::Union{AbstractString,Symbol}, v) =
    unsafe_pydict_setitem_string(unsafe_pyobj(o), string(k), unsafe_pyobj(v))

function unsafe_pydict_frompairs(kvs)
    d = unsafe_pydict_new()
    isnull(d) && return pynull()
    for (k,v) in kvs
        iserr(unsafe_pydict_setitem(d, k, v)) && return pynull()
    end
    return d
end
pydict_frompairs(kvs) =
    safe(unsafe_pydict_frompairs(kvs))
export pydict_frompairs

function unsafe_pydict_fromstringpairs(kvs)
    d = unsafe_pydict_new()
    isnull(d) && return pynull()
    for (k,v) in kvs
        iserr(unsafe_pydict_setitem_string(d, k, v)) && return pynull()
    end
    return d
end
pydict_fromstringpairs(kvs) =
    safe(unsafe_pydict_fromstringpairs(kvs))
export pydict_fromstringpairs

unsafe_pydict(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pydicttype(), args, kwargs)
pydict(args...; kwargs...) =
    safe(unsafe_pydict(args...; kwargs...))
export pydict
