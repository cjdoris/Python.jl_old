module Python

using UnsafePointers, Conda, Libdl, Dates, MacroTools, Pkg

include("utils.jl")
include("init.jl")
include("consts.jl")
include("refs.jl")
# fundamental objects
include("fundamental.jl")
include("generate.jl")
include("object.jl")
include("type.jl")
include("error.jl")
include("none.jl")
# utilities
include("import.jl")
# abstract interfaces
include("iter.jl")
include("number.jl")
# numeric objects
include("bool.jl")
include("int.jl")
include("float.jl")
include("complex.jl")
# sequential objects
include("str.jl")
include("bytes.jl")
include("bytearray.jl")
include("tuple.jl")
include("structseq.jl")
include("list.jl")
# container objects
include("dict.jl")
include("set.jl")
# other objects
include("slice.jl")
# modules
include("builtins.jl")
include("datetime.jl")
include("fractions.jl")
# wrapper types providing Julia semantics
include("converters.jl")
include("PyDict.jl")
include("PyList.jl")
include("PyBuffer.jl")
include("PyArray.jl")
# extras
include("pymacro.jl")

end # module
