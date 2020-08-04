_unsafe_pytype(o) = PyBorrowedRef{CPyTypeObject}(uptr(CPyObject, o).type[Ptr])

_unsafe_pytype_checkexact(o, t) = ptr(_unsafe_pytype(o)) == ptr(t)

_unsafe_pytype_issubtype(t1, t2) = !iszero(ccall((:PyType_IsSubtype, PYLIB), Cint, (PyPtr, PyPtr), t1, t2))

_unsafe_pytype_check(o, t) = _unsafe_pytype_issubtype(_unsafe_pytype(o), t)

_unsafe_pytype_issubtype_fast(t, f) = _unsafe_pytype_hasfeature(t, f)

_unsafe_pytype_check_fast(o, f) = _unsafe_pytype_issubtype_fast(_unsafe_pytype(o), f)

_unsafe_pytype_hasfeature(t, f) = !iszero(_unsafe_pytype_getflags(t) & f)

_unsafe_pytype_getflags(t) = uptr(CPyTypeObject, t).flags[]
_unsafe_pytype_getname(t) = unsafe_string(uptr(CPyTypeObject, t).name[])

function unsafe_pytype(o)
    if !(o isa AbstractPyRef)
        o = unsafe_pyobj(o)
        isnull(o) && return PYNULL
    end
    return unsafe_pyobj(_unsafe_pytype(o))
end

unsafe_pytype_check(o::AbstractPyRef, t::AbstractPyRef) = _unsafe_pytype_check(o, t)
unsafe_pytype_check(o, t::AbstractPyRef) = false

unsafe_pytype_checkexact(o::AbstractPyRef, t::AbstractPyRef) = _unsafe_pytype_checkexact(o, t)
unsafe_pytype_checkexact(o, t::AbstractPyRef) = false

unsafe_pytype_check_fast(o::AbstractPyRef, t::Integer) = _unsafe_pytype_check_fast(o, t)
unsafe_pytype_check_fast(o, t::Integer) = false
