abstract type AbstractPyConverter{T} end

AbstractPyConverter(c::AbstractPyConverter) = c
AbstractPyConverter(::Type{PyObject}) = IdPyConverter()
AbstractPyConverter(::Type{ConcretePyObject}) = IdPyConverter()
AbstractPyConverter(::Type{Symbol}) = SymbolPyConverter()
AbstractPyConverter(::Type{T}) where {T<:Integer} = IntPyConverter{T}()
AbstractPyConverter(::Type{T}) where {T<:AbstractString} = StrPyConverter{T}()
AbstractPyConverter(::Type{T}) where {T<:AbstractFloat} = FloatPyConverter{T}()
AbstractPyConverter(::Type{T}) where {T<:Rational} = FractionPyConverter{T}()

PyObject(c::AbstractPyConverter{T}, o::T) where {T} = error("not implemented")
PyObject(c::AbstractPyConverter{T}, o) where {T} = PyObject(c, convert(T, o))

struct IdPyConverter <: AbstractPyConverter{ConcretePyObject} end
PyObject(::IdPyConverter, o::ConcretePyObject) = o
pyconvert(::IdPyConverter, o::PyObject) = convert(ConcretePyObject, o)

struct SymbolPyConverter <: AbstractPyConverter{Symbol} end
PyObject(::SymbolPyConverter, o::Symbol) = pystr(o)
pyconvert(::SymbolPyConverter, o::PyObject) = Symbol(pystr(String, o))

struct IntPyConverter{T<:Integer} <: AbstractPyConverter{T} end
PyObject(::IntPyConverter{T}, o::T) where {T} = pyint(o)
pyconvert(::IntPyConverter{T}, o::PyObject) where {T} = pyint_convert(T, o)

struct StrPyConverter{T<:AbstractString} <: AbstractPyConverter{T} end
PyObject(::StrPyConverter{T}, o::T) where {T} = pystr(o)
pyconvert(::StrPyConverter{T}, o::PyObject) where {T} = pystr(T, o)

struct FloatPyConverter{T<:Real} <: AbstractPyConverter{T} end
PyObject(::FloatPyConverter{T}, o::T) where {T} = pyfloat(o)
pyconvert(::FloatPyConverter{T}, o::PyObject) where {T} = pyfloat_convert(T, o)

struct FractionPyConverter{T<:Rational} <: AbstractPyConverter{T} end
PyObject(::FractionPyConverter{T}, o::T) where {T} = pyfraction(pyint(numerator(o)), pyint(denominator(o)))
pyconvert(::FractionPyConverter{Rational{T}}, o::PyObject) where {T} = pyint_convert(T, o.numerator) // pyint_convert(T, o.denominator)
