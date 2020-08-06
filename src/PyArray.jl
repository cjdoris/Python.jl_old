"""
    PyArray{T,N,L}(o) :: AbstractArray{T,N}

A Julia array wrapping the Python object `o` satisfying the buffer protocol or `numpy` array interface.

Type parameters not specified or set to `missing` are inferred at run-time.

The parameter `L` controls indexing:
* If `L == false` then cartesian indexing is used
* If `L == true` then linear indexing is used
* If `L isa Int` then linear indexing is used with stride `L`

Note that numpy arrays are commonly C-contigous, whereas Julia requires Fortran-contiguous arrays for linear indexing. You may with to transpose the array first.
"""
struct PyArray{T,N,L} <: AbstractArray{T,N}
    parent :: PyObject # the object being wrapped
    handle :: Any      # an object required to keep the underlying memory valid
    ptr :: Ptr{T}      # pointer to the memory
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

function PyArray{T,N,L}(o::PyObject, info::NamedTuple) where {T,N,L}
    # element type
    if T === missing
        return PyArray{info.eltype, N, L}(o, info)
    elseif !isa(T, Type)
        error("T must be `missing` or a type (got $T)")
    end
    Base.allocatedinline(T) || error("T must be allocated inline (got $T)")
    sizeof(T) == info.elsize || error("sizeof(T) is incorrect (expected $(info.elsize), got $(sizeof(T)))")
    # pointer
    ptr = info.ptr
    # mutability
    mutable = info.mutable
    # number of dimensions
    if N===missing
        return PyArray{T, length(info.size), L}(o, info)
    elseif !isa(N, Int)
        error("N must be `missing` or an Int (got $N)")
    end
    length(info.size) == N || error("N is incorrect (expected $(length(info.size)), got $N)")
    # size, length
    _size = NTuple{N,Int}(info.size)
    _length = prod(_size)
    length(info.strides) == N || error("strides is incorrect length (expected N=$N, got $(length(info.strides)))")
    byte_strides = NTuple{N,Int}(info.strides)
    el_strides = map(byte_strides) do s
        q, r = fldmod(s, sizeof(T))
        r == 0 || error("byte strides must be a multiple of the element size (got $(byte_strides))")
        q
    end
    # indexing
    if L === missing || L === true || L isa Int
        if N ≤ 1 || byte_strides == make_f_contig_strides(byte_strides[1], _size...)
            if L === missing
                return PyArray{T, N, N==0 ? 0 : byte_strides[1]}(o, info)
            elseif L isa Int
                N==0 || L==byte_strides[1] || error("L is incorrect (expected bool or $(byte_strides[1]), got $L)")
            end
        elseif L === missing
            return PyArray{T, N, false}(o, info)
        else
            error("L is incorrect (expected false because array is not contiguous, got $L)")
        end
    elseif L !== false
        error("L must be `missing`, boolean or an Int (got $L)")
    end
    # done
    PyArray{T,N,L}(o, info.handle, ptr, mutable, _size, _length, byte_strides, el_strides)
end

PyArray{T,N,L}(o::PyObject; opts...) where {T,N,L} = PyArray{T,N,L}(o, pyarray_get_info(o; opts...))
PyArray{T,N,L}(o; opts...) where {T,N,L} = PyArray{T,N,L}(PyObject(o); opts...)
PyArray{T,N}(o; opts...) where {T,N} = PyArray{T,N,missing}(PyObject(o); opts...)
PyArray{T}(o; opts...) where {T} = PyArray{T,missing,missing}(PyObject(o); opts...)
PyArray(o; opts...) = PyArray{missing,missing,missing}(PyObject(o); opts...)

# CONSTRUCT FROM array.array

for T in (Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Float32, Float64)
    for (T2,c) in ((Cchar, "b"), (Cuchar, "B"), (Cshort, "h"), (Cushort, "H"), (Cint, "i"), (Cuint, "I"), (Clong, "l"), (Culong, "L"), (Clonglong, "q"), (Culonglong, "Q"), (Cfloat, "f"), (Cdouble, "d"))
        if T === T2
            @eval PyVector{$T}(undef, d::Integer) = PyVector{$T,$(sizeof(T))}(pyimportattr("array","array")($c, pybytearray(d * $(sizeof(T)))))
            break
        end
    end
end

# PROTOCOL-SPECIFIC INFORMATION

function pyarray_get_info(o::PyObject; kind::Symbol=:any)
    if kind in (:any, :array, :array_interface) && pyhasattr(o, "__array_interface__")
        return pyarray_get_info(Val(:array_interface), o)
    elseif kind in (:any, :array, :array_struct) && pyhasattr(o, "__array_struct__")
        return pyarray_get_info(Val(:array_struct), o)
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
    @assert length(typestr) ≥ 3
    endchar = typestr[1]
    typechar = typestr[2]
    elsize = parse(Int, typestr[3:end])
    eltype = NTuple{elsize, UInt8}
    if endchar == '|' || endchar == (islittleendian() ? '<' : '>')
        if typechar == 't'
            error("bit fields not supported")
        elseif typechar == 'b'
            if elsize == sizeof(Bool)
                eltype = Bool
            end
        elseif typechar == 'O'
            if elsize == sizeof(PyPtr)
                eltype = PyPtr
            end
        elseif typechar == 'f'
            if elsize == 8
                eltype = Float64
            elseif elsize == 4
                eltype = Float32
            elseif elsize == 2
                eltype == Float16
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
        elseif typechar == 'c'
            if elsize == 16
                eltype = Complex{Float64}
            elseif elsize == 8
                eltype = Complex{Float32}
            elseif elsize == 4
                eltype = Complex{Float16}
            end
        end
    end
    @assert sizeof(eltype) == elsize

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
    (handle=a, ptr=ptr, mutable=mutable, elsize=elsize, eltype=eltype, size=size, strides=strides)
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

Base.unsafe_convert(::Type{Ptr{T}}, o::PyArray{T}) where {T} = o.ptr

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
    unsafe_load(o.ptr + offset)
end

Base.@propagate_inbounds function Base.getindex(o::PyArray, i::Int)
    @boundscheck checkbounds(o, i)
    offset = _idx_to_offset(o, i)
    unsafe_load(o.ptr + offset)
end

Base.@propagate_inbounds function Base.setindex!(o::PyArray{T,N}, v, idx::Vararg{Int,N}) where {T,N}
    @boundscheck o.mutable || error("immutable")
    @boundscheck checkbounds(o, idx...)
    offset = _idx_to_offset(o, idx...)
    unsafe_store!(o.ptr + offset, v)
    o
end

Base.@propagate_inbounds function Base.setindex!(o::PyArray, v, i::Int)
    @boundscheck o.mutable || error("immutable")
    @boundscheck checkbounds(o, i)
    offset = _idx_to_offset(o, i)
    unsafe_store!(o.ptr + offset, v)
    o
end
