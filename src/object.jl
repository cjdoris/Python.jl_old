pyis(o1, o2) = ptr(PyObject(o1)) == ptr(PyObject(o2))
export pyis

unsafe_pyrepr(::Type{String}, o) =
    unsafe_pystr_asjuliastring(unsafe_pyrepr(o))

unsafe_pyascii(::Type{String}, o) =
    unsafe_pystr_asjuliastring(unsafe_pyascii(o))

unsafe_pystr(::Type{String}, o) =
    unsafe_pystr_asjuliastring(unsafe_pystr(o))

unsafe_pyhasattr(o, a::Symbol) =
    unsafe_pyhasattr(o, string(a))

unsafe_pygetattr(o, a::Symbol) =
    unsafe_pygetattr(o, string(a))

unsafe_pysetattr(o, a::Symbol, v) =
    unsafe_pysetattr(o, string(a), v)

unsafe_pydelattr(o, a::Symbol) =
    unsafe_pydelattr(o, string(a))

unsafe_pycompare(o1, o2, ::typeof(==)) = unsafe_pycompare(o1, o2, CPy_EQ)
unsafe_pycompare(o1, o2, ::typeof(!=)) = unsafe_pycompare(o1, o2, CPy_NE)
unsafe_pycompare(o1, o2, ::typeof(<=)) = unsafe_pycompare(o1, o2, CPy_LE)
unsafe_pycompare(o1, o2, ::typeof(< )) = unsafe_pycompare(o1, o2, CPy_LT)
unsafe_pycompare(o1, o2, ::typeof(>=)) = unsafe_pycompare(o1, o2, CPy_GE)
unsafe_pycompare(o1, o2, ::typeof(> )) = unsafe_pycompare(o1, o2, CPy_GT)

unsafe_pyeq(o1, o2) = unsafe_pycompare(o1, o2, CPy_EQ)
unsafe_pyne(o1, o2) = unsafe_pycompare(o1, o2, CPy_NE)
unsafe_pyle(o1, o2) = unsafe_pycompare(o1, o2, CPy_LE)
unsafe_pylt(o1, o2) = unsafe_pycompare(o1, o2, CPy_LT)
unsafe_pyge(o1, o2) = unsafe_pycompare(o1, o2, CPy_GE)
unsafe_pygt(o1, o2) = unsafe_pycompare(o1, o2, CPy_GT)

pyeq(o1, o2) = safe(unsafe_pyeq(o1, o2))
pyne(o1, o2) = safe(unsafe_pyne(o1, o2))
pyle(o1, o2) = safe(unsafe_pyle(o1, o2))
pylt(o1, o2) = safe(unsafe_pylt(o1, o2))
pyge(o1, o2) = safe(unsafe_pyge(o1, o2))
pygt(o1, o2) = safe(unsafe_pygt(o1, o2))
export pyeq, pyne, pyle, pylt, pyge, pygt

function unsafe_pycall_args(func, args, kwargs=())
    f = unsafe_pyobj(func)
    isnull(f) && return PYNULL
    a = unsafe_pytuple_fromiter(args)
    isnull(a) && return PYNULL
    if isempty(kwargs)
        k = PYNULL
    else
        k = unsafe_pydict_fromstringpairs(kwargs)
        isnull(k) && return PYNULL
    end
    r = ccall((:PyObject_Call, PYLIB), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), f, a, k)
    isnull(r) && return PYNULL
    return unsafe_pyobj(PyObjRef(r, false))
end
pycall_args(func, args, kwargs=()) =
    safe(unsafe_pycall_args(func, args, kwargs))

unsafe_pycall(func, args...; kwargs...) =
    unsafe_pycall(func, args, kwargs)
pycall(func, args...; kwargs...) =
    safe(unsafe_pycall_args(func, args, kwargs))
export pycall

### BASE

function Base.show(io::IO, o::PyObject)
    get(io, :typeinfo, Any) === typeof(o) ||
        print(io, "py: ")
    if isnull(o)
        print(io, "<NULL>")
    else
        print(io, pyrepr(String, o))
    end
end

function Base.print(io::IO, o::PyObject)
    if isnull(o)
        print(io, "<NULL>")
    else
        print(io, pystr(String, o))
    end
end

Base.getproperty(o::PyObject, a::Symbol) =
    _getproperty(o, Val(a))

_getproperty(o, ::Val{a}) where {a} =
    pygetattr(o, a)

_getproperty(o, ::Val{Symbol("b!")}) = pyistrue(o)
_getproperty(o, ::Val{Symbol("s!")}) = pystr(String, o)
_getproperty(o, ::Val{Symbol("r!")}) = pyrepr(String, o)
_getproperty(o, ::Val{Symbol("i!")}) = pyint_convert(Int, pyint(o))
_getproperty(o, ::Val{Symbol("u!")}) = pyint_convert(UInt, pyint(o))
_getproperty(o, ::Val{Symbol("f!")}) = pyfloat_convert(Float64, pyfloat(o))

Base.setproperty!(o::PyObject, a::Symbol, v) =
    pysetattr(o, a, v)

Base.propertynames(o::PyObject) =
    [Symbol(pystr(String, x)) for x in pydir(o)]

Base.:(==)(o1::PyObject, o2::PyObject) = pyeq(o1, o2)
Base.:(!=)(o1::PyObject, o2::PyObject) = pyne(o1, o2)
Base.:(<=)(o1::PyObject, o2::PyObject) = pyle(o1, o2)
Base.:(< )(o1::PyObject, o2::PyObject) = pylt(o1, o2)
Base.:(>=)(o1::PyObject, o2::PyObject) = pyge(o1, o2)
Base.:(> )(o1::PyObject, o2::PyObject) = pygt(o1, o2)

(f::PyObject)(args...; kwargs...) = pycall_args(f, args, kwargs)

Base.length(o::PyObject) = convert(Int, pylen(o))
Base.firstindex(o::PyObject) = 0
Base.lastindex(o::PyObject) = length(o)-1

Base.IteratorSize(::Type{<:PyObject}) = Base.SizeUnknown()

Base.eltype(o::PyObject) = PyObject{CPyObject}

function Base.iterate(o::PyObject, s=nothing)
    s = s===nothing ? pyiter(o) : s
    x = unsafe_pyiter_next(s)
    if !isnull(x)
        return x, s
    elseif pyerror_occurred()
        pythrow()
    else
        return nothing
    end
end

Base.getindex(o::PyObject, i) = pygetitem(o, i)
Base.getindex(o::PyObject, i...) = pygetitem(o, i)

Base.setindex!(o::PyObject, v, i) = (pysetitem(o, i, v); o)
Base.setindex!(o::PyObject, v, i...) = (pysetitem(o, i, v); o)

Base.delete!(o::PyObject, i) = (pydelitem(o, i); o)
Base.delete!(o::PyObject, i...) = (pydelitem(o, i); o)
