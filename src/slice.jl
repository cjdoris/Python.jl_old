abstract type AbstractCPySliceObject <: AbstractCPyObject end

Base.@kwdef struct CPySliceObject <: AbstractCPySliceObject
    base :: CPyObject = CPyObject()
    start :: Ptr{CPyObject} = C_NULL
    stop :: Ptr{CPyObject} = C_NULL
    step :: Ptr{CPyObject} = C_NULL
end

unsafe_pyslice_start(o::PyObject) =
    isnull(o) ? PYNULL : unsafe_pyobj(PyObjRef(uptr(CPySliceObject, o).start[], true))
unsafe_pyslice_stop(o::PyObject) =
    isnull(o) ? PYNULL : unsafe_pyobj(PyObjRef(uptr(CPySliceObject, o).stop[], true))
unsafe_pyslice_step(o::PyObject) =
    isnull(o) ? PYNULL : unsafe_pyobj(PyObjRef(uptr(CPySliceObject, o).step[], true))
