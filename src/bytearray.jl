_pybytearraytype = pynulltype()
unsafe_pybytearraytype() =
    @unsafe_cacheget_object _pybytearraytype :PyByteArray_Type
pybytearraytype() = safe(unsafe_pybytearraytype())
export pybytearraytype

unsafe_pybytearray(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pybytearraytype(), args, kwargs)
pybytearray(args...; kwargs...) =
    safe(unsafe_pybytearray(args...; kwargs...))
export pybytearray
