function unsafe_pyabc_register(abc::AbstractPyRef, t::AbstractPyRef)
    R = ValueOrError{Nothing}
    r = unsafe_pygetattr(abc, "register")
    isnull(r) && return R()
    r = unsafe_pycall(r, t)
    isnull(r) && return R()
    R(nothing)
end

function unsafe_pyabc_register(_abc::AbstractString, t::AbstractPyRef)
    abc = unsafe_pyimportattr(_abc)
    isnull(abc) && return ValueOrError{Nothing}()
    unsafe_pyabc_register(abc, t)
end
