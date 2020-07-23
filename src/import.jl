unsafe_pyimport(o::AbstractString) =
    @cpycall :PyImport_ImportModule(o::Cstring)::CPyNewPtr
unsafe_pyimport(o::Symbol) =
    unsafe_pyimport(string(o))
unsafe_pyimport(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyImport_Import(o::CPyPtr)::CPyNewPtr
unsafe_pyimport(o) =
    unsafe_pyimport(unsafe_pyobj(o))
pyimport(args...; kwargs...) =
    safe(unsafe_pyimport(args...; kwargs...))
export pyimport
