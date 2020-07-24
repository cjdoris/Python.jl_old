pyisbool(o::PyObject) = pyis(pytype(o), pybooltype())
pyisbool(o) = pyisbool(PyObject(o))
export pyisbool

unsafe_pybool() = unsafe_pyfalse()
unsafe_pybool(o::Bool) = o ? unsafe_pytrue() : unsafe_pyfalse()
unsafe_pybool(o::Integer) = unsafe_pybool(!iszero(o))
function unsafe_pybool(o)
    r = unsafe_pyistrue(o)
    iserr(r) && return PYNULL
    unsafe_pybool(value(r))
end
