unsafe_pyset(args...; kwargs...) = unsafe_pycall_args(unsafe_pysettype(), args, kwargs)
pyset(args...; kwargs...) = safe(unsafe_pyset(args...; kwargs...))
export pyset


function unsafe_pyisinstance(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_IsInstance, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
pyisinstance(args...; kwargs...) = safe(unsafe_pyisinstance(args...; kwargs...))
export pyisinstance


function unsafe_pysub(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Subtract, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pysub(args...; kwargs...) = safe(unsafe_pysub(args...; kwargs...))
export pysub


function unsafe_pynot(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_Not, PYLIB), Cint, (Ptr{Cvoid},), x1)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
pynot(args...; kwargs...) = safe(unsafe_pynot(args...; kwargs...))
export pynot


const _pysupertype = pynulltype()
unsafe_pysupertype() = unsafe_cacheget!(_pysupertype) do; cglobal((:PySuper_Type, PYLIB), CPyObject); end
pysupertype(args...; kwargs...) = safe(unsafe_pysupertype(args...; kwargs...))
export pysupertype


const _pytimedeltatype = pynull()
unsafe_pytimedeltatype() = unsafe_cacheget!(_pytimedeltatype) do; unsafe_pygetattr(pydatetimemodule(), "timedelta"); end
pytimedeltatype(args...; kwargs...) = safe(unsafe_pytimedeltatype(args...; kwargs...))
export pytimedeltatype


unsafe_pyhelp(args...; kwargs...) = unsafe_pycall_args(unsafe_pyhelpfunction(), args, kwargs)
pyhelp(args...; kwargs...) = safe(unsafe_pyhelp(args...; kwargs...))
export pyhelp


function unsafe_pydir(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_Dir, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pydir(args...; kwargs...) = safe(unsafe_pydir(args...; kwargs...))
export pydir


const _pytimetype = pynull()
unsafe_pytimetype() = unsafe_cacheget!(_pytimetype) do; unsafe_pygetattr(pydatetimemodule(), "time"); end
pytimetype(args...; kwargs...) = safe(unsafe_pytimetype(args...; kwargs...))
export pytimetype


function unsafe_pytuple_setitem(x1::Any, x2::Any, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return ValueOrError{Nothing}()
    end

    incref(x3)
    r = ccall((:PyTuple_SetItem, PYLIB), Cint, (Ptr{Cvoid}, CPy_ssize_t, Ptr{Cvoid}), x1, x2, x3)
    if r == -1
        decref(x3)
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end


function unsafe_pyinv(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Invert, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyinv(args...; kwargs...) = safe(unsafe_pyinv(args...; kwargs...))
export pyinv


const _pyhelpfunction = pynull()
unsafe_pyhelpfunction() = unsafe_cacheget!(_pyhelpfunction) do; unsafe_pybuiltin("help"); end
pyhelpfunction(args...; kwargs...) = safe(unsafe_pyhelpfunction(args...; kwargs...))


const _pyfalse = pynull()
unsafe_pyfalse() = unsafe_cacheget!(_pyfalse) do; cglobal((:_Py_FalseStruct, PYLIB), CPyObject); end
pyfalse(args...; kwargs...) = safe(unsafe_pyfalse(args...; kwargs...))
export pyfalse


function unsafe_pyior(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceOr, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyior(args...; kwargs...) = safe(unsafe_pyior(args...; kwargs...))
export pyior


unsafe_pyeval(args...; kwargs...) = unsafe_pycall_args(unsafe_pyevalfunction(), args, kwargs)
pyeval(args...; kwargs...) = safe(unsafe_pyeval(args...; kwargs...))
export pyeval


const _pytzinfotype = pynull()
unsafe_pytzinfotype() = unsafe_cacheget!(_pytzinfotype) do; unsafe_pygetattr(pydatetimemodule(), "tzinfo"); end
pytzinfotype(args...; kwargs...) = safe(unsafe_pytzinfotype(args...; kwargs...))
export pytzinfotype


const _pynone = pynull()
unsafe_pynone() = unsafe_cacheget!(_pynone) do; cglobal((:_Py_NoneStruct, PYLIB), CPyObject); end
pynone(args...; kwargs...) = safe(unsafe_pynone(args...; kwargs...))
export pynone


const _pysettype = pynulltype()
unsafe_pysettype() = unsafe_cacheget!(_pysettype) do; cglobal((:PySet_Type, PYLIB), CPyObject); end
pysettype(args...; kwargs...) = safe(unsafe_pysettype(args...; kwargs...))
export pysettype


unsafe_pytimedelta(args...; kwargs...) = unsafe_pycall_args(unsafe_pytimedeltatype(), args, kwargs)
pytimedelta(args...; kwargs...) = safe(unsafe_pytimedelta(args...; kwargs...))
export pytimedelta


function unsafe_pycompare_obj(x1::Any, x2::Any, x3::CPy_CompareOp)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyObject_RichCompare, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, CPy_CompareOp), x1, x2, x3)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pycompare_obj(args...; kwargs...) = safe(unsafe_pycompare_obj(args...; kwargs...))


function unsafe_pyint_fromlonglong(x1::Any)
    r = ccall((:PyLong_FromLongLong, PYLIB), Ptr{Cvoid}, (Clonglong,), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


const _pyobjecttype = pynulltype()
unsafe_pyobjecttype() = unsafe_cacheget!(_pyobjecttype) do; cglobal((:PyBaseObject_Type, PYLIB), CPyObject); end
pyobjecttype(args...; kwargs...) = safe(unsafe_pyobjecttype(args...; kwargs...))
export pyobjecttype


unsafe_pyrange(args...; kwargs...) = unsafe_pycall_args(unsafe_pyrangetype(), args, kwargs)
pyrange(args...; kwargs...) = safe(unsafe_pyrange(args...; kwargs...))
export pyrange


function unsafe_pybytes(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_Bytes, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
unsafe_pybytes(args...; kwargs...) = unsafe_pycall_args(unsafe_pybytestype(), args, kwargs)
pybytes(args...; kwargs...) = safe(unsafe_pybytes(args...; kwargs...))
export pybytes


function unsafe_pytruediv(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_TrueDivide, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pytruediv(args...; kwargs...) = safe(unsafe_pytruediv(args...; kwargs...))
export pytruediv


function unsafe_pyilshift(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceLshift, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyilshift(args...; kwargs...) = safe(unsafe_pyilshift(args...; kwargs...))
export pyilshift


unsafe_pytuple(args...; kwargs...) = unsafe_pycall_args(unsafe_pytupletype(), args, kwargs)
pytuple(args...; kwargs...) = safe(unsafe_pytuple(args...; kwargs...))
export pytuple


const _pylisttype = pynulltype()
unsafe_pylisttype() = unsafe_cacheget!(_pylisttype) do; cglobal((:PyList_Type, PYLIB), CPyObject); end
pylisttype(args...; kwargs...) = safe(unsafe_pylisttype(args...; kwargs...))
export pylisttype


unsafe_pytimezone(args...; kwargs...) = unsafe_pycall_args(unsafe_pytimezonetype(), args, kwargs)
pytimezone(args...; kwargs...) = safe(unsafe_pytimezone(args...; kwargs...))
export pytimezone


function unsafe_pymatmul(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_MatrixMultiply, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pymatmul(args...; kwargs...) = safe(unsafe_pymatmul(args...; kwargs...))
export pymatmul


function unsafe_pyabs(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Absolute, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyabs(args...; kwargs...) = safe(unsafe_pyabs(args...; kwargs...))
export pyabs


function pyerror_set(x1::Any)
    x1 = unsafe_pyobj(x1)
    r = ccall((:PyErr_SetNone, PYLIB), Cvoid, (Ptr{Cvoid},), x1)
    return r
end
function pyerror_set(x1::Any, x2::AbstractString)
    x1 = unsafe_pyobj(x1)
    r = ccall((:PyErr_SetString, PYLIB), Cvoid, (Ptr{Cvoid}, Cstring), x1, x2)
    return r
end
function pyerror_set(x1::Any, x2::Any)
    x1 = unsafe_pyobj(x1)
    x2 = unsafe_pyobj(x2)
    r = ccall((:PyErr_SetObject, PYLIB), Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    return r
end


function unsafe_pyiabs(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceAbsolute, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyiabs(args...; kwargs...) = safe(unsafe_pyiabs(args...; kwargs...))
export pyiabs


function unsafe_pyxor(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Xor, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyxor(args...; kwargs...) = safe(unsafe_pyxor(args...; kwargs...))
export pyxor


function unsafe_pysetitem(x1::Any, x2::Any, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyObject_SetItem, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), x1, x2, x3)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end
pysetitem(args...; kwargs...) = safe(unsafe_pysetitem(args...; kwargs...))
export pysetitem


const _pystrtype = pynulltype()
unsafe_pystrtype() = unsafe_cacheget!(_pystrtype) do; cglobal((:PyUnicode_Type, PYLIB), CPyObject); end
pystrtype(args...; kwargs...) = safe(unsafe_pystrtype(args...; kwargs...))
export pystrtype


function unsafe_pyirshift(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceRshift, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyirshift(args...; kwargs...) = safe(unsafe_pyirshift(args...; kwargs...))
export pyirshift


function unsafe_pyifloordiv(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceFloorDivide, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyifloordiv(args...; kwargs...) = safe(unsafe_pyifloordiv(args...; kwargs...))
export pyifloordiv


function unsafe_pystr_decodeutf8(x1::Any, x2::Any, x3::Any)
    r = ccall((:PyUnicode_DecodeUTF8, PYLIB), Ptr{Cvoid}, (Cstring, CPy_ssize_t, Cstring), x1, x2, x3)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pyisub(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceSubtract, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyisub(args...; kwargs...) = safe(unsafe_pyisub(args...; kwargs...))
export pyisub


function unsafe_pyand(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_And, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyand(args...; kwargs...) = safe(unsafe_pyand(args...; kwargs...))
export pyand


function unsafe_pymod(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Remainder, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pymod(args...; kwargs...) = safe(unsafe_pymod(args...; kwargs...))
export pymod


function unsafe_pylist_new(x1::Any)
    r = ccall((:PyList_New, PYLIB), Ptr{Cvoid}, (CPy_ssize_t,), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pyidivmod(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceDivmod, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyidivmod(args...; kwargs...) = safe(unsafe_pyidivmod(args...; kwargs...))
export pyidivmod


function unsafe_pycompare(x1::Any, x2::Any, x3::CPy_CompareOp)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_RichCompareBool, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, CPy_CompareOp), x1, x2, x3)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
pycompare(args...; kwargs...) = safe(unsafe_pycompare(args...; kwargs...))
export pycompare


const _pytupletype = pynulltype()
unsafe_pytupletype() = unsafe_cacheget!(_pytupletype) do; cglobal((:PyTuple_Type, PYLIB), CPyObject); end
pytupletype(args...; kwargs...) = safe(unsafe_pytupletype(args...; kwargs...))
export pytupletype


function unsafe_pydict_setitem(x1::Any, x2::Any, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyDict_SetItem, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), x1, x2, x3)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end


function unsafe_pysetattr(x1::Any, x2::Any, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyObject_SetAttr, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), x1, x2, x3)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end
function unsafe_pysetattr(x1::Any, x2::AbstractString, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyObject_SetAttrString, PYLIB), Cint, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}), x1, x2, x3)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end
pysetattr(args...; kwargs...) = safe(unsafe_pysetattr(args...; kwargs...))
export pysetattr


const _pyslicetype = pynulltype()
unsafe_pyslicetype() = unsafe_cacheget!(_pyslicetype) do; cglobal((:PySlice_Type, PYLIB), CPyObject); end
pyslicetype(args...; kwargs...) = safe(unsafe_pyslicetype(args...; kwargs...))
export pyslicetype


unsafe_pyexec(args...; kwargs...) = unsafe_pycall_args(unsafe_pyexecfunction(), args, kwargs)
pyexec(args...; kwargs...) = safe(unsafe_pyexec(args...; kwargs...))
export pyexec


const _pydatetimemodule = pynull()
unsafe_pydatetimemodule() = unsafe_cacheget!(_pydatetimemodule) do; pyimport("datetime"); end
pydatetimemodule(args...; kwargs...) = safe(unsafe_pydatetimemodule(args...; kwargs...))
export pydatetimemodule


const _pyfloattype = pynulltype()
unsafe_pyfloattype() = unsafe_cacheget!(_pyfloattype) do; cglobal((:PyFloat_Type, PYLIB), CPyObject); end
pyfloattype(args...; kwargs...) = safe(unsafe_pyfloattype(args...; kwargs...))
export pyfloattype


unsafe_pytzinfo(args...; kwargs...) = unsafe_pycall_args(unsafe_pytzinfotype(), args, kwargs)
pytzinfo(args...; kwargs...) = safe(unsafe_pytzinfo(args...; kwargs...))
export pytzinfo


function unsafe_pydelattr(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyObject_DelAttr, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end
function unsafe_pydelattr(x1::Any, x2::AbstractString)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyObject_DelAttrString, PYLIB), Cint, (Ptr{Cvoid}, Cstring), x1, x2)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end
pydelattr(args...; kwargs...) = safe(unsafe_pydelattr(args...; kwargs...))
export pydelattr


function unsafe_pyrepr(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_Repr, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyrepr(args...; kwargs...) = safe(unsafe_pyrepr(args...; kwargs...))
export pyrepr


function unsafe_pymul(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Multiply, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pymul(args...; kwargs...) = safe(unsafe_pymul(args...; kwargs...))
export pymul


function unsafe_pyipos(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_InplacePositive, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyipos(args...; kwargs...) = safe(unsafe_pyipos(args...; kwargs...))
export pyipos


const _pytypetype = pynulltype()
unsafe_pytypetype() = unsafe_cacheget!(_pytypetype) do; cglobal((:PyType_Type, PYLIB), CPyObject); end
pytypetype(args...; kwargs...) = safe(unsafe_pytypetype(args...; kwargs...))
export pytypetype


function unsafe_pyitruediv(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceTrueDivide, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyitruediv(args...; kwargs...) = safe(unsafe_pyitruediv(args...; kwargs...))
export pyitruediv


function unsafe_pyhasattr(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_HasAttr, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
function unsafe_pyhasattr(x1::Any, x2::AbstractString)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_HasAttrString, PYLIB), Cint, (Ptr{Cvoid}, Cstring), x1, x2)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
pyhasattr(args...; kwargs...) = safe(unsafe_pyhasattr(args...; kwargs...))
export pyhasattr


function pyerror_clear()
    r = ccall((:PyErr_Clear, PYLIB), Cvoid, (), )
    return r
end


function unsafe_pyfrozenset_new(x1::Ptr)
    r = ccall((:PyFrozenSet_New, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pypos(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Positive, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pypos(args...; kwargs...) = safe(unsafe_pypos(args...; kwargs...))
export pypos


function unsafe_pypow(x1::Any, x2::Any, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return PYNULL
    end

    r = ccall((:PyNumber_Power, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), x1, x2, x3)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pypow(args...; kwargs...) = safe(unsafe_pypow(args...; kwargs...))
export pypow


function unsafe_pyimport(x1::AbstractString)
    r = ccall((:PyImport_ImportModule, PYLIB), Ptr{Cvoid}, (Cstring,), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
function unsafe_pyimport(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyImport_Import, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyimport(args...; kwargs...) = safe(unsafe_pyimport(args...; kwargs...))
export pyimport


function unsafe_pyfloat_asdouble(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Cdouble}()
    end

    r = ccall((:PyFloat_AsDouble, PYLIB), Cdouble, (Ptr{Cvoid},), x1)
    if iszero(r + one(r)) && pyerror_occurred()
        return ValueOrError{Cdouble}()
    else
        return ValueOrError{Cdouble}(r)
    end
end


const _pyellipsis = pynull()
unsafe_pyellipsis() = unsafe_cacheget!(_pyellipsis) do; cglobal((:_Py_EllipsisObject, PYLIB), CPyObject); end
pyellipsis(args...; kwargs...) = safe(unsafe_pyellipsis(args...; kwargs...))
export pyellipsis


const _pyevalfunction = pynull()
unsafe_pyevalfunction() = unsafe_cacheget!(_pyevalfunction) do; unsafe_pybuiltin("eval"); end
pyevalfunction(args...; kwargs...) = safe(unsafe_pyevalfunction(args...; kwargs...))


function unsafe_pyiinv(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceInvert, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyiinv(args...; kwargs...) = safe(unsafe_pyiinv(args...; kwargs...))
export pyiinv


const _pyfrozensettype = pynulltype()
unsafe_pyfrozensettype() = unsafe_cacheget!(_pyfrozensettype) do; cglobal((:PyFrozenSet_Type, PYLIB), CPyObject); end
pyfrozensettype(args...; kwargs...) = safe(unsafe_pyfrozensettype(args...; kwargs...))
export pyfrozensettype


function unsafe_pyadd(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Add, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyadd(args...; kwargs...) = safe(unsafe_pyadd(args...; kwargs...))
export pyadd


function unsafe_pycomplex_imagasdouble(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Cdouble}()
    end

    r = ccall((:PyComplex_ImagAsDouble, PYLIB), Cdouble, (Ptr{Cvoid},), x1)
    if iszero(r + one(r)) && pyerror_occurred()
        return ValueOrError{Cdouble}()
    else
        return ValueOrError{Cdouble}(r)
    end
end


const _pybooltype = pynulltype()
unsafe_pybooltype() = unsafe_cacheget!(_pybooltype) do; cglobal((:PyBool_Type, PYLIB), CPyObject); end
pybooltype(args...; kwargs...) = safe(unsafe_pybooltype(args...; kwargs...))
export pybooltype


const _pynonetype = pynulltype()
unsafe_pynonetype() = unsafe_cacheget!(_pynonetype) do; unsafe_pytype(unsafe_pynone()); end
pynonetype(args...; kwargs...) = safe(unsafe_pynonetype(args...; kwargs...))
export pynonetype


function unsafe_pystr_asutf8string(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyUnicode_AsUTF8String, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pylist_append(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyList_Append, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end


function unsafe_pyiter_next(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyIter_Next, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if (r == C_NULL) && pyerror_occurred()
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pydict()
    r = ccall((:PyDict_New, PYLIB), Ptr{Cvoid}, (), )
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
unsafe_pydict(args...; kwargs...) = unsafe_pycall_args(unsafe_pydicttype(), args, kwargs)
pydict(args...; kwargs...) = safe(unsafe_pydict(args...; kwargs...))
export pydict


unsafe_pyfrozenset(args...; kwargs...) = unsafe_pycall_args(unsafe_pyfrozensettype(), args, kwargs)
pyfrozenset(args...; kwargs...) = safe(unsafe_pyfrozenset(args...; kwargs...))
export pyfrozenset


const _pytrue = pynull()
unsafe_pytrue() = unsafe_cacheget!(_pytrue) do; cglobal((:_Py_TrueStruct, PYLIB), CPyObject); end
pytrue(args...; kwargs...) = safe(unsafe_pytrue(args...; kwargs...))
export pytrue


function unsafe_pydict_setitem_string(x1::Any, x2::AbstractString, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyDict_SetItemString, PYLIB), Cint, (Ptr{Cvoid}, Cstring, Ptr{Cvoid}), x1, x2, x3)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end


function unsafe_pydelitem(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    r = ccall((:PyObject_DelItem, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end
pydelitem(args...; kwargs...) = safe(unsafe_pydelitem(args...; kwargs...))
export pydelitem


function unsafe_pyint(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Long, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
unsafe_pyint(args...; kwargs...) = unsafe_pycall_args(unsafe_pyinttype(), args, kwargs)
pyint(args...; kwargs...) = safe(unsafe_pyint(args...; kwargs...))
export pyint


unsafe_pydate(args...; kwargs...) = unsafe_pycall_args(unsafe_pydatetype(), args, kwargs)
pydate(args...; kwargs...) = safe(unsafe_pydate(args...; kwargs...))
export pydate


const _pyinttype = pynulltype()
unsafe_pyinttype() = unsafe_cacheget!(_pyinttype) do; cglobal((:PyLong_Type, PYLIB), CPyObject); end
pyinttype(args...; kwargs...) = safe(unsafe_pyinttype(args...; kwargs...))
export pyinttype


const _pybytearraytype = pynulltype()
unsafe_pybytearraytype() = unsafe_cacheget!(_pybytearraytype) do; cglobal((:PyByteArray_Type, PYLIB), CPyObject); end
pybytearraytype(args...; kwargs...) = safe(unsafe_pybytearraytype(args...; kwargs...))
export pybytearraytype


function unsafe_pydivmod(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Divmod, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pydivmod(args...; kwargs...) = safe(unsafe_pydivmod(args...; kwargs...))
export pydivmod


function unsafe_pyneg(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Negative, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyneg(args...; kwargs...) = safe(unsafe_pyneg(args...; kwargs...))
export pyneg


function unsafe_pygetitem(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyObject_GetItem, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pygetitem(args...; kwargs...) = safe(unsafe_pygetitem(args...; kwargs...))
export pygetitem


function unsafe_pyor(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Or, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyor(args...; kwargs...) = safe(unsafe_pyor(args...; kwargs...))
export pyor


function unsafe_pyindex(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Index, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyindex(args...; kwargs...) = safe(unsafe_pyindex(args...; kwargs...))
export pyindex


function unsafe_pycomplex_realasdouble(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Cdouble}()
    end

    r = ccall((:PyComplex_RealAsDouble, PYLIB), Cdouble, (Ptr{Cvoid},), x1)
    if iszero(r + one(r)) && pyerror_occurred()
        return ValueOrError{Cdouble}()
    else
        return ValueOrError{Cdouble}(r)
    end
end


function unsafe_pyint_aslonglong(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Clonglong}()
    end

    r = ccall((:PyLong_AsLongLong, PYLIB), Clonglong, (Ptr{Cvoid},), x1)
    if iszero(r + one(r)) && pyerror_occurred()
        return ValueOrError{Clonglong}()
    else
        return ValueOrError{Clonglong}(r)
    end
end


function unsafe_pyfloordiv(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_FloorDivide, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyfloordiv(args...; kwargs...) = safe(unsafe_pyfloordiv(args...; kwargs...))
export pyfloordiv


function unsafe_pyhash(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{CPy_hash_t}()
    end

    r = ccall((:PyObject_Hash, PYLIB), CPy_hash_t, (Ptr{Cvoid},), x1)
    if iszero(r + one(r))
        return ValueOrError{CPy_hash_t}()
    else
        return ValueOrError{CPy_hash_t}(r)
    end
end
pyhash(args...; kwargs...) = safe(unsafe_pyhash(args...; kwargs...))
export pyhash


const _pyexecfunction = pynull()
unsafe_pyexecfunction() = unsafe_cacheget!(_pyexecfunction) do; unsafe_pybuiltin("exec"); end
pyexecfunction(args...; kwargs...) = safe(unsafe_pyexecfunction(args...; kwargs...))


function unsafe_pyint_fromulonglong(x1::Any)
    r = ccall((:PyLong_FromUnsignedLongLong, PYLIB), Ptr{Cvoid}, (Clonglong,), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pyerror_ptr()
    r = ccall((:PyErr_Occurred, PYLIB), Ptr{Cvoid}, (), )
    return r
end


function unsafe_pyissubclass(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_IsSubclass, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
pyissubclass(args...; kwargs...) = safe(unsafe_pyissubclass(args...; kwargs...))
export pyissubclass


const _pyrangetype = pynull()
unsafe_pyrangetype() = unsafe_cacheget!(_pyrangetype) do; unsafe_pybuiltin("range"); end
pyrangetype(args...; kwargs...) = safe(unsafe_pyrangetype(args...; kwargs...))
export pyrangetype


const _pytimezonetype = pynull()
unsafe_pytimezonetype() = unsafe_cacheget!(_pytimezonetype) do; unsafe_pygetattr(pydatetimemodule(), "timezone"); end
pytimezonetype(args...; kwargs...) = safe(unsafe_pytimezonetype(args...; kwargs...))
export pytimezonetype


function unsafe_pyint_asulonglong(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Culonglong}()
    end

    r = ccall((:PyLong_AsUnsignedLongLong, PYLIB), Culonglong, (Ptr{Cvoid},), x1)
    if iszero(r + one(r)) && pyerror_occurred()
        return ValueOrError{Culonglong}()
    else
        return ValueOrError{Culonglong}(r)
    end
end


const _pyfractionsmodule = pynull()
unsafe_pyfractionsmodule() = unsafe_cacheget!(_pyfractionsmodule) do; pyimport("fractions"); end
pyfractionsmodule(args...; kwargs...) = safe(unsafe_pyfractionsmodule(args...; kwargs...))
export pyfractionsmodule


function pyerror_givenexceptionmatches(x1::Any, x2::Any)
    x1 = unsafe_pyobj(x1)
    x2 = unsafe_pyobj(x2)
    r = ccall((:PyErr_GivenExceptionMatches, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    return (r != 0)
end


const _pybytestype = pynulltype()
unsafe_pybytestype() = unsafe_cacheget!(_pybytestype) do; cglobal((:PyBytes_Type, PYLIB), CPyObject); end
pybytestype(args...; kwargs...) = safe(unsafe_pybytestype(args...; kwargs...))
export pybytestype


const _pybuiltinsmodule = pynull()
unsafe_pybuiltinsmodule() = unsafe_cacheget!(_pybuiltinsmodule) do; pyimport("builtins"); end
pybuiltinsmodule(args...; kwargs...) = safe(unsafe_pybuiltinsmodule(args...; kwargs...))
export pybuiltinsmodule


const _pycomplextype = pynulltype()
unsafe_pycomplextype() = unsafe_cacheget!(_pycomplextype) do; cglobal((:PyComplex_Type, PYLIB), CPyObject); end
pycomplextype(args...; kwargs...) = safe(unsafe_pycomplextype(args...; kwargs...))
export pycomplextype


function unsafe_pyfloat(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_Float, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
function unsafe_pyfloat(x1::Real)
    r = ccall((:PyFloat_FromDouble, PYLIB), Ptr{Cvoid}, (Cdouble,), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
unsafe_pyfloat(args...; kwargs...) = unsafe_pycall_args(unsafe_pyfloattype(), args, kwargs)
pyfloat(args...; kwargs...) = safe(unsafe_pyfloat(args...; kwargs...))
export pyfloat


function unsafe_pytruth(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Bool}()
    end

    r = ccall((:PyObject_IsTrue, PYLIB), Cint, (Ptr{Cvoid},), x1)
    if r == -1
        return ValueOrError{Bool}()
    else
        return ValueOrError{Bool}(r != 0)
    end
end
pytruth(args...; kwargs...) = safe(unsafe_pytruth(args...; kwargs...))
export pytruth


unsafe_pyobject(args...; kwargs...) = unsafe_pycall_args(unsafe_pyobjecttype(), args, kwargs)
pyobject(args...; kwargs...) = safe(unsafe_pyobject(args...; kwargs...))
export pyobject


function unsafe_pytuple_new(x1::Any)
    r = ccall((:PyTuple_New, PYLIB), Ptr{Cvoid}, (CPy_ssize_t,), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


function unsafe_pyascii(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_ASCII, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyascii(args...; kwargs...) = safe(unsafe_pyascii(args...; kwargs...))
export pyascii


function unsafe_pyixor(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceXor, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyixor(args...; kwargs...) = safe(unsafe_pyixor(args...; kwargs...))
export pyixor


unsafe_pytype(args...; kwargs...) = unsafe_pycall_args(unsafe_pytypetype(), args, kwargs)
pytype(args...; kwargs...) = safe(unsafe_pytype(args...; kwargs...))
export pytype


const _pydatetype = pynull()
unsafe_pydatetype() = unsafe_cacheget!(_pydatetype) do; unsafe_pygetattr(pydatetimemodule(), "date"); end
pydatetype(args...; kwargs...) = safe(unsafe_pydatetype(args...; kwargs...))
export pydatetype


unsafe_pybytearray(args...; kwargs...) = unsafe_pycall_args(unsafe_pybytearray(), args, kwargs)
pybytearray(args...; kwargs...) = safe(unsafe_pybytearray(args...; kwargs...))
export pybytearray


function unsafe_pyiter(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_GetIter, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyiter(args...; kwargs...) = safe(unsafe_pyiter(args...; kwargs...))
export pyiter


function unsafe_pycomplex(x1::Real, x2::Real)
    r = ccall((:PyComplex_FromDoubles, PYLIB), Ptr{Cvoid}, (Cdouble, Cdouble), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
unsafe_pycomplex(args...; kwargs...) = unsafe_pycall_args(unsafe_pycomplextype(), args, kwargs)
pycomplex(args...; kwargs...) = safe(unsafe_pycomplex(args...; kwargs...))
export pycomplex


const _pyfractiontype = pynull()
unsafe_pyfractiontype() = unsafe_cacheget!(_pyfractiontype) do; unsafe_pygetattr(pyfractionsmodule(), "Fraction"); end
pyfractiontype(args...; kwargs...) = safe(unsafe_pyfractiontype(args...; kwargs...))
export pyfractiontype


function unsafe_pyrshift(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Rshift, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyrshift(args...; kwargs...) = safe(unsafe_pyrshift(args...; kwargs...))
export pyrshift


function unsafe_pyimod(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceRemainder, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyimod(args...; kwargs...) = safe(unsafe_pyimod(args...; kwargs...))
export pyimod


function unsafe_pyipow(x1::Any, x2::Any, x3::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    if !(x3 isa PyObject)
        x3 = unsafe_pyobj(x3)
        isnull(x3) && return PYNULL
    end

    r = ccall((:PyNumber_InplacePower, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), x1, x2, x3)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyipow(args...; kwargs...) = safe(unsafe_pyipow(args...; kwargs...))
export pyipow


function unsafe_pylen(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{CPy_ssize_t}()
    end

    r = ccall((:PyObject_Length, PYLIB), CPy_ssize_t, (Ptr{Cvoid},), x1)
    if iszero(r + one(r))
        return ValueOrError{CPy_ssize_t}()
    else
        return ValueOrError{CPy_ssize_t}(r)
    end
end
pylen(args...; kwargs...) = safe(unsafe_pylen(args...; kwargs...))
export pylen


function unsafe_pyset_new(x1::Ptr)
    r = ccall((:PySet_New, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end


const _pydatetimetype = pynull()
unsafe_pydatetimetype() = unsafe_cacheget!(_pydatetimetype) do; unsafe_pygetattr(pydatetimemodule(), "datetime"); end
pydatetimetype(args...; kwargs...) = safe(unsafe_pydatetimetype(args...; kwargs...))
export pydatetimetype


unsafe_pyfraction(args...; kwargs...) = unsafe_pycall_args(unsafe_pyfractiontype(), args, kwargs)
pyfraction(args...; kwargs...) = safe(unsafe_pyfraction(args...; kwargs...))
export pyfraction


function unsafe_pyimul(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceMultiply, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyimul(args...; kwargs...) = safe(unsafe_pyimul(args...; kwargs...))
export pyimul


function unsafe_pyineg(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceNegative, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyineg(args...; kwargs...) = safe(unsafe_pyineg(args...; kwargs...))
export pyineg


function unsafe_pyimatmul(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceMatrixMultiply, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyimatmul(args...; kwargs...) = safe(unsafe_pyimatmul(args...; kwargs...))
export pyimatmul


unsafe_pylist(args...; kwargs...) = unsafe_pycall_args(unsafe_pylisttype(), args, kwargs)
pylist(args...; kwargs...) = safe(unsafe_pylist(args...; kwargs...))
export pylist


unsafe_pytime(args...; kwargs...) = unsafe_pycall_args(unsafe_pytimetype(), args, kwargs)
pytime(args...; kwargs...) = safe(unsafe_pytime(args...; kwargs...))
export pytime


unsafe_pydatetime(args...; kwargs...) = unsafe_pycall_args(unsafe_pydatetimetype(), args, kwargs)
pydatetime(args...; kwargs...) = safe(unsafe_pydatetime(args...; kwargs...))
export pydatetime


function unsafe_pyiadd(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceAdd, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyiadd(args...; kwargs...) = safe(unsafe_pyiadd(args...; kwargs...))
export pyiadd


unsafe_pybool(args...; kwargs...) = unsafe_pycall_args(unsafe_pybooltype(), args, kwargs)
pybool(args...; kwargs...) = safe(unsafe_pybool(args...; kwargs...))
export pybool


function unsafe_pylshift(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_Lshift, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pylshift(args...; kwargs...) = safe(unsafe_pylshift(args...; kwargs...))
export pylshift


function unsafe_pystr(x1::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_Str, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid},), x1)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
unsafe_pystr(args...; kwargs...) = unsafe_pycall_args(unsafe_pystrtype(), args, kwargs)
pystr(args...; kwargs...) = safe(unsafe_pystr(args...; kwargs...))
export pystr


function unsafe_pyiand(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyNumber_InplaceAnd, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pyiand(args...; kwargs...) = safe(unsafe_pyiand(args...; kwargs...))
export pyiand


function unsafe_pyset_add(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return ValueOrError{Nothing}()
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return ValueOrError{Nothing}()
    end

    r = ccall((:PySet_Add, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == -1
        return ValueOrError{Nothing}()
    else
        return ValueOrError{Nothing}(nothing)
    end
end


unsafe_pysuper(args...; kwargs...) = unsafe_pycall_args(unsafe_pysupertype(), args, kwargs)
pysuper(args...; kwargs...) = safe(unsafe_pysuper(args...; kwargs...))
export pysuper


const _pyellipsistype = pynulltype()
unsafe_pyellipsistype() = unsafe_cacheget!(_pyellipsistype) do; unsafe_pytype(unsafe_pyellipsis()); end
pyellipsistype(args...; kwargs...) = safe(unsafe_pyellipsistype(args...; kwargs...))
export pyellipsistype


function unsafe_pygetattr(x1::Any, x2::Any)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    if !(x2 isa PyObject)
        x2 = unsafe_pyobj(x2)
        isnull(x2) && return PYNULL
    end

    r = ccall((:PyObject_GetAttr, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
function unsafe_pygetattr(x1::Any, x2::AbstractString)
    if !(x1 isa PyObject)
        x1 = unsafe_pyobj(x1)
        isnull(x1) && return PYNULL
    end

    r = ccall((:PyObject_GetAttrString, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), x1, x2)
    if r == C_NULL
        return PYNULL
    else
        return unsafe_pyobj(PyObjRef(r, false))
    end
end
pygetattr(args...; kwargs...) = safe(unsafe_pygetattr(args...; kwargs...))
export pygetattr


const _pydicttype = pynulltype()
unsafe_pydicttype() = unsafe_cacheget!(_pydicttype) do; cglobal((:PyDict_Type, PYLIB), CPyObject); end
pydicttype(args...; kwargs...) = safe(unsafe_pydicttype(args...; kwargs...))
export pydicttype


unsafe_pyslice(args...; kwargs...) = unsafe_pycall_args(unsafe_pyslicetype(), args, kwargs)
pyslice(args...; kwargs...) = safe(unsafe_pyslice(args...; kwargs...))
export pyslice


const _pyexc_BaseException_type = pynull()
unsafe_pyexc_BaseException_type() = unsafe_cacheget!(_pyexc_BaseException_type) do; unsafe_load(cglobal((:PyExc_BaseException, PYLIB), Ptr{CPyObject})); end
pyexc_BaseException_type(args...; kwargs...) = safe(unsafe_pyexc_BaseException_type(args...; kwargs...))
export pyexc_BaseException_type

pyerror_set_BaseException(args...; kwargs...) = pyerror_set(unsafe_pyexc_BaseException_type(), args...; kwargs...)
export pyerror_set_BaseException

pyerror_occurred_BaseException() = pyerror_occurred(unsafe_pyexc_BaseException_type())
export pyerror_occurred_BaseException

const _pyexc_Exception_type = pynull()
unsafe_pyexc_Exception_type() = unsafe_cacheget!(_pyexc_Exception_type) do; unsafe_load(cglobal((:PyExc_Exception, PYLIB), Ptr{CPyObject})); end
pyexc_Exception_type(args...; kwargs...) = safe(unsafe_pyexc_Exception_type(args...; kwargs...))
export pyexc_Exception_type

pyerror_set_Exception(args...; kwargs...) = pyerror_set(unsafe_pyexc_Exception_type(), args...; kwargs...)
export pyerror_set_Exception

pyerror_occurred_Exception() = pyerror_occurred(unsafe_pyexc_Exception_type())
export pyerror_occurred_Exception

const _pyexc_StopIteration_type = pynull()
unsafe_pyexc_StopIteration_type() = unsafe_cacheget!(_pyexc_StopIteration_type) do; unsafe_load(cglobal((:PyExc_StopIteration, PYLIB), Ptr{CPyObject})); end
pyexc_StopIteration_type(args...; kwargs...) = safe(unsafe_pyexc_StopIteration_type(args...; kwargs...))
export pyexc_StopIteration_type

pyerror_set_StopIteration(args...; kwargs...) = pyerror_set(unsafe_pyexc_StopIteration_type(), args...; kwargs...)
export pyerror_set_StopIteration

pyerror_occurred_StopIteration() = pyerror_occurred(unsafe_pyexc_StopIteration_type())
export pyerror_occurred_StopIteration

const _pyexc_GeneratorExit_type = pynull()
unsafe_pyexc_GeneratorExit_type() = unsafe_cacheget!(_pyexc_GeneratorExit_type) do; unsafe_load(cglobal((:PyExc_GeneratorExit, PYLIB), Ptr{CPyObject})); end
pyexc_GeneratorExit_type(args...; kwargs...) = safe(unsafe_pyexc_GeneratorExit_type(args...; kwargs...))
export pyexc_GeneratorExit_type

pyerror_set_GeneratorExit(args...; kwargs...) = pyerror_set(unsafe_pyexc_GeneratorExit_type(), args...; kwargs...)
export pyerror_set_GeneratorExit

pyerror_occurred_GeneratorExit() = pyerror_occurred(unsafe_pyexc_GeneratorExit_type())
export pyerror_occurred_GeneratorExit

const _pyexc_ArithmeticError_type = pynull()
unsafe_pyexc_ArithmeticError_type() = unsafe_cacheget!(_pyexc_ArithmeticError_type) do; unsafe_load(cglobal((:PyExc_ArithmeticError, PYLIB), Ptr{CPyObject})); end
pyexc_ArithmeticError_type(args...; kwargs...) = safe(unsafe_pyexc_ArithmeticError_type(args...; kwargs...))
export pyexc_ArithmeticError_type

pyerror_set_ArithmeticError(args...; kwargs...) = pyerror_set(unsafe_pyexc_ArithmeticError_type(), args...; kwargs...)
export pyerror_set_ArithmeticError

pyerror_occurred_ArithmeticError() = pyerror_occurred(unsafe_pyexc_ArithmeticError_type())
export pyerror_occurred_ArithmeticError

const _pyexc_LookupError_type = pynull()
unsafe_pyexc_LookupError_type() = unsafe_cacheget!(_pyexc_LookupError_type) do; unsafe_load(cglobal((:PyExc_LookupError, PYLIB), Ptr{CPyObject})); end
pyexc_LookupError_type(args...; kwargs...) = safe(unsafe_pyexc_LookupError_type(args...; kwargs...))
export pyexc_LookupError_type

pyerror_set_LookupError(args...; kwargs...) = pyerror_set(unsafe_pyexc_LookupError_type(), args...; kwargs...)
export pyerror_set_LookupError

pyerror_occurred_LookupError() = pyerror_occurred(unsafe_pyexc_LookupError_type())
export pyerror_occurred_LookupError

const _pyexc_AssertionError_type = pynull()
unsafe_pyexc_AssertionError_type() = unsafe_cacheget!(_pyexc_AssertionError_type) do; unsafe_load(cglobal((:PyExc_AssertionError, PYLIB), Ptr{CPyObject})); end
pyexc_AssertionError_type(args...; kwargs...) = safe(unsafe_pyexc_AssertionError_type(args...; kwargs...))
export pyexc_AssertionError_type

pyerror_set_AssertionError(args...; kwargs...) = pyerror_set(unsafe_pyexc_AssertionError_type(), args...; kwargs...)
export pyerror_set_AssertionError

pyerror_occurred_AssertionError() = pyerror_occurred(unsafe_pyexc_AssertionError_type())
export pyerror_occurred_AssertionError

const _pyexc_AttributeError_type = pynull()
unsafe_pyexc_AttributeError_type() = unsafe_cacheget!(_pyexc_AttributeError_type) do; unsafe_load(cglobal((:PyExc_AttributeError, PYLIB), Ptr{CPyObject})); end
pyexc_AttributeError_type(args...; kwargs...) = safe(unsafe_pyexc_AttributeError_type(args...; kwargs...))
export pyexc_AttributeError_type

pyerror_set_AttributeError(args...; kwargs...) = pyerror_set(unsafe_pyexc_AttributeError_type(), args...; kwargs...)
export pyerror_set_AttributeError

pyerror_occurred_AttributeError() = pyerror_occurred(unsafe_pyexc_AttributeError_type())
export pyerror_occurred_AttributeError

const _pyexc_BufferError_type = pynull()
unsafe_pyexc_BufferError_type() = unsafe_cacheget!(_pyexc_BufferError_type) do; unsafe_load(cglobal((:PyExc_BufferError, PYLIB), Ptr{CPyObject})); end
pyexc_BufferError_type(args...; kwargs...) = safe(unsafe_pyexc_BufferError_type(args...; kwargs...))
export pyexc_BufferError_type

pyerror_set_BufferError(args...; kwargs...) = pyerror_set(unsafe_pyexc_BufferError_type(), args...; kwargs...)
export pyerror_set_BufferError

pyerror_occurred_BufferError() = pyerror_occurred(unsafe_pyexc_BufferError_type())
export pyerror_occurred_BufferError

const _pyexc_EOFError_type = pynull()
unsafe_pyexc_EOFError_type() = unsafe_cacheget!(_pyexc_EOFError_type) do; unsafe_load(cglobal((:PyExc_EOFError, PYLIB), Ptr{CPyObject})); end
pyexc_EOFError_type(args...; kwargs...) = safe(unsafe_pyexc_EOFError_type(args...; kwargs...))
export pyexc_EOFError_type

pyerror_set_EOFError(args...; kwargs...) = pyerror_set(unsafe_pyexc_EOFError_type(), args...; kwargs...)
export pyerror_set_EOFError

pyerror_occurred_EOFError() = pyerror_occurred(unsafe_pyexc_EOFError_type())
export pyerror_occurred_EOFError

const _pyexc_FloatingPointError_type = pynull()
unsafe_pyexc_FloatingPointError_type() = unsafe_cacheget!(_pyexc_FloatingPointError_type) do; unsafe_load(cglobal((:PyExc_FloatingPointError, PYLIB), Ptr{CPyObject})); end
pyexc_FloatingPointError_type(args...; kwargs...) = safe(unsafe_pyexc_FloatingPointError_type(args...; kwargs...))
export pyexc_FloatingPointError_type

pyerror_set_FloatingPointError(args...; kwargs...) = pyerror_set(unsafe_pyexc_FloatingPointError_type(), args...; kwargs...)
export pyerror_set_FloatingPointError

pyerror_occurred_FloatingPointError() = pyerror_occurred(unsafe_pyexc_FloatingPointError_type())
export pyerror_occurred_FloatingPointError

const _pyexc_OSError_type = pynull()
unsafe_pyexc_OSError_type() = unsafe_cacheget!(_pyexc_OSError_type) do; unsafe_load(cglobal((:PyExc_OSError, PYLIB), Ptr{CPyObject})); end
pyexc_OSError_type(args...; kwargs...) = safe(unsafe_pyexc_OSError_type(args...; kwargs...))
export pyexc_OSError_type

pyerror_set_OSError(args...; kwargs...) = pyerror_set(unsafe_pyexc_OSError_type(), args...; kwargs...)
export pyerror_set_OSError

pyerror_occurred_OSError() = pyerror_occurred(unsafe_pyexc_OSError_type())
export pyerror_occurred_OSError

const _pyexc_ImportError_type = pynull()
unsafe_pyexc_ImportError_type() = unsafe_cacheget!(_pyexc_ImportError_type) do; unsafe_load(cglobal((:PyExc_ImportError, PYLIB), Ptr{CPyObject})); end
pyexc_ImportError_type(args...; kwargs...) = safe(unsafe_pyexc_ImportError_type(args...; kwargs...))
export pyexc_ImportError_type

pyerror_set_ImportError(args...; kwargs...) = pyerror_set(unsafe_pyexc_ImportError_type(), args...; kwargs...)
export pyerror_set_ImportError

pyerror_occurred_ImportError() = pyerror_occurred(unsafe_pyexc_ImportError_type())
export pyerror_occurred_ImportError

const _pyexc_IndexError_type = pynull()
unsafe_pyexc_IndexError_type() = unsafe_cacheget!(_pyexc_IndexError_type) do; unsafe_load(cglobal((:PyExc_IndexError, PYLIB), Ptr{CPyObject})); end
pyexc_IndexError_type(args...; kwargs...) = safe(unsafe_pyexc_IndexError_type(args...; kwargs...))
export pyexc_IndexError_type

pyerror_set_IndexError(args...; kwargs...) = pyerror_set(unsafe_pyexc_IndexError_type(), args...; kwargs...)
export pyerror_set_IndexError

pyerror_occurred_IndexError() = pyerror_occurred(unsafe_pyexc_IndexError_type())
export pyerror_occurred_IndexError

const _pyexc_KeyError_type = pynull()
unsafe_pyexc_KeyError_type() = unsafe_cacheget!(_pyexc_KeyError_type) do; unsafe_load(cglobal((:PyExc_KeyError, PYLIB), Ptr{CPyObject})); end
pyexc_KeyError_type(args...; kwargs...) = safe(unsafe_pyexc_KeyError_type(args...; kwargs...))
export pyexc_KeyError_type

pyerror_set_KeyError(args...; kwargs...) = pyerror_set(unsafe_pyexc_KeyError_type(), args...; kwargs...)
export pyerror_set_KeyError

pyerror_occurred_KeyError() = pyerror_occurred(unsafe_pyexc_KeyError_type())
export pyerror_occurred_KeyError

const _pyexc_KeyboardInterrupt_type = pynull()
unsafe_pyexc_KeyboardInterrupt_type() = unsafe_cacheget!(_pyexc_KeyboardInterrupt_type) do; unsafe_load(cglobal((:PyExc_KeyboardInterrupt, PYLIB), Ptr{CPyObject})); end
pyexc_KeyboardInterrupt_type(args...; kwargs...) = safe(unsafe_pyexc_KeyboardInterrupt_type(args...; kwargs...))
export pyexc_KeyboardInterrupt_type

pyerror_set_KeyboardInterrupt(args...; kwargs...) = pyerror_set(unsafe_pyexc_KeyboardInterrupt_type(), args...; kwargs...)
export pyerror_set_KeyboardInterrupt

pyerror_occurred_KeyboardInterrupt() = pyerror_occurred(unsafe_pyexc_KeyboardInterrupt_type())
export pyerror_occurred_KeyboardInterrupt

const _pyexc_MemoryError_type = pynull()
unsafe_pyexc_MemoryError_type() = unsafe_cacheget!(_pyexc_MemoryError_type) do; unsafe_load(cglobal((:PyExc_MemoryError, PYLIB), Ptr{CPyObject})); end
pyexc_MemoryError_type(args...; kwargs...) = safe(unsafe_pyexc_MemoryError_type(args...; kwargs...))
export pyexc_MemoryError_type

pyerror_set_MemoryError(args...; kwargs...) = pyerror_set(unsafe_pyexc_MemoryError_type(), args...; kwargs...)
export pyerror_set_MemoryError

pyerror_occurred_MemoryError() = pyerror_occurred(unsafe_pyexc_MemoryError_type())
export pyerror_occurred_MemoryError

const _pyexc_NameError_type = pynull()
unsafe_pyexc_NameError_type() = unsafe_cacheget!(_pyexc_NameError_type) do; unsafe_load(cglobal((:PyExc_NameError, PYLIB), Ptr{CPyObject})); end
pyexc_NameError_type(args...; kwargs...) = safe(unsafe_pyexc_NameError_type(args...; kwargs...))
export pyexc_NameError_type

pyerror_set_NameError(args...; kwargs...) = pyerror_set(unsafe_pyexc_NameError_type(), args...; kwargs...)
export pyerror_set_NameError

pyerror_occurred_NameError() = pyerror_occurred(unsafe_pyexc_NameError_type())
export pyerror_occurred_NameError

const _pyexc_OverflowError_type = pynull()
unsafe_pyexc_OverflowError_type() = unsafe_cacheget!(_pyexc_OverflowError_type) do; unsafe_load(cglobal((:PyExc_OverflowError, PYLIB), Ptr{CPyObject})); end
pyexc_OverflowError_type(args...; kwargs...) = safe(unsafe_pyexc_OverflowError_type(args...; kwargs...))
export pyexc_OverflowError_type

pyerror_set_OverflowError(args...; kwargs...) = pyerror_set(unsafe_pyexc_OverflowError_type(), args...; kwargs...)
export pyerror_set_OverflowError

pyerror_occurred_OverflowError() = pyerror_occurred(unsafe_pyexc_OverflowError_type())
export pyerror_occurred_OverflowError

const _pyexc_RuntimeError_type = pynull()
unsafe_pyexc_RuntimeError_type() = unsafe_cacheget!(_pyexc_RuntimeError_type) do; unsafe_load(cglobal((:PyExc_RuntimeError, PYLIB), Ptr{CPyObject})); end
pyexc_RuntimeError_type(args...; kwargs...) = safe(unsafe_pyexc_RuntimeError_type(args...; kwargs...))
export pyexc_RuntimeError_type

pyerror_set_RuntimeError(args...; kwargs...) = pyerror_set(unsafe_pyexc_RuntimeError_type(), args...; kwargs...)
export pyerror_set_RuntimeError

pyerror_occurred_RuntimeError() = pyerror_occurred(unsafe_pyexc_RuntimeError_type())
export pyerror_occurred_RuntimeError

const _pyexc_NotImplementedError_type = pynull()
unsafe_pyexc_NotImplementedError_type() = unsafe_cacheget!(_pyexc_NotImplementedError_type) do; unsafe_load(cglobal((:PyExc_NotImplementedError, PYLIB), Ptr{CPyObject})); end
pyexc_NotImplementedError_type(args...; kwargs...) = safe(unsafe_pyexc_NotImplementedError_type(args...; kwargs...))
export pyexc_NotImplementedError_type

pyerror_set_NotImplementedError(args...; kwargs...) = pyerror_set(unsafe_pyexc_NotImplementedError_type(), args...; kwargs...)
export pyerror_set_NotImplementedError

pyerror_occurred_NotImplementedError() = pyerror_occurred(unsafe_pyexc_NotImplementedError_type())
export pyerror_occurred_NotImplementedError

const _pyexc_SyntaxError_type = pynull()
unsafe_pyexc_SyntaxError_type() = unsafe_cacheget!(_pyexc_SyntaxError_type) do; unsafe_load(cglobal((:PyExc_SyntaxError, PYLIB), Ptr{CPyObject})); end
pyexc_SyntaxError_type(args...; kwargs...) = safe(unsafe_pyexc_SyntaxError_type(args...; kwargs...))
export pyexc_SyntaxError_type

pyerror_set_SyntaxError(args...; kwargs...) = pyerror_set(unsafe_pyexc_SyntaxError_type(), args...; kwargs...)
export pyerror_set_SyntaxError

pyerror_occurred_SyntaxError() = pyerror_occurred(unsafe_pyexc_SyntaxError_type())
export pyerror_occurred_SyntaxError

const _pyexc_IndentationError_type = pynull()
unsafe_pyexc_IndentationError_type() = unsafe_cacheget!(_pyexc_IndentationError_type) do; unsafe_load(cglobal((:PyExc_IndentationError, PYLIB), Ptr{CPyObject})); end
pyexc_IndentationError_type(args...; kwargs...) = safe(unsafe_pyexc_IndentationError_type(args...; kwargs...))
export pyexc_IndentationError_type

pyerror_set_IndentationError(args...; kwargs...) = pyerror_set(unsafe_pyexc_IndentationError_type(), args...; kwargs...)
export pyerror_set_IndentationError

pyerror_occurred_IndentationError() = pyerror_occurred(unsafe_pyexc_IndentationError_type())
export pyerror_occurred_IndentationError

const _pyexc_TabError_type = pynull()
unsafe_pyexc_TabError_type() = unsafe_cacheget!(_pyexc_TabError_type) do; unsafe_load(cglobal((:PyExc_TabError, PYLIB), Ptr{CPyObject})); end
pyexc_TabError_type(args...; kwargs...) = safe(unsafe_pyexc_TabError_type(args...; kwargs...))
export pyexc_TabError_type

pyerror_set_TabError(args...; kwargs...) = pyerror_set(unsafe_pyexc_TabError_type(), args...; kwargs...)
export pyerror_set_TabError

pyerror_occurred_TabError() = pyerror_occurred(unsafe_pyexc_TabError_type())
export pyerror_occurred_TabError

const _pyexc_ReferenceError_type = pynull()
unsafe_pyexc_ReferenceError_type() = unsafe_cacheget!(_pyexc_ReferenceError_type) do; unsafe_load(cglobal((:PyExc_ReferenceError, PYLIB), Ptr{CPyObject})); end
pyexc_ReferenceError_type(args...; kwargs...) = safe(unsafe_pyexc_ReferenceError_type(args...; kwargs...))
export pyexc_ReferenceError_type

pyerror_set_ReferenceError(args...; kwargs...) = pyerror_set(unsafe_pyexc_ReferenceError_type(), args...; kwargs...)
export pyerror_set_ReferenceError

pyerror_occurred_ReferenceError() = pyerror_occurred(unsafe_pyexc_ReferenceError_type())
export pyerror_occurred_ReferenceError

const _pyexc_SystemError_type = pynull()
unsafe_pyexc_SystemError_type() = unsafe_cacheget!(_pyexc_SystemError_type) do; unsafe_load(cglobal((:PyExc_SystemError, PYLIB), Ptr{CPyObject})); end
pyexc_SystemError_type(args...; kwargs...) = safe(unsafe_pyexc_SystemError_type(args...; kwargs...))
export pyexc_SystemError_type

pyerror_set_SystemError(args...; kwargs...) = pyerror_set(unsafe_pyexc_SystemError_type(), args...; kwargs...)
export pyerror_set_SystemError

pyerror_occurred_SystemError() = pyerror_occurred(unsafe_pyexc_SystemError_type())
export pyerror_occurred_SystemError

const _pyexc_SystemExit_type = pynull()
unsafe_pyexc_SystemExit_type() = unsafe_cacheget!(_pyexc_SystemExit_type) do; unsafe_load(cglobal((:PyExc_SystemExit, PYLIB), Ptr{CPyObject})); end
pyexc_SystemExit_type(args...; kwargs...) = safe(unsafe_pyexc_SystemExit_type(args...; kwargs...))
export pyexc_SystemExit_type

pyerror_set_SystemExit(args...; kwargs...) = pyerror_set(unsafe_pyexc_SystemExit_type(), args...; kwargs...)
export pyerror_set_SystemExit

pyerror_occurred_SystemExit() = pyerror_occurred(unsafe_pyexc_SystemExit_type())
export pyerror_occurred_SystemExit

const _pyexc_TypeError_type = pynull()
unsafe_pyexc_TypeError_type() = unsafe_cacheget!(_pyexc_TypeError_type) do; unsafe_load(cglobal((:PyExc_TypeError, PYLIB), Ptr{CPyObject})); end
pyexc_TypeError_type(args...; kwargs...) = safe(unsafe_pyexc_TypeError_type(args...; kwargs...))
export pyexc_TypeError_type

pyerror_set_TypeError(args...; kwargs...) = pyerror_set(unsafe_pyexc_TypeError_type(), args...; kwargs...)
export pyerror_set_TypeError

pyerror_occurred_TypeError() = pyerror_occurred(unsafe_pyexc_TypeError_type())
export pyerror_occurred_TypeError

const _pyexc_UnboundLocalError_type = pynull()
unsafe_pyexc_UnboundLocalError_type() = unsafe_cacheget!(_pyexc_UnboundLocalError_type) do; unsafe_load(cglobal((:PyExc_UnboundLocalError, PYLIB), Ptr{CPyObject})); end
pyexc_UnboundLocalError_type(args...; kwargs...) = safe(unsafe_pyexc_UnboundLocalError_type(args...; kwargs...))
export pyexc_UnboundLocalError_type

pyerror_set_UnboundLocalError(args...; kwargs...) = pyerror_set(unsafe_pyexc_UnboundLocalError_type(), args...; kwargs...)
export pyerror_set_UnboundLocalError

pyerror_occurred_UnboundLocalError() = pyerror_occurred(unsafe_pyexc_UnboundLocalError_type())
export pyerror_occurred_UnboundLocalError

const _pyexc_UnicodeError_type = pynull()
unsafe_pyexc_UnicodeError_type() = unsafe_cacheget!(_pyexc_UnicodeError_type) do; unsafe_load(cglobal((:PyExc_UnicodeError, PYLIB), Ptr{CPyObject})); end
pyexc_UnicodeError_type(args...; kwargs...) = safe(unsafe_pyexc_UnicodeError_type(args...; kwargs...))
export pyexc_UnicodeError_type

pyerror_set_UnicodeError(args...; kwargs...) = pyerror_set(unsafe_pyexc_UnicodeError_type(), args...; kwargs...)
export pyerror_set_UnicodeError

pyerror_occurred_UnicodeError() = pyerror_occurred(unsafe_pyexc_UnicodeError_type())
export pyerror_occurred_UnicodeError

const _pyexc_UnicodeEncodeError_type = pynull()
unsafe_pyexc_UnicodeEncodeError_type() = unsafe_cacheget!(_pyexc_UnicodeEncodeError_type) do; unsafe_load(cglobal((:PyExc_UnicodeEncodeError, PYLIB), Ptr{CPyObject})); end
pyexc_UnicodeEncodeError_type(args...; kwargs...) = safe(unsafe_pyexc_UnicodeEncodeError_type(args...; kwargs...))
export pyexc_UnicodeEncodeError_type

pyerror_set_UnicodeEncodeError(args...; kwargs...) = pyerror_set(unsafe_pyexc_UnicodeEncodeError_type(), args...; kwargs...)
export pyerror_set_UnicodeEncodeError

pyerror_occurred_UnicodeEncodeError() = pyerror_occurred(unsafe_pyexc_UnicodeEncodeError_type())
export pyerror_occurred_UnicodeEncodeError

const _pyexc_UnicodeDecodeError_type = pynull()
unsafe_pyexc_UnicodeDecodeError_type() = unsafe_cacheget!(_pyexc_UnicodeDecodeError_type) do; unsafe_load(cglobal((:PyExc_UnicodeDecodeError, PYLIB), Ptr{CPyObject})); end
pyexc_UnicodeDecodeError_type(args...; kwargs...) = safe(unsafe_pyexc_UnicodeDecodeError_type(args...; kwargs...))
export pyexc_UnicodeDecodeError_type

pyerror_set_UnicodeDecodeError(args...; kwargs...) = pyerror_set(unsafe_pyexc_UnicodeDecodeError_type(), args...; kwargs...)
export pyerror_set_UnicodeDecodeError

pyerror_occurred_UnicodeDecodeError() = pyerror_occurred(unsafe_pyexc_UnicodeDecodeError_type())
export pyerror_occurred_UnicodeDecodeError

const _pyexc_UnicodeTranslateError_type = pynull()
unsafe_pyexc_UnicodeTranslateError_type() = unsafe_cacheget!(_pyexc_UnicodeTranslateError_type) do; unsafe_load(cglobal((:PyExc_UnicodeTranslateError, PYLIB), Ptr{CPyObject})); end
pyexc_UnicodeTranslateError_type(args...; kwargs...) = safe(unsafe_pyexc_UnicodeTranslateError_type(args...; kwargs...))
export pyexc_UnicodeTranslateError_type

pyerror_set_UnicodeTranslateError(args...; kwargs...) = pyerror_set(unsafe_pyexc_UnicodeTranslateError_type(), args...; kwargs...)
export pyerror_set_UnicodeTranslateError

pyerror_occurred_UnicodeTranslateError() = pyerror_occurred(unsafe_pyexc_UnicodeTranslateError_type())
export pyerror_occurred_UnicodeTranslateError

const _pyexc_ValueError_type = pynull()
unsafe_pyexc_ValueError_type() = unsafe_cacheget!(_pyexc_ValueError_type) do; unsafe_load(cglobal((:PyExc_ValueError, PYLIB), Ptr{CPyObject})); end
pyexc_ValueError_type(args...; kwargs...) = safe(unsafe_pyexc_ValueError_type(args...; kwargs...))
export pyexc_ValueError_type

pyerror_set_ValueError(args...; kwargs...) = pyerror_set(unsafe_pyexc_ValueError_type(), args...; kwargs...)
export pyerror_set_ValueError

pyerror_occurred_ValueError() = pyerror_occurred(unsafe_pyexc_ValueError_type())
export pyerror_occurred_ValueError

const _pyexc_ZeroDivisionError_type = pynull()
unsafe_pyexc_ZeroDivisionError_type() = unsafe_cacheget!(_pyexc_ZeroDivisionError_type) do; unsafe_load(cglobal((:PyExc_ZeroDivisionError, PYLIB), Ptr{CPyObject})); end
pyexc_ZeroDivisionError_type(args...; kwargs...) = safe(unsafe_pyexc_ZeroDivisionError_type(args...; kwargs...))
export pyexc_ZeroDivisionError_type

pyerror_set_ZeroDivisionError(args...; kwargs...) = pyerror_set(unsafe_pyexc_ZeroDivisionError_type(), args...; kwargs...)
export pyerror_set_ZeroDivisionError

pyerror_occurred_ZeroDivisionError() = pyerror_occurred(unsafe_pyexc_ZeroDivisionError_type())
export pyerror_occurred_ZeroDivisionError

