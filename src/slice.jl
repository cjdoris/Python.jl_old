abstract type AbstractCPySliceObject <: AbstractCPyObject end

Base.@kwdef struct CPySliceObject <: AbstractCPySliceObject
    base :: CPyObject = CPyObject()
    start :: Ptr{CPyObject} = C_NULL
    stop :: Ptr{CPyObject} = C_NULL
    step :: Ptr{CPyObject} = C_NULL
end

_pyslicetype = pynulltype()
unsafe_pyslicetype() =
    @unsafe_cacheget_object _pyslicetype :PySlice_Type
pyslicetype() = safe(unsafe_pyslicetype())
export pyslicetype

unsafe_pyslice(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pyslicetype(), args, kwargs)
pyslice(args...; kwargs...) =
    safe(unsafe_pyslice(args...; kwargs...))
export pyslice

unsafe_pyslice_start(o::PyObject) =
    isnull(o) ? pynull() : unsafe_pyobj(PyBorrowedObjRef(uptr(CPySliceObject, o).start[]))
unsafe_pyslice_stop(o::PyObject) =
    isnull(o) ? pynull() : unsafe_pyobj(PyBorrowedObjRef(uptr(CPySliceObject, o).stop[]))
unsafe_pyslice_step(o::PyObject) =
    isnull(o) ? pynull() : unsafe_pyobj(PyBorrowedObjRef(uptr(CPySliceObject, o).step[]))

### Ellipsis

const _pyellipsis = pynull()
unsafe_pyellipsis() = @unsafe_cacheget_object _pyellipsis :_Py_EllipsisObject
pyellipsis() = safe(unsafe_pyellipsis())
export pyellipsis

const _pyellipsistype = pynulltype()
unsafe_pyellipsistype() = unsafe_cacheget!(_pyellipsistype) do
    unsafe_pytype(unsafe_pyellipsis())
end
pyellipsistype() = safe(unsafe_pyellipsistype())
export pyellipsistype
