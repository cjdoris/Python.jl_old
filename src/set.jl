_pysettype = pynulltype()
unsafe_pysettype() =
    @unsafe_cacheget_object _pysettype :PySet_Type
pysettype() = safe(unsafe_pysettype())
export pysettype

unsafe_pyset_new() =
    @cpycall :PySet_New(C_NULL::Ptr{Cvoid})::CPyNewPtr

_pyfrozensettype = pynulltype()
unsafe_pyfrozensettype() =
    @unsafe_cacheget_object _pyfrozensettype :PyFrozenSet_Type
pyfrozensettype() = safe(unsafe_pyfrozensettype())
export pyfrozensettype

unsafe_pyfrozenset_new() =
    @cpycall :PyFrozenSet_New(C_NULL::Ptr{Cvoid})::CPyNewPtr

unsafe_pyset_add(o::PyObject, v::PyObject) =
    (isnull(o) || isnull(v)) ? CPyVoidInt() :
    @cpycall :PySet_Add(o::CPyPtr, v::CPyPtr)::CPyVoidInt
unsafe_pyset_add(o::PyObject, v) =
    unsafe_pyset_add(unsafe_pyobj(o), unsafe_pyobj(v))

function unsafe_pyset_fromiter(xs)
    t = unsafe_pyset_new()
    isnull(t) && return pynull()
    for x in xs
        iserr(unsafe_pyset_add(t, x)) && return pynull()
    end
    return t
end
pyset_fromiter(xs) =
    safe(unsafe_pyset_fromiter(xs))
export pyset_fromiter

function unsafe_pyfrozenset_fromiter(xs)
    t = unsafe_pyfrozenset_new()
    isnull(t) && return pynull()
    for x in xs
        iserr(unsafe_pyset_add(t, x)) && return pynull()
    end
    return t
end
pyfrozenset_fromiter(xs) =
    safe(unsafe_pyfrozenset_fromiter(xs))
export pyfrozenset_fromiter

unsafe_pyset(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pysettype(), args, kwargs)
pyset(args...; kwargs...) =
    safe(unsafe_pyset(args...; kwargs...))
export pyset

unsafe_pyfrozenset(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pyfrozensettype(), args, kwargs)
pyfrozenset(args...; kwargs...) =
    safe(unsafe_pyfrozenset(args...; kwargs...))
export pyfrozenset
