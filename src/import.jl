unsafe_pyimport(o::Symbol) =
    unsafe_pyimport(string(o))

function unsafe_pyimportattr(mname, k)
    m = unsafe_pyimport(mname)
    isnull(m) && return PYNULL
    unsafe_pygetattr(m, k)
end
function unsafe_pyimportattr(path::AbstractString)
    i0 = firstindex(path)
    i = findlast('.', path)
    i1 = prevind(path, i)
    i2 = nextind(path, i)
    i3 = lastindex(path)
    unsafe_pyimportattr(SubString(path, i0, i1), SubString(path, i2, i3))
end
pyimportattr(args...; kwargs...) = safe(unsafe_pyimportattr(args...; kwargs...))
return pyimportattr
