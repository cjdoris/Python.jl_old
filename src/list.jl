_pylisttype = pynulltype()
unsafe_pylisttype() =
    @unsafe_cacheget_object _pylisttype :PyList_Type
pylisttype() = safe(unsafe_pylisttype())
export pylisttype

unsafe_pylist_new(len=0) =
    @cpycall :PyList_New(len::CPy_ssize_t)::CPyNewPtr

unsafe_pylist(args...; kwargs...) = unsafe_pycall_args(unsafe_pylisttype(), args, kwargs)
pylist(args...; kwargs...) = safe(unsafe_pylist(args...; kwargs...))
export pylist
