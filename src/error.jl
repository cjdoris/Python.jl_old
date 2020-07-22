pyerror_clear() = ccall((:PyErr_Clear, PYLIB), Cvoid, ())

pyerror_set(t::PyObject) =
    @cpycall :PyErr_SetNone(t::CPyPtr)::Cvoid
pyerror_set(t::PyObject, v::AbstractString) =
    @cpycall :PyErr_SetString(t::CPyPtr, v::Cstring)::Cvoid
pyerror_set(t::PyObject, v::PyObject) =
    @cpycall :PyErr_SetObject(t::CPyPtr, v::CPyPtr)::Cvoid
pyerror_set(t::PyObject, v) =
    pyerror_set(t, unsafe_pyobj(v))

unsafe_pyerror_ptr() = ccall((:PyErr_Occurred, PYLIB), Ptr{Cvoid}, ())

"""
    pyerror_occurred([t::PyObject])

True if a Python error is currently raised, and optionally its type matches `t`.
"""
pyerror_occurred() = unsafe_pyerror_ptr() != C_NULL
function pyerror_occurred(t::PyObject)
    p = unsafe_pyerror_ptr()
    p == C_NULL && return false
    value(@cpycall :PyErr_GivenExceptionMatches(p::Ptr{Cvoid}, t::CPyPtr)::CPyNoErr{CPyBool})
end

for name in [:BaseException, :Exception, :StopIteration, :GeneratorExit, :ArithmeticError, :LookupError, :AssertionError, :AttributeError, :BufferError, :EOFError, :FloatingPointError, :OSError, :ImportError, :IndexError, :KeyError, :KeyboardInterrupt, :MemoryError, :NameError, :OverflowError, :RuntimeError, :NotImplementedError, :SyntaxError, :IndentationError, :TabError, :ReferenceError, :SystemError, :SystemExit, :TypeError, :UnboundLocalError, :UnicodeError, :UnicodeEncodeError, :UnicodeDecodeError, :UnicodeTranslateError, :ValueError, :ZeroDivisionError]
    jname = Symbol(:pyerror_, name)
    _jname = Symbol(:_, jname)
    unsafe_jname = Symbol(:unsafe_, jname)
    pname = Symbol(:PyExc_, name)
    @eval begin
        const $_jname = pynulltype()
        $unsafe_jname() = @unsafe_cacheget_objectptr $_jname $(QuoteNode(pname))
        $jname() = safe($unsafe_jname())
        export $jname
    end
end


struct PythonException <: Exception
    t :: PyObject
    v :: PyObject
    b :: PyObject
end

function pythrow()
    t = Ref{Ptr{Cvoid}}()
    v = Ref{Ptr{Cvoid}}()
    b = Ref{Ptr{Cvoid}}()
    ccall((:PyErr_Fetch, PYLIB), Cvoid, (Ptr{Ptr{Cvoid}},Ptr{Ptr{Cvoid}},Ptr{Ptr{Cvoid}}), t, v, b)
    ccall((:PyErr_NormalizeException, PYLIB), Cvoid, (Ptr{Ptr{Cvoid}},Ptr{Ptr{Cvoid}},Ptr{Ptr{Cvoid}}), t, v, b)
    e = PythonException(unsafe_pyobj(PyBorrowedObjRef(t[])), unsafe_pyobj(PyBorrowedObjRef(v[])), unsafe_pyobj(PyBorrowedObjRef(b[])))
    throw(e)
end

function Base.showerror(io::IO, e::PythonException)
    print(io, "PythonException: ")
    if isnull(e.t)
        print(io, "mysterious error (no error was actually set)")
    else
        try
            print(io, pystr(String, pygetattr(e.t, "__name__")))
        catch
            print(io, "<error while printing type>")
        end
        if !isnull(e.v)
            print(io, ": ")
            try
                print(io, pystr(String, e.v))
            catch
                print(io, "<error while printing value>")
            end
        end
    end
end
