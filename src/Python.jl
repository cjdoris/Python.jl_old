module Python

using UnsafePointers, Conda, Libdl, Dates, MacroTools

include("utils.jl")
include("init.jl")
include("consts.jl")
include("refs.jl")
# fundamental objects
include("object.jl")
include("type.jl")
include("error.jl")
include("none.jl")
# utilities
include("import.jl")
# abstract interfaces
include("iter.jl")
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
# extras
include("pymacro.jl")

end # module
