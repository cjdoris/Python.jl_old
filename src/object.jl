pyis(o1::AbstractPyRef, o2::AbstractPyRef) = ptr(o1) == ptr(o2)
pyis(o1, o2) = false
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

unsafe_pyconvert_rule(T, name, o) = VNE{T}(nothing)

unsafe_pyconvert_rule(::Type{T}, ::Val{:NoneType}, o) where {T<:Nothing} =
    VNE{Nothing}(Some(nothing))
unsafe_pyconvert_rule(::Type{T}, ::Val{:NoneType}, o) where {T>:Nothing} =
    VNE{Nothing}(Some(nothing))

unsafe_pyconvert_rule(::Type{T}, ::Val{:int}, o) where {T<:Number} =
    unsafe_pyint_tryconvert(T, o)
unsafe_pyconvert_rule(::Type{T}, ::Val{:int}, o) where {T>:Number} =
    unsafe_pyint_tryconvert(Number, o)

unsafe_pyconvert_rule(::Type{T}, ::Val{:float}, o) where {T<:Number} =
    unsafe_pyfloat_tryconvert(T, o)
unsafe_pyconvert_rule(::Type{T}, ::Val{:float}, o) where {T>:Number} =
    unsafe_pyfloat_tryconvert(Number, o)

unsafe_pyconvert_rule(::Type{T}, ::Val{:str}, o) where {T<:AbstractString} =
    unsafe_pystr_tryconvert(T, o)
unsafe_pyconvert_rule(::Type{T}, ::Val{:str}, o) where {T>:AbstractString} =
    unsafe_pystr_tryconvert(AbstractString, o)
unsafe_pyconvert_rule(::Type{Symbol}, ::Val{:str}, o) =
    unsafe_pystr_tryconvert(Symbol, o)

function unsafe_pyconvert_rule(::Type{T}, ::Val{Symbol("julia.Any")}, o) where {T}
    x = unsafe_pyjulia_getvalue(o)
    iserr(x) && return VNE{T}()
    try
        y = convert(T, value(x))
        return VNE{T}(Some(y))
    catch err
        if err isa MethodError && err.f === convert && err.args === (T, value(x))
            return VNE{T}(nothing)
        else
            rethrow()
        end
    end
end

function unsafe_pytryconvert_union(::Type{A}, ::Type{B}, o::AbstractPyRef) where {A,B}
    R = VNE{Union{A,B}}
    a = unsafe_pytryconvert(A, o)
    a.iserr && return R()
    b = unsafe_pytryconvert(B, o)
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

function unsafe_pytryconvert(::Type{T}, o::AbstractPyRef) where {T}
    R = VNE{T}
    _R = VNE{<:T}
    r::R = R()

    # FAST SPECIAL CASES
    # TODO: UnionAll
    # TODO: Fast checks for int, list, etc
    if T === Union{}
        # nothing converts to the bottom type
        return R(nothing)
    elseif T isa Union
        # deal with each piece of a union separately
        return unsafe_pytryconvert_union(T.a, T.b, o)::R
    elseif T <: AbstractPyObject
        # if we ask for a PyObject, just return o
        return R(Some(T(o)))
    end

    # TRAVERSE THE MRO
    mro = _unsafe_pytype_getmro(_unsafe_pytype(o))
    len = ccall((:PyTuple_Size, PYLIB), CPy_ssize_t, (PyPtr,), mro)
    for i in 1:len
        base = PyBorrowedRef(ccall((:PyTuple_GetItem, PYLIB), PyPtr, (PyPtr, CPy_ssize_t), mro, i-1))
        name = Symbol(_unsafe_pytype_getname(base))
        r = unsafe_pyconvert_rule(T, Val(name), o) :: _R
        (r.iserr || !r.isnothing) && return r
    end

    # MORE SPECIAL CASES
    # TODO: is it possible to detect which abstract base classes a type is registered with?
    if (typeintersect(T, AbstractVector) !== Union{}) && @safe unsafe_pyisinstance(o, @safe unsafe_pysequenceabc())
        r = unsafe_pyconvert_rule(T, Val(Symbol("collections.abc.Sequence")), o) :: _R
        (r.iserr || !r.isnothing) && return r
    end
    if (typeintersect(T, AbstractDict) !== Union{}) && @safe unsafe_pyisinstance(o, @safe unsafe_pymappingabc())
        r = unsafe_pyconvert_rule(T, Val(Symbol("collections.abc.Mapping")), o) :: _R
        (r.iserr || !r.isnothing) && return r
    end
    if (typeintersect(T, AbstractSet) !== Union{}) && @safe unsafe_pyisinstance(o, @safe unsafe_pysetabc())
        r = unsafe_pyconvert_rule(T, Val(Symbol("collections.abc.Set")), o) :: _R
        (r.iserr || !r.isnothing) && return r
    end
    if T === Any
        return R(Some(o))
    end

    # NOTHING WORKED
    return R(nothing)

    @label error
    return R()
end

tryconvtoconv(o::AbstractPyRef, r::VNE{T}) where {T} =
    nothingtoerror(r) do
        pyerror_set_TypeError("cannot convert $(_unsafe_pytype_getname(_unsafe_pytype(o))) to julia.$T")
    end

unsafe_pyconvert(::Type{T}, o::AbstractPyRef) where {T} =
    tryconvtoconv(o, unsafe_pytryconvert(T, o))
pytryconvert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pytryconvert(T, o))
pyconvert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pyconvert(T, o))
export pytryconvert, pyconvert

unsafe_pyconvertkey(o, ko::AbstractPyRef) =
    tryconvtoconv(ko, unsafe_pytryconvertkey(o, ko))
unsafe_pyconvertvalue(o, k, vo::AbstractPyRef) =
    tryconvtoconv(vo, unsafe_pyconvertvalue(o, k, vo))
unsafe_pyconvertvalue(o, vo::AbstractPyRef) =
    tryconvtoconv(vo, unsafe_pytryconvertvalue(o, vo))
unsafe_pyconvertarrayindices(axes, ko::AbstractPyRef) =
    tryconvtoconv(ko, unsafe_pytryconvertarrayindices(axes, ko))

@generated unsafe_pytryconvertkey(o, ko::AbstractPyRef) =
    try
        :(unsafe_pytryconvert($(keytype(o)), ko))
    catch
        :(unsafe_pytryconvert(Any, ko))
    end

unsafe_pytryconvertkey(o::NamedTuple, ko::AbstractPyRef) =
    unsafe_pytryconvert(Union{Int,Symbol}, ko)

unsafe_pytryconvertvalue(o, k, vo::AbstractPyRef) =
    unsafe_pytryconvertvalue(o, vo)

@generated unsafe_pytryconvertvalue(o, vo::AbstractPyRef) =
    try
        :(unsafe_pytryconvert($(eltype(o)), vo))
    catch
        :(unsafe_pytryconvert(Any, vo))
    end

const PyArrayIndex = Union{Int, StepRange{Int,Int}}

function unsafe_pytryconvertarrayindices(array::AbstractArray{T,N}, vo::AbstractPyRef) where {T,N}
    R = VNE{NTuple{N, PyArrayIndex}}
    if pyistuple(vo)
        if unsafe_pytuple_size(vo) == N
            rs = PyArrayIndex[]
            for i in 1:N
                r = unsafe_pytryconvertarrayindex(axes(array, i), _unsafe_pytuple_getitem(vo, i-1))
                if r.iserr
                    return R()
                elseif r.isnothing
                    return R(nothing)
                else
                    push!(rs, r.value)
                end
            end
            return R(Some(NTuple{N,PyArrayIndex}(rs)))
        else
            pyerror_set_TypeError("expecting $N indices")
        end
    elseif N == 1
        r = unsafe_pytryconvertarrayindex(axes(array, 1), vo)
        if r.iserr
            return R()
        elseif r.isnothing
            return R(nothing)
        else
            return R(Some((r.value,)))
        end
    else
        pyerror_set_TypeError("expecting $N indices")
    end
    return R()
end

function unsafe_pytryconvertarrayindex(axis::AbstractUnitRange{<:Integer}, vo::AbstractPyRef)
    R = VNE{PyArrayIndex}
    # integer
    ri = unsafe_pytryconvert(Int, vo)
    if ri.iserr
        return R()
    elseif !ri.isnothing
        if ri.value < 0
            return R(Some(ri.value + 1 + last(axis)))
        else
            return R(Some(ri.value + first(axis)))
        end
    end
    # slice
    if pyisslice(vo)
        # extract the fields
        ao = _unsafe_pyslice_start(vo)
        a = unsafe_pytryconvert(Union{Int,Nothing}, ao)
        a.iserr && return R()
        a.isnothing && return R(nothing)
        ai = a.value
        bo = _unsafe_pyslice_stop(vo)
        b = unsafe_pytryconvert(Union{Int,Nothing}, bo)
        b.iserr && return R()
        b.isnothing && return R(nothing)
        bi = b.value
        co = _unsafe_pyslice_step(vo)
        c = unsafe_pytryconvert(Union{Int,Nothing}, co)
        c.iserr && return R()
        c.isnothing && return R(nothing)
        ci = c.value
        # make a range
        if ci === nothing
            ci = 1
        elseif iszero(ci)
            pyerror_set_ValueError("slice step cannot be zero")
            return R()
        end
        if ai === nothing
            ai = ci > 0 ? first(axis) : last(axis)
        elseif ai < 0
            ai = ai + 1 + last(axis)
        else
            ai = ai + first(axis)
        end
        if bi === nothing
            bi = ci > 0 ? last(axis) : fist(axis)
        elseif bi < 0
            bi = bi + 1 + last(axis) - sign(ci)
        else
            bi = bi + first(axis) - sign(ci)
        end
        return R(Some(ai:ci:bi))
    end
    return R(nothing)
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

_getproperty(o::PyObject, ::Val{a}) where {a} =
    pygetattr(o, a)

_getproperty(o::PyObject, ::Val{Symbol("jl!b")}) = pytruth(o)
_getproperty(o::PyObject, ::Val{Symbol("jl!s")}) = pystr(String, o)
_getproperty(o::PyObject, ::Val{Symbol("jl!r")}) = pyrepr(String, o)
_getproperty(o::PyObject, ::Val{Symbol("jl!i")}) = pyint_convert(Int, o)
_getproperty(o::PyObject, ::Val{Symbol("jl!u")}) = pyint_convert(UInt, o)
_getproperty(o::PyObject, ::Val{Symbol("jl!f")}) = pyfloat_convert(Float64, o)
_getproperty(o::PyObject, ::Val{Symbol("jl!list")}) = (args...)->PyList{args...}(o)
_getproperty(o::PyObject, ::Val{Symbol("jl!dict")}) = (args...)->PyDict{args...}(o)
_getproperty(o::PyObject, ::Val{Symbol("jl!array")}) = (args...; opts...)->PyArray{args...}(o; opts...)
_getproperty(o::PyObject, ::Val{Symbol("jl!buffer")}) = (args...)->PyBuffer(o, args...)

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
    r = [Symbol(pystr(String, x)) for x in words]
    return r
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

Base.eltype(::Type{PyObject}) = PyObject
Base.keytype(::Type{PyObject}) = PyObject
Base.valtype(::Type{PyObject}) = PyObject

Base.in(x, o::PyObject) = pycontains(o, x)

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
