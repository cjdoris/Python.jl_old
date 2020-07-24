function unsafe_pybuiltin(x)
    b = unsafe_pybuiltinsmodule()
    iserr(b) && return PYNULL
    unsafe_pygetattr(b, x)
end
pybuiltin(x) = safe(unsafe_pybuiltin(x))
export pybuiltin

unsafe_pyrange(x::AbstractRange{<:Integer}) =
    unsafe_pyrange(first(x), last(x)+sign(step(x)), step(x))
