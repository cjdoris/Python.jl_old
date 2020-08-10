unsafe_pyimport(o::Symbol) =
    unsafe_pyimport(string(o))

function unsafe_pyimportattr(mname, k)
    m = unsafe_pyimport(mname)
    isnull(m) && return PYNULL
    unsafe_pygetattr(m, k)
end

function unsafe_pyimportattrcall(mname, attr, args...; kwargs...)
    f = unsafe_pyimportattr(mname, attr)
    isnull(f) && return PYNULL
    unsafe_pycall(f, args...; kwargs...)
end
