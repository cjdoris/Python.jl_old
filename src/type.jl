unsafe_pytype_ptr(o) = uptr(CPyObject, o).type[Ptr]

function unsafe_pytype(o)
    if !(o isa AbstractPyRef)
        o = unsafe_pyobj(o)
        isnull(o) && return PYNULL
    end
    return unsafe_pyobj(PyRef(unsafe_pytype_ptr(o), true))
end

unsafe_pytype_checkexact(o, t) = unsafe_pytype_ptr(o) == ptr(t)

unsafe_pytype_issubtype(t1, t2) = !iszero(ccall((:PyType_IsSubtype, PYLIB), Cint, (PyPtr, PyPtr), t1, t2))

unsafe_pytype_check(o, t) = unsafe_pytype_issubtype(unsafe_pytype_ptr(o), t)

unsafe_pytype_issubtype_fast(t, f) = unsafe_pytype_hasfeature(t, f)

unsafe_pytype_check_fast(o, f) = unsafe_pytype_issubtype_fast(unsafe_pytype_ptr(o), f)

unsafe_pytype_hasfeature(t, f) = !iszero(unsafe_pytype_getflags(t) & f)

unsafe_pytype_getflags(t) = uptr(CPyTypeObject, t).flags[]
