"""
    PyObjRef(ptr)

Holds a single reference to the Python object pointed to by `ptr`, which is automatically decref'd on garbage collection.

It basically has no other semantics, these are provided by `PyObject` which wraps this.
"""
mutable struct PyObjRef
    ptr :: Ptr{Cvoid}
    function PyObjRef(ptr::Ptr=C_NULL)
        ref = new(Ptr{Cvoid}(ptr))
        finalizer(decref, ref)
        return ref
    end
end

PyObjRef(o::PyObjRef) = o
ptr(o::PyObjRef) = o.ptr
refcnt(o::PyObjRef) = uptr(CPyObject, ptr(o)).refcnt[]
decref(o) = (ccall((:Py_DecRef, PYLIB), Cvoid, (Ptr{Cvoid},), ptr(o)); o)
incref(o) = (ccall((:Py_IncRef, PYLIB), Cvoid, (Ptr{Cvoid},), ptr(o)); o)

iserr(o::PyObjRef) = isnull(o)
value(o::PyObjRef) = o

iserr(o::Cvoid) = pyerror_occurred()
value(o::Cvoid) = o

abstract type AbstractCPyCallType end

iserr(o::AbstractCPyCallType) = error("not implemented")
value(o::AbstractCPyCallType) = error("not implemented")
cpycall_errhook(o) = nothing
cpycall_returnhook(o) = o
cpycall_ctype(::Type{T}) where {T<:AbstractCPyCallType} = cpycall_ctype(fieldtype(T, 1))
cpycall_toc(o::AbstractCPyCallType) = getfield(o, 1)
cpycall_fromc(::Type{T}, o) where {T<:AbstractCPyCallType} = T(o)

cpycall_ctype(::Type{T}) where {T} = T
cpycall_toc(o) = o
cpycall_fromc(::Type{T}, o) where {T} = convert(T, o)

"""
    CPyPtr

Use as an argument type in `ccall` for `PyObject*` arguments that don't steal a reference.
"""
struct CPyPtr <: AbstractCPyCallType
    ptr :: Ptr{Cvoid}
end

ptr(p::CPyPtr) = p.ptr

Base.cconvert(::Type{CPyPtr}, o::PyObjRef) = o
Base.unsafe_convert(::Type{CPyPtr}, o::PyObjRef) = CPyPtr(o.ptr)
Base.unsafe_convert(::Type{Ptr{Cvoid}}, o::CPyPtr) = o.ptr

"""
    CPyStealPtr

Use as an argument type in `ccall` for `PyObject*` arguments that steal the reference.

If the true argument is a `PyObjRef` (or `PyObject`), the reference count is automatically increased.
"""
struct CPyStealPtr <: AbstractCPyCallType
    ptr :: Ptr{Cvoid}
end

ptr(p::CPyStealPtr) = p.ptr

Base.cconvert(::Type{CPyStealPtr}, o::PyObjRef) = o

function Base.unsafe_convert(::Type{CPyStealPtr}, o::PyObjRef)
    incref(o)
    CPyStealPtr(o.ptr)
end

Base.unsafe_convert(::Type{Ptr{Cvoid}}, o::CPyStealPtr) = o.ptr

cpycall_errhook(p::CPyStealPtr) = ccall((:Py_DecRef, PYLIB), Cvoid, (Ptr{Cvoid},), p.ptr)

"""
    CPyNoErr{T}

Use as a return type in `ccall` when the result is never an error.
"""
struct CPyNoErr{T} <: AbstractCPyCallType
    value :: T
end

CPyNoErr{T}(args...) where {T} = CPyNoErr(T(args...))

iserr(o::CPyNoErr) = false
value(o::CPyNoErr) = value(o.value)

cpycall_returnhook(o::CPyNoErr) = CPyNoErr(cpycall_returnhook(o.value))

ptr(o::CPyNoErr) = ptr(o.value)

"""
    CPyAmbigErr{T}

Use as a return type in `ccall` when the result error value is also a valid return value.
"""
struct CPyAmbigErr{T} <: AbstractCPyCallType
    value :: T
end

CPyAmbigErr{T}(args...) where {T} = CPyAmbigErr(T(args...))

iserr(o::CPyAmbigErr) = iserr(o.value) && pyerror_occurred()
value(o::CPyAmbigErr) = value(o.value)

cpycall_returnhook(o::CPyAmbigErr) = CPyAmbigErr(cpycall_returnhook(o.value))

ptr(o::CPyAmbigErr) = ptr(o.value)

"""
    CPyNewPtr

Use as a return type in `ccall` for a new `PyObject*` reference.

Should be immediately wrapped with `PyObjRef(ptr)`.
"""
struct CPyNewPtr <: AbstractCPyCallType
    ptr :: Ptr{Cvoid}
end
CPyNewPtr() = CPyNewPtr(C_NULL)

Base.convert(::Type{CPyNewPtr}, x::Ptr) = CPyNewPtr(x)

ptr(p::CPyNewPtr) = p.ptr
iserr(p::CPyNewPtr) = isnull(ptr(p))

PyObjRef(p::CPyNewPtr) = setptr!(PyObjRef(), p)
PyNewObjRef(p::Union{Ptr,UnsafePtr}) = PyObjRef(CPyNewPtr(p))

function setptr!(r::PyObjRef, p::CPyNewPtr)
    r.ptr = ptr(p)
    r
end

cpycall_returnhook(o::CPyNewPtr) = unsafe_pyobj(PyObjRef(o))

"""
    CPyBorrowedPtr

Use as a return type in `ccall` for a borrowed `PyObject*` reference.
"""
struct CPyBorrowedPtr <: AbstractCPyCallType
    ptr :: Ptr{Cvoid}
end
CPyBorrowedPtr() = CPyBorrowedPtr(C_NULL)

Base.convert(::Type{CPyBorrowedPtr}, x::Ptr) = CPyNewPtr(x)

ptr(p::CPyBorrowedPtr) = p.ptr
iserr(p::CPyBorrowedPtr) = isnull(ptr(p))

PyObjRef(p::CPyBorrowedPtr) = setptr!(PyObjRef(), p)
PyBorrowedObjRef(p::Union{Ptr,UnsafePtr}) = PyObjRef(CPyBorrowedPtr(p))

function setptr!(r::PyObjRef, p::CPyBorrowedPtr)
    incref(p)
    r.ptr = ptr(p)
    r
end

cpycall_returnhook(o::CPyBorrowedPtr) = unsafe_pyobj(PyObjRef(o))

"""
    CPyBool

Use as a return type in `ccall` for a `Cint` representing a boolean, with `-1` representing an error.
"""
struct CPyBool <: AbstractCPyCallType
    value :: Cint
end
CPyBool() = CPyBool(-1)

iserr(o::CPyBool) = o.value == -1
value(o::CPyBool) = o.value != 0

"""
    CPyNumber{T<:Number}

Use as a return type in `ccall` for a `T`, with `-1` representing an error.
"""
struct CPyNumber{T<:Number} <: AbstractCPyCallType
    value :: T
end
CPyNumber{T}() where {T} = CPyNumber{T}(zero(T) - one(T))

const CPyInt = CPyNumber{Cint}
const CPyHashT = CPyNumber{CPy_hash_t}
const CPySsizeT = CPyNumber{CPy_ssize_t}
const CPyAmbigNumber{T} = CPyAmbigErr{CPyNumber{T}}

(::Type{T})(x) where {S, T<:CPyAmbigErr{S}} = T(S(x))

iserr(o::CPyNumber) = o.value == (zero(o.value) - one(o.value))
value(o::CPyNumber) = o.value

"""
    CPyVoidInt

Use as a return type in `ccall` for an `Cint` which is only used to indicate error.
"""
struct CPyVoidInt <: AbstractCPyCallType
    value :: Cint
end
CPyVoidInt() = CPyVoidInt(-1)

iserr(o::CPyVoidInt) = o.value == -1
value(::CPyVoidInt) = nothing

struct ValueOrError{T}
    iserr :: Bool
    value :: T
    ValueOrError{T}() where {T} = new{T}(true)
    ValueOrError{T}(iserr::Bool, value) where {T} = new{T}(iserr, convert(T, value))
end
ValueOrError{T}(value) where {T} = ValueOrError{T}(false, value)
ValueOrError(iserr::Bool, value::T) where {T} = ValueOrError{T}(iserr, value)
ValueOrError(value) = ValueOrError(false, value)

iserr(o::ValueOrError) = o.iserr
value(o::ValueOrError) = o.value

safe(o) = iserr(o) ? pythrow() : value(o)
