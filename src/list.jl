_pylisttype = pynulltype()
unsafe_pylisttype() =
    @unsafe_cacheget_object _pylisttype :PyList_Type
pylisttype() = safe(unsafe_pylisttype())
export pylisttype

unsafe_pylist_new(len=0) =
    @cpycall :PyList_New(len::CPy_ssize_t)::CPyNewPtr

unsafe_pylist_append(o::PyObject, x::PyObject) =
    (isnull(o) || isnull(x)) ? CPyVoidInt() :
    @cpycall :PyList_Append(o::CPyPtr, x::CPyPtr)::CPyVoidInt
unsafe_pylist_append(o::PyObject, x) =
    unsafe_pylist_append(o, unsafe_pyobj(x))

function unsafe_pylist_fromiter(xs)
    t = unsafe_pylist_new()
    isnull(t) && return pynull()
    for x in xs
        iserr(unsafe_pylist_append(t, x)) && return pynull()
    end
    return t
end
pylist_fromiter(xs) =
    safe(unsafe_pylist_fromiter(xs))
export pylist_fromiter

unsafe_pylist(args...; kwargs...) = unsafe_pycall_args(unsafe_pylisttype(), args, kwargs)
pylist(args...; kwargs...) = safe(unsafe_pylist(args...; kwargs...))
export pylist
