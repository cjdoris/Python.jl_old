"""
    AbstractPyRef{T<:AbstractCPyObject}

Abstract type for objects whose main function is to hold a reference to a Python object.

All subtypes must implement `ptr(r)`, returning `Ptr{T}`.

Subtypes include `PyRef`, `PyBorrowedRef`, `AbstractPyObject` and `PyObject`.
"""
abstract type AbstractPyRef{T<:AbstractCPyObject} end

decref(o::AbstractPyRef) = (ccall((:Py_DecRef, PYLIB), Cvoid, (PyPtr,), ptr(o)); o)
incref(o::AbstractPyRef) = (ccall((:Py_IncRef, PYLIB), Cvoid, (PyPtr,), ptr(o)); o)
refcnt(o::AbstractPyRef) = uptr(CPyObject, o).refcnt[]
iserr(o::AbstractPyRef) = isnull(o)
value(o::AbstractPyRef) = o
Base.unsafe_convert(::Type{T}, o::AbstractPyRef) where {T<:Ptr} = T(ptr(o))

"""
    PyRef(ptr, isborrowed)

Holds a single reference to the Python object pointed to by `ptr`, which is automatically decref'd on garbage collection.

If `isborrowed` is true, then `ptr` is a borrowed reference so is `incref`ed first. Otherwise `ptr` is a new reference so is not `incref`ed.
"""
mutable struct PyRef <: AbstractPyRef{CPyObject}
    ptr :: PyPtr
    function PyRef(p::Ptr, isborrowed::Bool)
        r = new(PyPtr(p))
        isborrowed && incref(r)
        finalizer(decref, r)
        return r
    end
end

PyRef(p::UnsafePtr, isborrowed::Bool) = PyRef(ptr(p), isborrowed)
PyRef(o::PyRef) = o
PyRef(o::AbstractPyRef) = PyRef(ptr(o), true)
PyRef() = PyRef(C_NULL, false)

ptr(o::PyRef) = o.ptr

setptr!(o::PyRef, ptr::Ptr, isborrowed::Bool) =
    (decref(o); o.ptr = ptr; isborrowed && incref(o); o)

"""
    PyBorrowedRef(ptr)

Holds a single *borrowed* reference to the Python object pointed to by `ptr`.

It is the user's responsibility to ensure the object remains valid for the lifetime of this reference --- no `incref` or `decref` automatically occurs.
"""
struct PyBorrowedRef{T} <: AbstractPyRef{T}
    ptr :: Ptr{T}
    PyBorrowedRef{T}(p::Ptr) where {T} = new{T}(Ptr{T}(p))
end
PyBorrowedRef(p::Ptr{T}) where {T<:AbstractCPyObject} = PyBorrowedRef{T}(p)
PyBorrowedRef(p::Ptr) = PyBorrowedRef{CPyObject}(p)
PyBorrowedRef(p::UnsafePtr) = PyBorrowedRef(ptr(p))
PyBorrowedRef(p::PyBorrowedRef) = p
PyBorrowedRef(p::AbstractPyRef) = PyBorrowedRef(ptr(p))
PyBorrowedRef() = PyBorrowedRef(C_NULL)

ptr(o::PyBorrowedRef) = o.ptr
