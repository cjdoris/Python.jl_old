function unsafe_pytype(o)
    if !(o isa PyObject)
        o = unsafe_pyobj(o)
        isnull(o) && return PYNULLTYPE
    end
    return unsafe_pyobj(PyObjRef(uptr(CPyObject, o).type[], true))
end
