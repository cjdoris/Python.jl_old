function _unsafe_pyisbuffer(o)
    b = uptr(_unsafe_pytype(o)).as_buffer[]
    !isnull(b) && !isnull(b.get[])
end

function _unsafe_pygetbuffer(o, view, flags)
    R = ValueOrError{Nothing}
    b = uptr(_unsafe_pytype(o)).as_buffer[]
    if isnull(b) || isnull(b.get[])
        pyerror_set_TypeError("a bytes-like object is required")
        return R()
    end
    e = ccall(b.get[Ptr], Cint, (PyPtr, Ptr{CPy_buffer}, Cint), o, view, flags)
    e == -1 ? R() : R(nothing)
end

function _unsafe_pyreleasebuffer(o, view)
    v = UnsafePtr{CPy_buffer}(view)
    obj = v.obj[]
    isnull(obj) && return
    b = uptr(_unsafe_pytype(o)).as_buffer[]
    if !isnull(b) && !isnull(b.release[])
        ccall(b.release[Ptr], Cvoid, (PyPtr, Ptr{CPy_buffer}), o, view)
    end
    v.obj[] = C_NULL
    decref!(PyBorrowedRef(ptr(obj)))
    nothing
end

mutable struct PyBuffer
    o :: PyObject
    view :: Array{CPy_buffer, 0}
    flags :: UInt
    function PyBuffer(::Val{:unsafe}, _o, flags=CPyBUF_FULL_RO)
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
    elseif k == :itemtype
        t = pybuffer_itemtype(b)
    else
        getfield(b, k)
    end
end

pybuffer_itemtype(b::PyBuffer) = pybuffer_itemtype(b.format)

function pybuffer_itemtype(fmt::String)
    natbo = true
    natsz = true
    i = 1
    # first character encodes byte order and size
    m = match(r"^[@=<>!]\s*", fmt, i)
    if m !== nothing
        c = m.match[1]
        i += ncodeunits(m.match)
        natbo = (c in ('@', '=')) || (islittleendian() ? c == '<' : c in ('>', '!'))
        natsz = c == '@'
    end
    # now read the types
    types = []
    len = ncodeunits(fmt)
    while i ≤ len
        m = match(r"\s*([0-9]*)([a-zA-Z?])\s*", fmt, i)
        m !== nothing && m.offset == i || error("error parsing buffer format string at position $i: $(repr(fmt))")
        i += ncodeunits(m.match)
        n = isempty(m.captures[1]) ? 1 : parse(Int, m.captures[1])
        c = m.captures[2][1]
        if c == 'x'
            t = PaddingBytes{n}
            @assert sizeof(t) == n
            n = 1
        elseif c == 'c'
            t = natsz ? Cchar : Int8
        elseif c == 'b'
            t = natsz ? Cchar : Int8
        elseif c == 'B'
            t = natsz ? Cuchar : UInt8
        elseif c == '?'
            t = Bool
        elseif c == 'h'
            t = natsz ? Cshort : Int16
        elseif c == 'H'
            t = natsz ? Cushort : UInt16
        elseif c == 'i'
            t = natsz ? Cint : Int32
        elseif c == 'I'
            t = natsz ? Cuint : UInt32
        elseif c == 'l'
            t = natsz ? Clong : Int32
        elseif c == 'L'
            t = natsz ? Culong : UInt32
        elseif c == 'q'
            t = natsz ? Clonglong : Int64
        elseif c == 'Q'
            t = natsz ? Culonglong : UInt64
        elseif c == 'n'
            t = natsz ? Cssize_t : error("format character 'n' only valid with native sizing")
        elseif c == 'N'
            t = natsz ? Csize_t : error("format character 'N' only valid with native sizing")
        elseif c == 'e'
            t = Float16
        elseif c == 'f'
            t = Float32
        elseif c == 'd'
            t = Float64
        elseif c == 's'
            t = NTuple{n,UInt8}
            @assert sizeof(t) == n
            n = 1
        elseif c == 'p'
            t = PascalString{n}
            @assert sizeof(t) == n
            n = 1
        elseif c == 'P'
            t = natbo ? Ptr{Cvoid} : error("format character 'P' only valid with native byte ordering")
        else
            error("format character '$c' not recognized")
        end
        if !natbo && sizeof(t) > 1 && c != 's' && c != 'p'
            t = ByteReversed{t}
        end
        for i in 1:n
            if t <: PaddingBytes && !isempty(types) && types[end] <: PaddingBytes
                types[end] = PaddingBytes{types[end].parameters[1] + t.parameters[1]}
            else
                push!(types, t)
            end
        end
    end
    # done
    return length(types) == 1 ? types[1] : Tuple{types...}
end
