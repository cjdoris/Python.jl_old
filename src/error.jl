# pyerror_clear() = ccall((:PyErr_Clear, PYLIB), Cvoid, ())

# unsafe_pyerror_ptr() = ccall((:PyErr_Occurred, PYLIB), Ptr{Cvoid}, ())

"""
    pyerror_occurred([t::PyObject])

True if a Python error is currently raised, and optionally its type matches `t`.
"""
pyerror_occurred() = unsafe_pyerror_ptr() != C_NULL
function pyerror_occurred(t::PyObject)
    p = unsafe_pyerror_ptr()
    p != C_NULL && ccall((:PyErr_GivenExceptionMatches, PYLIB), Cint, (Ptr{C_NULL}, Ptr{C_NULL}), p, t) != 0
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
    to = unsafe_pyobj(PyRef(t[], false))
    vo = unsafe_pyobj(PyRef(v[], false))
    bo = unsafe_pyobj(PyRef(b[], false))
    e = PythonException(to, vo, bo)
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
