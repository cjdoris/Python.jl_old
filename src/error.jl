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
    if isnull(e.t)
        print(io, "mysterious error (no error was actually set)")
        return
    end

    # if this is a Julia exception then recursively print it and its stacktrace
    if pyerror_givenexceptionmatches(e.t, pyexc_JuliaException_type())
        # get the exception and backtrace
        jp = try
            pyjulia_getvalue(e.v.args[0])
        catch
            @goto jlerr
        end
        if jp isa Exception
            je = jp
            jb = nothing
        elseif jp isa Tuple{Exception, AbstractVector}
            je, jb = jp
        else
            @goto jlerr
        end

        showerror(io, je)
        if jb === nothing
            println(io)
            print(io, "<no stacktrace>")
        else
            io2 = IOBuffer()
            Base.show_backtrace(IOContext(io2, :color=>true, :displaysize=>displaysize(io)), jb)
            seekstart(io2)
            printstyled(io, read(io2, String))
        end

        if !isnull(e.b)
            @goto pystacktrace
        else
            println(io)
            printstyled(io, "(thrown from unknown Python code)")
            return
        end

        @label jlerr
        println(io, "<error while printing Julia exception inside Python exception>")
    end

    # otherwise, print the Python exception
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
        if !isnull(e.b)
            @label pystacktrace
            println(io)
            printstyled(io, "Python stacktrace:")
            try
                fs = pyimport("traceback").extract_tb(e.b)
                nfs = pylen(fs)
                for i in 1:nfs
                    println(io)
                    f = fs[nfs-i]
                    printstyled(io, " [", i, "] ", )
                    printstyled(io, pystr(String, f.name), bold=true)
                    printstyled(io, " at ")
                    printstyled(io, pystr(String, f.filename), ":", pystr(String, f.lineno), bold=true)
                end
            catch
                print(io, "<error while printing traceback>")
            end
        end
    end
end
