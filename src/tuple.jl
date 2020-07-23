_pytupletype = pynulltype()
unsafe_pytupletype() =
    @unsafe_cacheget_object _pytupletype :PyTuple_Type
pytupletype() = safe(unsafe_pytupletype())
export pytupletype

unsafe_pytuple_new(len=0) =
    @cpycall :PyTuple_New(len::CPy_ssize_t)::CPyNewPtr

unsafe_pytuple_setitem(o::PyObject, i, v::PyObject) =
    @cpycall :PyTuple_SetItem(o::CPyPtr, i::CPy_ssize_t, v::CPyStealPtr)::CPyInt
unsafe_pytuple_setitem(o, i, v) =
    unsafe_pytuple_setitem(unsafe_pyobj(o), i, unsafe_pyobj(v))

function unsafe_pytuple_fromiter(xs)
    t = unsafe_pytuple_new(length(xs))
    isnull(t) && return pynull()
    for (i,x) in enumerate(xs)
        iserr(unsafe_pytuple_setitem(t, i-1, x)) && return pynull()
    end
    return t
end
pytuple_fromiter(xs) = safe(unsafe_pytuple_fromiter(xs))
export pytuple_fromiter

unsafe_pytuple(args...; kwargs...) = unsafe_pycall_args(unsafe_pytupletype(), args, kwargs)
pytuple(args...; kwargs...) = safe(unsafe_pytuple(args...; kwargs...))
export pytuple
