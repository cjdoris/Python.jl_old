"""
    PyArray{T,N,L,R}(o) :: AbstractArray{T,N}

A Julia array wrapping the Python array object `o`.

`o` may be a `bytes`, `bytearray`, `array.array`, `numpy.ndarray`, `pandas.DataFrame` or anything satisfying the buffer protocol, numpy array interface or with an `__array__` method.

# Extended help

Normally this array references the original data, so modifications to this array are reflected in `o`. The exception is if the `__array__` method returns a copy of the data, e.g. if `o` is a heterogeneous dataframe.

Type parameters not specified or set to `missing` are inferred at run-time.

The parameter `L` controls indexing:
* If `L == false` then cartesian indexing is used
* If `L == true` then linear indexing is used
* If `L isa Int` then linear indexing is used with stride `L`

The parameter `R` is the "raw" data type held by `o`. For bits types this is the same as the user-facing `T`, but for example we allow `T=PyObject` and `R=PyBorrowedRef` so that arrays holding python objects can be viewed as such from Julia. The functions [`pyarray_T_from_R`](@ref), [`pyarray_R_from_T`](@ref), [`pyarray_unsafe_load`](@ref) and [`pyarray_unsafe_store!`](@ref) control the mapping between raw- and user-values.

Note that numpy arrays are commonly C-contigous, whereas Julia requires Fortran-contiguous arrays for linear indexing. You may with to transpose the array first.
"""
struct PyArray{T,N,L,R} <: AbstractArray{T,N}
    parent :: PyObject # the object being wrapped
    handle :: Any      # an object required to keep the underlying memory valid
    ptr :: Ptr{R}      # pointer to the memory
    mutable :: Bool    # TODO: make this a type parameter?
    size :: NTuple{N, Int}
    length :: Int
    byte_strides :: NTuple{N, Int}
    el_strides :: NTuple{N, Int}
end

"""
    PyVector{T}(undef, d)

A `PyArray{T,1}` of length `d` backed by a Python `array.array`.
"""
const PyVector{T} = PyArray{T,1}
const PyMatrix{T} = PyArray{T,2}

export PyArray, PyVector, PyMatrix

unsafe_pyobj(o::PyArray) = o.parent

# CONSTRUCTORS

pyarray_T_from_R(::Type{R}) where {R} = R
pyarray_T_from_R(::Type{R}) where {R<:PyBorrowedRef{CPyObject}} = PyObject

pyarray_R_from_T(::Type{T}) where {T} = T
pyarray_R_from_T(::Type{PyObject}) = PyBorrowedRef{CPyObject}

"""
    pyarray_unsafe_load(::Type{T}, p::Ptr{R})

Load the element of type `T` from the pointer `p` to a raw element of a `PyArray{T,-,-,R}`.
"""
pyarray_unsafe_load(::Type{T}, p::Ptr{T}) where {T} = unsafe_load(p)
pyarray_unsafe_load(::Type{T}, p::Ptr{<:PyBorrowedRef}) where {T<:AbstractPyObject} = T(unsafe_load(p))

"""
    pyarray_unsafe_store!(p::Ptr{R}, x::T)

Store the element `x` into the pointer `p` to a raw element of a `PyArray{T,-,-,R}`.
"""
pyarray_unsafe_store!(p::Ptr{T}, x::T) where {T} = unsafe_store!(p, x)
function pyarray_unsafe_store!(p::Ptr{R}, x::AbstractPyObject) where {R<:PyBorrowedRef}
    r = PyRef(x)
    r0 = R(ptr(r))
    Base.GC.@preserve r begin
        decref!(unsafe_load(p))
        incref!(r0)
        unsafe_store!(p, r0)
    end
end

function PyArray{T,N,L,R}(o::PyObject, info::NamedTuple) where {T,N,L,R}

    # check arguments
    T isa Union{Missing, Type} || error("T must be a `Missing` or `Type` (got $T)")
    R isa Union{Missing, Type} || error("R must be a `Missing` or `Type` (got $R)")
    N isa Union{Missing, Int}  || error("N must be a `Missing` or `Int` (got $N)")
    L isa Union{Missing, Bool, Int} || error("L must be a `Missing` or `Bool` or `Int` (got $L)")

    # element type
    T === missing && R === missing && return PyArray{T, N, L, info.eltype}(o, info)
    T === missing && return PyArray{pyarray_T_from_R(R), N, L, R}(o, info)
    R === missing && return PyArray{T, N, L, pyarray_R_from_T(T)}(o, info)
    @assert T isa Type
    @assert R isa Type
    Base.allocatedinline(R) || error("R must be allocated inline (got $R)")
    sizeof(R) == info.elsize || error("sizeof(R) is incorrect (expected $(info.elsize), got $(sizeof(R)))")

    # pointer
    ptr = info.ptr

    # mutability
    mutable = info.mutable

    # number of dimensions
    N === missing && return PyArray{T, length(info.size), L, R}(o, info)
    @assert N isa Int
    length(info.size) == N || error("N is incorrect (expected $(length(info.size)), got $N)")

    # size, length
    _size = NTuple{N,Int}(info.size)
    _length = prod(_size)
    length(info.strides) == N || error("strides is incorrect length (expected N=$N, got $(length(info.strides)))")
    byte_strides = NTuple{N,Int}(info.strides)
    el_strides = map(byte_strides) do s
        q, r = fldmod(s, sizeof(R))
        r == 0 || error("byte strides must be a multiple of the element size (got $(byte_strides))")
        q
    end

    # indexing
    if L === missing || L === true || L isa Int
        if N ≤ 1 || byte_strides == make_f_contig_strides(byte_strides[1], _size...)
            if L === missing
                return PyArray{T, N, N==0 ? 0 : byte_strides[1], R}(o, info)
            elseif L isa Int
                N==0 || L==byte_strides[1] || error("L is incorrect (expected bool or $(byte_strides[1]), got $L)")
            end
        elseif L === missing
            return PyArray{T, N, false, R}(o, info)
        else
            error("L is incorrect (expected false because array is not contiguous, got $L)")
        end
    else
        @assert L === false
    end
    # done
    PyArray{T, N, L, R}(o, info.handle, ptr, mutable, _size, _length, byte_strides, el_strides)
end

PyArray{T,N,L,R}(o::PyObject; opts...) where {T,N,L,R} = PyArray{T,N,L,R}(o, pyarray_get_info(o; opts...))
PyArray{T,N,L,R}(o; opts...) where {T,N,L,R} = PyArray{T,N,L,R}(PyObject(o); opts...)
PyArray{T,N,L}(o; opts...) where {T,N,L} = PyArray{T,N,L,missing}(PyObject(o); opts...)
PyArray{T,N}(o; opts...) where {T,N} = PyArray{T,N,missing,missing}(PyObject(o); opts...)
PyArray{T}(o; opts...) where {T} = PyArray{T,missing,missing,missing}(PyObject(o); opts...)
PyArray(o; opts...) = PyArray{missing, missing, missing, missing}(PyObject(o); opts...)

# CONSTRUCT FROM array.array

for T in (Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Float32, Float64)
    for (T2,c) in ((Cchar, "b"), (Cuchar, "B"), (Cshort, "h"), (Cushort, "H"), (Cint, "i"), (Cuint, "I"), (Clong, "l"), (Culong, "L"), (Clonglong, "q"), (Culonglong, "Q"), (Cfloat, "f"), (Cdouble, "d"))
        if T === T2
            @eval PyVector{$T}(undef, d::Integer) = PyVector{$T,$(sizeof(T)),$T}(pyimportattr("array","array")($c, pybytearray(d * $(sizeof(T)))))
            break
        end
    end
end

# PROTOCOL-SPECIFIC INFORMATION

function pyarray_get_info(o::PyObject; kind::Symbol=:any, recurse::Bool=true)
    if kind in (:any, :array, :array_interface) && pyhasattr(o, "__array_interface__")
        return pyarray_get_info(Val(:array_interface), o)
    elseif kind in (:any, :array, :array_struct) && pyhasattr(o, "__array_struct__")
        return pyarray_get_info(Val(:array_struct), o)
    elseif recurse && kind in (:any, :array, :array_interface, :array_struct) && pyhasattr(o, "__array__")
        return pyarray_get_info(o.__array__(), kind=kind, recurse=recurse)
    elseif kind in (:any, :buffer) && _unsafe_pyisbuffer(o)
        return pyarray_get_info(Val(:buffer), o)
    else
        error("Python `$(_unsafe_pytype_getname(_unsafe_pytype(o)))` does not support array interface$(kind==:any ? "" : " of kind `$(repr(kind))`")")
    end
end

function pyarray_get_info(::Val{:array_interface}, o::PyObject)
    a = o.__array_interface__

    # version
    ver = pyint_convert(Int, a["version"])
    ver == 3 || error("currently only numpy array interface version 3 is supported")

    # size (shape)
    size = [pyint_convert(Int, x) for x in a["shape"]]
    ndim = length(size)

    # eltype (ignoring descr for now)
    typestr = pystr(String, a["typestr"])
    @assert length(typestr) ≥ 2
    endchar = typestr[1]
    typechar = typestr[2]
    elsize = tryparse(Int, typestr[3:end])
    eltype = nothing
    if typechar == 't'
        error("bit fields not supported")
    elseif typechar == 'b'
        if elsize == sizeof(Bool)
            eltype = Bool
        end
    elseif typechar == 'i'
        if elsize == 8
            eltype = Int64
        elseif elsize == 4
            eltype = Int32
        elseif elsize == 2
            eltype = Int16
        elseif elsize == 1
            eltype = Int8
        end
    elseif typechar == 'u'
        if elsize == 8
            eltype = UInt64
        elseif elsize == 4
            eltype = UInt32
        elseif elsize == 2
            eltype = UInt16
        elseif elsize == 1
            eltype = UInt8
        end
    elseif typechar == 'f'
        if elsize == 8
            eltype = Float64
        elseif elsize == 4
            eltype = Float32
        elseif elsize == 2
            eltype == Float16
        end
    elseif typechar == 'c'
        if elsize == 16
            eltype = Complex{Float64}
        elseif elsize == 8
            eltype = Complex{Float32}
        elseif elsize == 4
            eltype = Complex{Float16}
        end
    elseif typechar in ('m', 'M')
        if (m = match(r"^([0-9]+)\[([a-zA-Z]+)\]$", typestr[3:end])) !== nothing
            elsize = parse(Int, m.captures[1])
            unit = Symbol(m.captures[2])
            if elsize == 8
                eltype = typechar == 'm' ? NumpyTimedelta64{unit} : NumpyDatetime64{unit}
            end
        end
    elseif typechar == 'O'
        @assert elsize === nothing
        elsize = sizeof(PyBorrowedRef{CPyObject})
        eltype = PyBorrowedRef{CPyObject}
    elseif typechar == 'S'
        eltype = NTuple{elsize, Cchar}
    elseif typechar == 'U'
        error("unicode strings not supported")
    elseif typechar == 'V'
        eltype = NTuple{elsize, UInt8}
    end
    if eltype === nothing
        if elsize === nothing
            error("typestr=$(repr(typestr)) not supported")
        else
            eltype = NTuple{elsize, UInt8}
        end
    end
    @assert elsize isa Int
    @assert eltype isa Type
    @assert sizeof(eltype) == elsize
    if elsize > 1 && endchar == (islittleendian() ? '>' : '<') && eltype <: Union{Number, NumpyDatetime64}
        eltype = ByteReversed(eltype)
    end

    # data
    _data = a.get("data", pynone())
    offset = pyint_convert(Int, a.get("offset", 0))
    if pyisinstance(_data, pytupletype())
        @assert offset == 0
        @assert pylen(_data) == 2
        ptr = Ptr{Cvoid}(pyint_convert(UInt, _data[0]))
        mutable = pynot(_data[1])
    else
        buf = pyisnone(_data) ? o : _data
        error("buffer protocol data not supported yet")
    end

    # strides
    _strides = a.get("strides", pynone())
    if pyisnone(_strides)
        strides = Int[]
        for i in 1:ndim
            s = i==1 ? elsize : strides[1]*size[end-(i-2)]
            insert!(strides, 1, s)
        end
    else
        strides = [pyint_convert(Int, x) for x in _strides]
    end

    # mask
    _mask = a.get("mask", pynone())
    pyisnone(_mask) || error("masked arrays not supported")

    # done
    (handle=(o,a), ptr=ptr, mutable=mutable, elsize=elsize, eltype=eltype, size=size, strides=strides)
end

function pyarray_get_info(::Val{:array_struct}, o::PyObject)
    error("not implemented")
end

function pyarray_get_info(::Val{:buffer}, o::PyObject; flags::Integer=CPyBUF_RECORDS_RO)
    buf = PyBuffer(o, flags)

    # suboffsets
    isnull(buf.view[].suboffsets) || error("buffers with suboffsets not supported")

    (handle=buf, ptr=buf.buf, mutable=!buf.readonly, elsize=buf.itemsize, eltype=buf.itemtype, size=buf.shape, strides=buf.strides)
end

# ARRAY INTERFACE

Base.isimmutable(o::PyArray) = !o.mutable

Base.size(o::PyArray) = o.size

Base.length(o::PyArray) = o.length

Base.strides(o::PyArray) = o.el_strides

Base.unsafe_convert(::Type{Ptr{R}}, o::PyArray{T,N,L,R}) where {T,N,L,R} = o.ptr

Base.IndexStyle(::Type{PyArray{T,N,L}}) where {T,N,L} = L===false ? IndexCartesian() : IndexLinear()

_idx_to_offset(o::PyArray{T,0}        ) where {T} = 0
_idx_to_offset(o::PyArray{T,0}, i::Int) where {T} = 0

_idx_to_offset(o::PyArray{T,1,false}, i::Int) where {T}   = (i-1) * o.byte_strides[1]
_idx_to_offset(o::PyArray{T,1,true},  i::Int) where {T}   = (i-1) * o.byte_strides[1]
_idx_to_offset(o::PyArray{T,1,L},     i::Int) where {T,L} = (i-1) * L

_idx_to_offset(o::PyArray{T,N,L}, idx::Vararg{Int,N}) where {T,N,L} = sum((idx .- 1) .* o.byte_strides)

_idx_to_offset(o::PyArray{T,N,false}, i::Int) where {T,N}   = _idx_to_offset(o, Base._unsafe_ind2sub(o.size, i)...)
_idx_to_offset(o::PyArray{T,N,true},  i::Int) where {T,N}   = (i-1) * o.byte_strides[1]
_idx_to_offset(o::PyArray{T,N,L},     i::Int) where {T,N,L} = (i-1) * L

Base.@propagate_inbounds function Base.getindex(o::PyArray{T,N}, idx::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(o, idx...)
    offset = _idx_to_offset(o, idx...)
    pyarray_unsafe_load(T, o.ptr + offset)
end

Base.@propagate_inbounds function Base.getindex(o::PyArray{T}, i::Int) where {T}
    @boundscheck checkbounds(o, i)
    offset = _idx_to_offset(o, i)
    pyarray_unsafe_load(T, o.ptr + offset)
end

Base.@propagate_inbounds function Base.setindex!(o::PyArray{T,N}, _v, idx::Vararg{Int,N}) where {T,N}
    @boundscheck o.mutable || error("immutable")
    @boundscheck checkbounds(o, idx...)
    v = convert(T, _v)
    offset = _idx_to_offset(o, idx...)
    pyarray_unsafe_store!(o.ptr + offset, v)
    o
end

Base.@propagate_inbounds function Base.setindex!(o::PyArray{T}, _v, i::Int) where {T}
    @boundscheck o.mutable || error("immutable")
    @boundscheck checkbounds(o, i)
    v = convert(T, _v)
    offset = _idx_to_offset(o, i)
    pyarray_unsafe_store!(o.ptr + offset, v)
    o
end
