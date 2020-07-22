const _pynone = pynull()
unsafe_pynone() = @unsafe_cacheget_object _pynone :_Py_NoneStruct
pynone() = safe(unsafe_pynone())
export pynone

const _pynonetype = pynull(CPyTypeObject)
unsafe_pynonetype() = unsafe_cacheget!(_pynonetype) do
    unsafe_pytype(unsafe_pynone())
end
pynonetype() = safe(unsafe_pynonetype())
export pynonetype

pyisnone(o::PyObject) = pyis(o, pynone())
export pyisnone
