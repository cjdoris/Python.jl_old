function _unsafe_pyisbuffer(o)
    b = uptr(_unsafe_pytype(o)).as_buffer[]
    !isnull(b) && !isnull(b.getbuffer[])
end

function _unsafe_pygetbuffer(o, view, flags)
    R = ValueOrError{Nothing}
    b = uptr(_unsafe_pytype(o)).as_buffer[]
    if isnull(b) || isnull(b.getbuffer[])
        pyerror_set_TypeError("a bytes-like object is required")
        return R()
    end
    e = ccall(b.getbuffer[Ptr], Cint, (PyPtr, Ptr{CPy_buffer}, Cint), o, view, flags)
    e == -1 ? R() : R(nothing)
end

function _unsafe_pyreleasebuffer(o, view)
    v = UnsafePtr{CPy_buffer}(view)
    obj = v.obj[]
    isnull(obj) && return
    b = uptr(_unsafe_pytype(o)).as_buffer[]
    if !isnull(b) && !isnull(b.releasebuffer[])
        ccall(b.releasebuffer[Ptr], Cvoid, (PyPtr, Ptr{CPy_buffer}), o, view)
    end
    v.obj[] = C_NULL
    decref!(PyBorrowedRef(ptr(obj)))
    nothing
end

mutable struct PyBuffer
    o :: PyObject
    view :: Array{CPy_buffer, 0}
    flags :: UInt
    function PyBuffer(::Val{:unsafe}, _o, flags=CPyBUF_FULL)
        R = ValueOrError{PyBuffer}
        if !isa(_o, AbstractPyRef)
            _o = unsafe_pyref(_o)
            isnull(_o) && return R()
        end
        o = unsafe_pyobj(_o)
        view = fill(CPy_buffer())
        iserr(_unsafe_pygetbuffer(o, view, flags)) && return R()
        r = new(o, view, flags)
        finalizer(r) do r
            _unsafe_pyreleasebuffer(r.o, r.view)
        end
        R(r)
    end
end
PyBuffer(::Val{:unsafe}, args...; kwargs...) = throw(MethodError(PyBuffer, (Val(:unsafe), args...)))
unsafe_PyBuffer(args...; kwargs...) = PyBuffer(Val(:unsafe), args...; kwargs...)
PyBuffer(args...; kwargs...) = safe(unsafe_PyBuffer(args...; kwargs...))
export PyBuffer

function Base.getproperty(b::PyBuffer, k::Symbol)
    if k == :buf
        b.view[].buf
    elseif k == :len
        b.view[].len
    elseif k == :readonly
        !iszero(b.view[].readonly)
    elseif k == :itemsize
        b.view[].shape == C_NULL ? 1 : convert(Int, b.view[].itemsize)
    elseif k == :format
        b.view[].format == C_NULL ? "B" : unsafe_string(b.view[].format)
    elseif k == :ndim
        b.view[].ndim
    elseif k == :shape
        b.view[].shape == C_NULL ? Int[b.len] : Int[unsafe_load(b.view[].shape, i) for i in 1:b.ndim]
    elseif k == :strides
        b.view[].strides == C_NULL ? error("not implemented") : Int[unsafe_load(b.view[].strides, i) for i in 1:b.ndim]
    else
        getfield(b, k)
    end
end
