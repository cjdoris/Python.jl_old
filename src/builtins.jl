const _pybuiltinsmodule = pynull()
unsafe_pybuiltinsmodule() = unsafe_cacheget!(_pybuiltinsmodule) do
    unsafe_pyimport("builtins")
end
pybuiltinsmodule() = safe(unsafe_pybuiltinsmodule())
export pybuiltinsmodule

const _pyrangetype = pynull()
unsafe_pyrangetype() = unsafe_cacheget!(_pyrangetype) do
    unsafe_pygetattr(unsafe_pybuiltinsmodule(), "range")
end
pyrangetype() = safe(unsafe_pyrangetype())
export pyrangetype

unsafe_pyrange(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pyrangetype(), args, kwargs)
unsafe_pyrange(x::AbstractRange{<:Integer}) =
    unsafe_pyrange(first(x), last(x)+sign(step(x)), step(x))
pyrange(args...; kwargs...) =
    safe(unsafe_pyrange(args...; kwargs...))
export pyrange
