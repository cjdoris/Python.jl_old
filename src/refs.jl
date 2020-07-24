"""
    PyObjRef(ptr)

Holds a single reference to the Python object pointed to by `ptr`, which is automatically decref'd on garbage collection.

It basically has no other semantics, these are provided by `PyObject` which wraps this.
"""
mutable struct PyObjRef
    ptr :: Ptr{Cvoid}
    function PyObjRef(p::Ptr, isborrowed::Bool)
        isborrowed && incref(p)
        r = new(Ptr{Cvoid}(p))
        finalizer(decref, r)
        return r
    end
end

PyObjRef(p::UnsafePtr, isborrowed::Bool) = PyObjRef(ptr(p), isborrowed)
PyObjRef(o::PyObjRef) = o
PyObjRef() = PyObjRef(C_NULL, true)
ptr(o::PyObjRef) = o.ptr
refcnt(o::PyObjRef) = uptr(CPyObject, ptr(o)).refcnt[]
decref(o) = (ccall((:Py_DecRef, PYLIB), Cvoid, (Ptr{Cvoid},), ptr(o)); o)
incref(o) = (ccall((:Py_IncRef, PYLIB), Cvoid, (Ptr{Cvoid},), ptr(o)); o)
setptr!(o::PyObjRef, ptr::Ptr, isborrowed::Bool) =
    (isborrowed && incref(ptr); o.ptr = ptr; o)
Base.unsafe_convert(::Type{T}, o::PyObjRef) where {T} = T(ptr(o))
