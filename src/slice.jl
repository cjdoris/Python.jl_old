abstract type AbstractCPySliceObject <: AbstractCPyObject end

Base.@kwdef struct CPySliceObject <: AbstractCPySliceObject
    base :: CPyObject = CPyObject()
    start :: PyPtr = C_NULL
    stop :: PyPtr = C_NULL
    step :: PyPtr = C_NULL
end

unsafe_pyslice_start(o::PyObject) =
    isnull(o) ? PYNULL : unsafe_pyobj(PyRef(uptr(CPySliceObject, o).start[], true))
unsafe_pyslice_stop(o::PyObject) =
    isnull(o) ? PYNULL : unsafe_pyobj(PyRef(uptr(CPySliceObject, o).stop[], true))
unsafe_pyslice_step(o::PyObject) =
    isnull(o) ? PYNULL : unsafe_pyobj(PyRef(uptr(CPySliceObject, o).step[], true))
