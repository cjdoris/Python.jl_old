### C types

abstract type AbstractCPyObject end

"""
    CPyObject

The layout of the PyObject_HEAD object header.
"""
Base.@kwdef struct CPyObject <: AbstractCPyObject
    # assumes _PyObject_HEAD_EXTRA is empty
    refcnt :: CPy_ssize_t = 0
    type :: Ptr{CPyObject} = C_NULL
end

abstract type AbstractCPyVarObject <: AbstractCPyObject end

"""
    CPyVarObject

The layout of the PyObject_VAR_HEAD object header.
"""
Base.@kwdef struct CPyVarObject <: AbstractCPyVarObject
    base :: CPyObject = CPyObject()
    size :: CPy_ssize_t = 0
end

### PyObject

struct PyObject{T<:AbstractCPyObject}
    ref :: PyObjRef
    function PyObject{T}(ref::PyObjRef, check::Bool=true) where {T<:AbstractCPyObject}
        check && isnull(ref) && pythrow()
        new{T}(ref)
    end
end
export PyObject

PyObjRef(o::PyObject) = getfield(o, :ref)

Base.cconvert(::Type{CPyPtr}, o::PyObject) = PyObjRef(o)
Base.cconvert(::Type{CPyStealPtr}, o::PyObject) = PyObjRef(o)

ptr(o::PyObject) = ptr(PyObjRef(o))

refcnt(o::PyObject) = refcnt(PyObjRef(o))

pynull(::Type{T}=CPyObject) where {T<:AbstractCPyObject} = PyObject{T}(PyObjRef(C_NULL), false)

function unsafe_cacheget!(f, o::PyObject)
    if isnull(o)
        p = f()
        if p isa PyObject || p isa PyObjRef
            p = CPyBorrowedPtr(ptr(p))
        end
        setptr!(PyObjRef(o), p)
    end
    return o
end

safe(o::PyObject) = isnull(o) ? pythrow() : o


### DEFAULT CONVERSION

unsafe_pyobj(T::Type, o::PyObjRef) = PyObject{T}(PyObjRef(o), false)
unsafe_pyobj(T::Type, o) = unsafe_pyobj(T, unsafe_pyobj(o))

unsafe_pyobj(o::PyObjRef) = unsafe_pyobj(CPyObject, o)
unsafe_pyobj(o::PyObject) = o
unsafe_pyobj(o::Nothing) = unsafe_pynone()
unsafe_pyobj(o::Bool) = unsafe_pybool(o)
unsafe_pyobj(o::AbstractString) = unsafe_pystr(o)
unsafe_pyobj(o::Tuple) = unsafe_pytuple_fromiter(o)
unsafe_pyobj(o::Integer) = unsafe_pyint(o)

PyObject(o::PyObject) = o
PyObject(o) = safe(unsafe_pyobj(o))

### API

pyis(o1::PyObject, o2::PyObject) = PyObjRef(o1).ptr == PyObjRef(o2).ptr
pyis(o1, o2) = pyis(PyObject(o1), PyObject(o2))
export pyis

unsafe_pyistrue(o::PyObject) =
    isnull(o) ? CPyBool() : @cpycall :PyObject_IsTrue(o::CPyPtr)::CPyBool
unsafe_pyistrue(o) =
    unsafe_pyistrue(unsafe_pyobj(o))
pyistrue(o) =
    safe(unsafe_pyistrue(o))
export pyistrue

unsafe_pynot(o::PyObject) =
    isnull(o) ? CPyBool() : @cpycall :PyObject_Not(o::CPyPtr)::CPyBool
unsafe_pynot(o) =
    unsafe_pynot(unsafe_pyobj(o))
pynot(o) =
    safe(unsafe_pynot(o))
export pynot

unsafe_pyrepr(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyObject_Repr(o::CPyPtr)::CPyNewPtr
unsafe_pyrepr(o) =
    unsafe_pyrepr(unsafe_pyobj(o))
unsafe_pyrepr(::Type{String}, o) =
    unsafe_pystr_asjuliastring(unsafe_pyrepr(o))
pyrepr(args...) =
    safe(unsafe_pyrepr(args...))
export pyrepr

unsafe_pyascii(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyObject_ASCII(o::CPyPtr)::CPyNewPtr
unsafe_pyascii(o) =
    unsafe_pyascii(unsafe_pyobj(o))
unsafe_pyascii(::Type{String}, o) =
    unsafe_pystr_asjuliastring(unsafe_pyascii(o))
pyascii(args...) =
    safe(unsafe_pyascii(args...))
export pyascii

unsafe_pystr(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyObject_Str(o::CPyPtr)::CPyNewPtr
unsafe_pystr(o) =
    unsafe_pystr(unsafe_pyobj(o))
unsafe_pystr(::Type{String}, o) =
    unsafe_pystr_asjuliastring(unsafe_pystr(o))
pystr(args...) =
    safe(unsafe_pystr(args...))
export pystr

unsafe_pybytes(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyObject_Bytes(o::CPyPtr)::CPyNewPtr
unsafe_pybytes(o) =
    unsafe_pybytes(unsafe_pyobj(o))
pybytes(args...) =
    safe(unsafe_pybytes(args...))
export pybytes

unsafe_pydir(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyObject_Dir(o::CPyPtr)::CPyNewPtr
unsafe_pydir(o) =
    unsafe_pydir(unsafe_pyobj(o))
pydir(o) =
    safe(unsafe_pydir(o))
export pydir

unsafe_pyhasattr(o::PyObject, a::PyObject) =
    (isnull(o) || isnull(a)) ? CPyBool() : @cpycall :PyObject_HasAttr(o::CPyPtr, a::CPyPtr)::CPyBool
unsafe_pyhasattr(o::PyObject, a::AbstractString) =
    isnull(o) ? CPyBool() : @cpycall :PyObject_HasAttrString(o::CPyPtr, a::Cstring)::CPyBool
unsafe_pyhasattr(o::PyObject, a::Symbol) =
    unsafe_pyhasattr(o, string(a))
unsafe_pyhasattr(o::PyObject, a) = unsafe_pyhasattr(o, unsafe_pyobj(a))
unsafe_pyhasattr(o, a) = unsafe_pyhasattr(unsafe_pyobj(o), a)
pyhasattr(o, a) = safe(unsafe_pyhasattr(o, a))
export pyhasattr

unsafe_pygetattr(o::PyObject, a::PyObject) =
    (isnull(o) || isnull(a)) ? pynull() : @cpycall :PyObject_GetAttr(o::CPyPtr, a::CPyPtr)::CPyNewPtr
unsafe_pygetattr(o::PyObject, a::AbstractString) =
    isnull(o) ? pynull() : @cpycall :PyObject_GetAttrString(o::CPyPtr, a::Cstring)::CPyNewPtr
unsafe_pygetattr(o::PyObject, a::Symbol) =
    unsafe_pygetattr(o, string(a))
unsafe_pygetattr(o::PyObject, a) = unsafe_pygetattr(o, unsafe_pyobj(a))
unsafe_pygetattr(o, a) = unsafe_pygetattr(unsafe_pyobj(o), a)
pygetattr(o, a) = safe(unsafe_pygetattr(o, a))
export pygetattr

unsafe_pysetattr(o::PyObject, a::PyObject, v::PyObject) =
    (isnull(o) || isnull(a) || isnull(v)) ? CPyVoidInt() :
    @cpycall :PyObject_SetAttr(o::CPyPtr, a::CPyPtr, v::CPyPtr)::CPyVoidInt
unsafe_pysetattr(o::PyObject, a::AbstractString, v::PyObject) =
    (isnull(o) || isnull(v)) ? CPyVoidInt() :
    @cpycall :PyObject_SetAttrString(o::CPyPtr, a::Cstring, v::CPyPtr)::CPyVoidInt
unsafe_pysetattr(o::PyObject, a::Symbol, v::PyObject) =
    unsafe_pysetattr(o, string(a), v)
unsafe_pysetattr(o::PyObject, a, v::PyObject) = unsafe_pysetattr(o, unsafe_pyobj(a), v)
unsafe_pysetattr(o, a, v) = unsafe_pysetattr(unsafe_pyobj(o), a, unsafe_pyobj(v))
pysetattr(o, a, v) = safe(unsafe_pysetattr(o, a, v))
export pysetattr

unsafe_pydelattr(o::PyObject, a::PyObject) =
    (isnull(o) || isnull(a)) ? CPyVoidInt() :
    @cpycall :PyObject_SetAttr(o::CPyPtr, a::CPyPtr, C_NULL::Ptr{Cvoid})::CPyVoidInt
unsafe_pydelattr(o::PyObject, a::AbstractString) =
    (isnull(o)) ? CPyVoidInt() :
    @cpycall :PyObject_SetAttrString(o::CPyPtr, a::Cstring, C_NULL::Ptr{Cvoid})::CPyVoidInt
unsafe_pydelattr(o::PyObject, a::Symbol) =
    unsafe_pydelattr(o, string(a))
unsafe_pydelattr(o::PyObject, a) = unsafe_pydelattr(o, unsafe_pyobj(a))
unsafe_pydelattr(o, a) = unsafe_pydelattr(unsafe_pyobj(o), a)
pydelattr(o, a) = safe(unsafe_pydelattr(o, a))
export pydelattr

@enum Py_CompareOp::Cint Py_LT=0 Py_LE=1 Py_EQ=2 Py_NE=3 Py_GT=4 Py_GE=5

unsafe_pycompare(::Type{PyObject}, o1::PyObject, o2::PyObject, op::Py_CompareOp) =
    (isnull(o1) || isnull(o2)) ? pynull() :
    @cpycall :PyObject_RichCompare(o1::CPyPtr, o2::CPyPtr, op::Py_CompareOp)::CPyNewPtr
unsafe_pycompare(::Type{Bool}, o1::PyObject, o2::PyObject, op::Py_CompareOp) =
    (isnull(o1) || isnull(o2)) ? CPyBool() :
    @cpycall :PyObject_RichCompareBool(o1::CPyPtr, o2::CPyPtr, op::Py_CompareOp)::CPyBool
unsafe_pycompare(T::Type, o1, o2, op) =
    unsafe_pycompare(T, unsafe_pyobj(o1), unsafe_pyobj(o2), convert(Py_CompareOp, op))
unsafe_pycompare(T::Type, o1, o2, ::typeof(==)) = unsafe_pycompare(T, o1, o2, Py_EQ)
unsafe_pycompare(T::Type, o1, o2, ::typeof(!=)) = unsafe_pycompare(T, o1, o2, Py_NE)
unsafe_pycompare(T::Type, o1, o2, ::typeof(<=)) = unsafe_pycompare(T, o1, o2, Py_LE)
unsafe_pycompare(T::Type, o1, o2, ::typeof(< )) = unsafe_pycompare(T, o1, o2, Py_LT)
unsafe_pycompare(T::Type, o1, o2, ::typeof(>=)) = unsafe_pycompare(T, o1, o2, Py_GE)
unsafe_pycompare(T::Type, o1, o2, ::typeof(> )) = unsafe_pycompare(T, o1, o2, Py_GT)
unsafe_pycompare(o1, o2, op) = unsafe_pycompare(Bool, o1, o2, op)
pycompare(args...) = safe(unsafe_pycompare(args...))
export pycompare

unsafe_pyeq(T::Type, o1, o2) = unsafe_pycompare(T, o1, o2, ==)
unsafe_pyeq(o1, o2) = unsafe_pycompare(o1, o2, ==)
pyeq(args...) = safe(unsafe_pyeq(args...))
export pyeq

unsafe_pyne(T::Type, o1, o2) = unsafe_pycompare(T, o1, o2, ==)
unsafe_pyne(o1, o2) = unsafe_pycompare(o1, o2, ==)
pyne(args...) = safe(unsafe_pyne(args...))
export pyne

unsafe_pyle(T::Type, o1, o2) = unsafe_pycompare(T, o1, o2, ==)
unsafe_pyle(o1, o2) = unsafe_pycompare(o1, o2, ==)
pyle(args...) = safe(unsafe_pyle(args...))
export pyle

unsafe_pylt(T::Type, o1, o2) = unsafe_pycompare(T, o1, o2, ==)
unsafe_pylt(o1, o2) = unsafe_pycompare(o1, o2, ==)
pylt(args...) = safe(unsafe_pylt(args...))
export pylt

unsafe_pyge(T::Type, o1, o2) = unsafe_pycompare(T, o1, o2, ==)
unsafe_pyge(o1, o2) = unsafe_pycompare(o1, o2, ==)
pyge(args...) = safe(unsafe_pyge(args...))
export pyge

unsafe_pygt(T::Type, o1, o2) = unsafe_pycompare(T, o1, o2, ==)
unsafe_pygt(o1, o2) = unsafe_pycompare(o1, o2, ==)
pygt(args...) = safe(unsafe_pygt(args...))
export pygt

unsafe_pyissubclass(o1::PyObject, o2::PyObject) =
    (isnull(o1) || isnull(o2)) ? CPyBool() :
    @cpycall :PyObject_IsSubclass(o1::CPyPtr, o2::CPyPtr)::CPyBool
unsafe_pyissubclass(o1, o2) =
    unsafe_pyissubclass(unsafe_pyobj(o1), unsafe_pyobj(o2))
pyissubclass(o1, o2) = safe(unsafe_pyissubclass(o1, o2))
export pyissubclass

unsafe_pyisinstance(o1::PyObject, o2::PyObject) =
    (isnull(o1) || isnull(o2)) ? CPyBool() :
    @cpycall :PyObject_IsInstance(o1::CPyPtr, o2::CPyPtr)::CPyBool
unsafe_pyisinstance(o1, o2) =
    unsafe_pyisinstance(unsafe_pyobj(o1), unsafe_pyobj(o2))
pyisinstance(o1, o2) = safe(unsafe_pyisinstance(o1, o2))
export pyisinstance

function unsafe_pycall_args(func, args, kwargs=())
    f = unsafe_pyobj(func)
    isnull(f) && return pynull()
    a = unsafe_pytuple_fromiter(args)
    isnull(a) && return pynull()
    if isempty(kwargs)
        return @cpycall :PyObject_Call(f::CPyPtr, a::CPyPtr, C_NULL::Ptr{Cvoid})::CPyNewPtr
    else
        error("keyword arguments not implemented")
    end
end
pycall_args(func, args, kwargs=()) =
    safe(unsafe_pycall_args(func, args, kwargs))

unsafe_pycall(func, args...; kwargs...) =
    unsafe_pycall(func, args, kwargs)
pycall(func, args...; kwargs...) =
    safe(unsafe_pycall_args(func, args, kwargs))
export pycall

unsafe_pyobject(args...; kwargs...) = unsafe_pycall_args(unsafe_pyobjecttype(), args, kwargs)
pyobject(args...; kwargs...) = safe(unsafe_pyobject(args...; kwargs...))
export pyobject

unsafe_pysuper(args...; kwargs...) = unsafe_pycall_args(unsafe_pysupertype(), args, kwargs)
pysuper(args...; kwargs...) = safe(unsafe_pysuper(args...; kwargs...))
export pysuper

unsafe_pytype(args...; kwargs...) = unsafe_pycall_args(unsafe_pytypetype(), args, kwargs)
pytype(args...; kwargs...) = safe(unsafe_pytype(args...; kwargs...))
export pytype

unsafe_pyhash(o::PyObject) =
    isnull(o) ? CPyHashT() : @cpycall :PyObject_Hash(o::CPyPtr)::CPyHashT
unsafe_pyhash(o) =
    unsafe_pyhash(unsafe_pyobj(o))
pyhash(args...; kwargs...) = safe(unsafe_pyhash(args...; kwargs...))
export pyhash

unsafe_pylen(o::PyObject) =
    isnull(o) ? CPySsizeT() : @cpycall :PyObject_Length(o::CPyPtr)::CPySsizeT
unsafe_pylen(o) = unsafe_pylen(unsafe_pyobj(o))
pylen(args...; kwargs...) = safe(unsafe_pylen(args...; kwargs...))
export pylen

unsafe_pyiter(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyObject_GetIter(o::CPyPtr)::CPyNewPtr
unsafe_pyiter(o) = unsafe_pyiter(unsafe_pyobj(o))
pyiter(args...; kwargs...) = safe(unsafe_pyiter(args...; kwargs...))
export pyiter

unsafe_pygetitem(o::PyObject, i::PyObject) =
    (isnull(o) || isnull(i)) ? pynull() :
    @cpycall :PyObject_GetItem(o::CPyPtr, i::CPyPtr)::CPyNewPtr
unsafe_pygetitem(o, i) =
    unsafe_pygetitem(unsafe_pyobj(o), unsafe_pyobj(i))
pygetitem(o, i) = safe(unsafe_pygetitem(o, i))
export pygetitem

unsafe_pysetitem(o::PyObject, i::PyObject, v::PyObject) =
    (isnull(o) || isnull(i) || isnull(v)) ? CPyVoidInt() :
    @cpycall :PyObject_SetItem(o::CPyPtr, i::CPyPtr, v::CPyPtr)::CPyVoidInt
unsafe_pysetitem(o, i, v) =
    unsafe_pysetitem(unsafe_pyobj(o), unsafe_pyobj(i), unsafe_pyobj(v))
pysetitem(o, i, v) = safe(unsafe_pysetitem(o, i, v))
export pysetitem

unsafe_pydelitem(o::PyObject, i::PyObject) =
    (isnull(o) || isnull(i)) ? CPyVoidInt() :
    @cpycall :PyObject_DelItem(o::CPyPtr, i::CPyPtr)::CPyVoidInt
unsafe_pydelitem(o, i) =
    unsafe_pydelitem(unsafe_pyobj(o), unsafe_pyobj(i))
pydelitem(o, i) = safe(unsafe_pydelitem(o, i))
export pydelitem


### BASE

function Base.show(io::IO, o::PyObject)
    if isnull(o)
        print(io, "<NULL>")
    else
        print(io, pyrepr(String, o))
    end
    get(io, :typeinfo, Any) === typeof(o) ||
        print(io, " :: ", typeof(o))
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

_getproperty(o, ::Val{Symbol("b!")}) =
    pyistrue(o)

_getproperty(o, ::Val{Symbol("s!")}) =
    pystr(String, o)

_getproperty(o, ::Val{Symbol("r!")}) =
    pyrepr(String, o)

_getproperty(o, ::Val{Symbol("i!")}) =
    pyint_convert(Int, pyint(o))

_getproperty(o, ::Val{Symbol("u!")}) =
    pyint_convert(UInt, pyint(o))

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
