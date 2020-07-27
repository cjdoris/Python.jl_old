"""
    PyArray(..., o)

A Julia array wrapping the Python object `o` satisfying the `numpy` array interface.
"""
struct PyArray{T,N} <: AbstractArray{T,N}
    parent :: ConcretePyObject
    ptr :: Ptr{T}
    mutable :: Bool
    size :: NTuple{N, Int}
    length :: Int
    byte_strides :: NTuple{N, Int}
    el_strides :: NTuple{N, Int}
end
export PyArray

# CONSTRUCTORS

function PyArray(::Type{T}, ::Val{N}, o::PyObject, info::NamedTuple=pyarray_get_info(o)) where {T,N}
    Base.allocatedinline(T) || error("T must be allocated inline")
    ptr = info.ptr
    mutable = info.mutable
    sizeof(T) == info.elsize || error("element size is incorrect (expected $(sizeof(T)), got $(info.elsize))")
    length(info.size) == N || error("size is incorrect length (expected $N, got $(length(info.size)))")
    _size = NTuple{N,Int}(info.size)
    _length = prod(_size)
    length(info.strides) == N || error("strides is incorrect length (expected $N, got $(length(info.strides)))")
    byte_strides = NTuple{N,Int}(info.strides)
    el_strides = map(byte_strides) do s
        q, r = fldmod(s, sizeof(T))
        r == 0 || error("strides must be a multiple of the element size")
        q
    end
    PyArray{T,N}(o, ptr, mutable, _size, _length, byte_strides, el_strides)
end

PyArray(::Type{T}, o::PyObject, info::NamedTuple=pyarray_get_info(o)) where {T} =
    PyArray(T, Val(length(info.size)), o, info)

PyArray(::Val{N}, o::PyObject, info::NamedTuple=pyarray_get_info(o)) where {N} =
    PyArray(info.eltype, Val(N), o, info)

PyArray(o::PyObject, info::NamedTuple=pyarray_get_info(o)) =
    PyArray(info.eltype, Val(length(info.size)), o, info)

function pyarray_get_info(o::PyObject)
    if pyhasattr(o, "__array_interface__")
        return pyarray_get_info(Val(:array_interface), o)
    elseif pyhasattr(o, "__array_struct__")
        return pyarray_get_info(Val(:array_struct), o)
    else
        error("does not look like an array")
    end
end

islittleendian() =
    Base.ENDIAN_BOM == 0x04030201 ? true  :
    Base.ENDIAN_BOM == 0x01020304 ? false :
    error("cannot determine endianness")

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
            if elsize == sizeof(Ptr{CPyObject})
                eltype = Ptr{CPyObject}
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
    (ptr=ptr, mutable=mutable, elsize=elsize, eltype=eltype, size=size, strides=strides)
end

# ARRAY INTERFACE

Base.isimmutable(o::PyArray) = !o.mutable
Base.size(o::PyArray) = o.size
Base.length(o::PyArray) = o.length
Base.strides(o::PyArray) = o.el_strides
Base.unsafe_convert(::Type{Ptr{T}}, o::PyArray{T}) where {T} = o.ptr
Base.@propagate_inbounds function Base.getindex(o::PyArray{T,N}, idx::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(o, idx...)
    offset = N==0 ? 0 : sum(map((i,s)->(i-1)*s, idx, o.byte_strides))
    unsafe_load(o.ptr + offset)
end
Base.@propagate_inbounds function Base.setindex!(o::PyArray{T,N}, v, idx::Vararg{Int,N}) where {T,N}
    @boundscheck o.mutable || error("immutable")
    @boundscheck checkbounds(o, idx...)
    offset = N==0 ? 0 : sum(map((i,s)->(i-1)*s, idx, o.byte_strides))
    unsafe_store!(o.ptr + offset, v)
    o
end
