const _pybooltype = pynull(CPyTypeObject)
unsafe_pybooltype() = @unsafe_cacheget_object _pybooltype :PyBool_Type
pybooltype() = safe(unsafe_pybooltype())
export pybooltype

const _pytrue = pynull(CPyObject)
unsafe_pytrue() = @unsafe_cacheget_object _pytrue :_Py_TrueStruct
pytrue() = safe(unsafe_pytrue())
export pytrue

const _pyfalse = pynull(CPyObject)
unsafe_pyfalse() = @unsafe_cacheget_object _pyfalse :_Py_FalseStruct
pyfalse() = safe(unsafe_pyfalse())
export pyfalse

pyisbool(o::PyObject) = pyis(pytype(o), pybooltype())
pyisbool(o) = pyisbool(PyObject(o))
export pyisbool

unsafe_pybool() = unsafe_pyfalse()
unsafe_pybool(o::Bool) = o ? unsafe_pytrue() : unsafe_pyfalse()
unsafe_pybool(o::CPyBool) = iserr(o) ? pynull() : unsafe_pybool(value(o))
unsafe_pybool(o::Integer) = unsafe_pybool(!iszero(o))
unsafe_pybool(o::PyObject) = unsafe_pybool(unsafe_pyistrue(o))
unsafe_pybool(o) = unsafe_pybool(unsafe_pyobj(o))
unsafe_pybool(args...; kwargs...) = unsafe_pycall_args(unsafe_pybooltype(), args, kwargs)
pybool(args...; kwargs...) = safe(unsafe_pybool(args...; kwargs...))
export pybool
