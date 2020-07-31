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
    return unsafe_pyobj(PyRef(r, false))
end
pycall_args(func, args, kwargs=()) =
    safe(unsafe_pycall_args(func, args, kwargs))

unsafe_pycall(func, args...; kwargs...) =
    unsafe_pycall_args(func, args, kwargs)
pycall(func, args...; kwargs...) =
    safe(unsafe_pycall_args(func, args, kwargs))
export pycall

### CONVERSION

unsafe_pyconvert_quick(::Type{T}, o) where {T} = unsafe_pyconvert_quick(T, T, o)
function unsafe_pyconvert_quick(::Type{T}, ::Type{S}, o) where {T, S}
    r = unsafe_pyconvert_quick_rule(T, S, o) :: ValueOrNothingOrError{T}
    if S===Any || r.iserr || !r.isnothing
        return r
    else
        return unsafe_pyconvert_quick(T, supertype(S), o)
    end
end

unsafe_pyconvert_quick_rule(T, S, o) = ValueOrNothingOrError{T}(nothing)

function unsafe_pyconvert_generic(T, o)
    mro = PyBorrowedRef(uptr(CPyTypeObject, uptr(CPyObject, o).type[]).mro[])
    len = ccall((:PyTuple_Size, PYLIB), CPy_ssize_t, (PyPtr,), mro)
    for i in 1:len
        b = ccall((:PyTuple_GetItem, PYLIB), PyPtr, (PyPtr, CPy_ssize_t), mro, i-1)
        name = Symbol(unsafe_string(uptr(CPyTypeObject, b).name[]))
        r = unsafe_pyconvert_generic(T, Val(name), o) :: ValueOrNothingOrError{T}
        if r.iserr || !r.isnothing
            return r
        end
    end
    return ValueOrNothingOrError{T}(nothing)
end

unsafe_pyconvert_generic(::Type{T}, name, o) where {T} =
    unsafe_pyconvert_generic_rule(T, name, o) :: ValueOrNothingOrError{T}

unsafe_pyconvert_generic_rule(T, name, o) = ValueOrNothingOrError{T}(nothing)

unsafe_pyconvert_generic_rule(::Type{T}, ::Val{:int}, o) where {T<:Number} =
    convert(ValueOrNothingOrError{T}, unsafe_pyint_convert(T, o))
unsafe_pyconvert_generic_rule(::Type{T}, ::Val{:int}, o) where {T>:Number} =
    convert(ValueOrNothingOrError{T}, unsafe_pyint_convert(BigInt, o))

unsafe_pyconvert_generic_rule(::Type{T}, ::Val{:float}, o) where {T<:Number} =
    convert(ValueOrNothingOrError{T}, unsafe_pyfloat_convert(T, o))
unsafe_pyconvert_generic_rule(::Type{T}, ::Val{:float}, o) where {T>:Number} =
    convert(ValueOrNothingOrError{T}, unsafe_pyfloat_convert(Float64, o))

unsafe_pyconvert_generic_rule(::Type{T}, ::Val{:str}, o) where {T<:AbstractString} =
    convert(ValueOrNothingOrError{T}, unsafe_pystr_convert(T, o))
unsafe_pyconvert_generic_rule(::Type{T}, ::Val{:str}, o) where {T>:AbstractString} =
    convert(ValueOrNothingOrError{T}, unsafe_pystr_convert(String, o))
unsafe_pyconvert_generic_rule(::Type{Symbol}, ::Val{:str}, o) =
    let r = unsafe_pystr_convert(String, o)
        r.iserr ? ValueOrNothingOrError{Symbol}() : ValueOrNothingOrError{Symbol}(Some(Symbol(r.value)))
    end

function unsafe_pytryconvert(T::Union, o)
    R = ValueOrNothingOrError{T}
    a = unsafe_pytryconvert(T.a, o)
    a.iserr && return R()
    b = unsafe_pytryconvert(T.b, o)
    b.iserr && return R()
    if a.isnothing
        if b.isnothing
            return R(nothing)
        else
            return R(Some(b.value))
        end
    else
        if b.isnothing
            return R(Some(a.value))
        else
            pyerror_set_TypeError("ambiguous conversion")
            return R()
        end
    end
end
function unsafe_pytryconvert(::Type{T}, o) where {T}
    R = ValueOrNothingOrError{T}
    if !isa(o, AbstractPyRef)
        o = unsafe_pyobj(o)
        isnull(o) && return R()
    end
    r = unsafe_pyconvert_quick(T, o) :: ValueOrNothingOrError{T}
    r.iserr && return R()
    r.isnothing || return R(Some(r.value))
    r = unsafe_pyconvert_generic(T, o) :: ValueOrNothingOrError{T}
    return r
end
function unsafe_pyconvert(::Type{T}, o) where {T}
    R = ValueOrError{T}
    r = unsafe_pytryconvert(T, o)
    if r.iserr
        return R()
    elseif r.isnothing
        pyerror_set_TypeError("cannot convert $(pytype(o).__name__) to julia.$T")
        return R()
    else
        return R(r.value)
    end
end
pytryconvert(T, o) = safe(unsafe_pytryconvert(T, o))
pyconvert(T, o) = safe(unsafe_pyconvert(T, o))
export pytryconvert, pyconvert

@generated unsafe_pyconvertkey(o, ko) =
    try
        :(unsafe_pyconvert($(keytype(o)), ko))
    catch
        :(unsafe_pyconvert(Any, ko))
    end

unsafe_pyconvertkey(o::NamedTuple, ko) =
    unsafe_pyconvert(Union{Int,Symbol}, ko)

unsafe_pyconvertvalue(o, k, vo) = unsafe_pyconvertvalue(o, vo)

@generated unsafe_pyconvertvalue(o, vo) =
    try
        :(unsafe_pyconvert($(eltype(o)), ko))
    catch
        :(unsafe_pyconvert(Any, ko))
    end

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

_getproperty(o, ::Val{Symbol("jl!b")}) = pytruth(o)
_getproperty(o, ::Val{Symbol("jl!s")}) = pystr(String, o)
_getproperty(o, ::Val{Symbol("jl!r")}) = pyrepr(String, o)
_getproperty(o, ::Val{Symbol("jl!i")}) = pyint_convert(Int, pyint(o))
_getproperty(o, ::Val{Symbol("jl!u")}) = pyint_convert(UInt, pyint(o))
_getproperty(o, ::Val{Symbol("jl!f")}) = pyfloat_convert(Float64, pyfloat(o))
_getproperty(o, ::Val{Symbol("jl!list")}) = (args...)->PyList(args..., o)
_getproperty(o, ::Val{Symbol("jl!dict")}) = (args...)->PyDict(args..., o)
_getproperty(o, ::Val{Symbol("jl!array")}) = (args...)->PyArray(args..., o)

Base.setproperty!(o::PyObject, a::Symbol, v) =
    pysetattr(o, a, v)

function Base.propertynames(o::PyObject)
    # this follows the logic of rlcompleter.py
    function classmembers(c)
        r = pydir(c)
        if pyhasattr(c, "__bases__")
            for b in c.__bases__
                r += classmembers(b)
            end
        end
        return r
    end
    words = pyset(pydir(o))
    words.discard("__builtins__")
    if pyhasattr(o, "__class__")
        words.add("__class__")
        words.update(classmembers(o.__class__))
    end
    [Symbol(pystr(String, x)) for x in words]
end

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
