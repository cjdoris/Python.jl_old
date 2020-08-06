abstract type AbstractCPySliceObject <: AbstractCPyObject end

Base.@kwdef struct CPySliceObject <: AbstractCPySliceObject
    base :: CPyObject = CPyObject()
    start :: PyPtr = C_NULL
    stop :: PyPtr = C_NULL
    step :: PyPtr = C_NULL
end

_unsafe_pyslice_start(o::AbstractPyRef) =
    PyBorrowedRef(uptr(CPySliceObject, o).start[])
_unsafe_pyslice_stop(o::AbstractPyRef) =
    PyBorrowedRef(uptr(CPySliceObject, o).stop[])
_unsafe_pyslice_step(o::AbstractPyRef) =
    PyBorrowedRef(uptr(CPySliceObject, o).step[])
