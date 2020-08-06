unsafe_pyrawio(io::IO) = unsafe_pyjulia(AsPyRawIO(io))
"""
    pyrawio(io::IO)

Wrap `io` into a Python raw bytes IO object.

See also [`pybufferedio`](@ref).
"""
pyrawio(io) = safe(unsafe_pyrawio(io))
export pyrawio

unsafe_pybufferedio(io::IO) = unsafe_pyjulia(AsPyBufferedIO(io))
"""
    pybufferedio(io::IO)

Wrap `io` into a Python buffered bytes IO object.

This is the default conversion to Python for `IO` objects. If you want text IO, use [`pytextio`](@ref).
"""
pybufferedio(io) = safe(unsafe_pybufferedio(io))
export pybufferedio

function unsafe_pytextio(io::IO, args...; encoding="utf8", kwargs...)
    r = unsafe_pybufferedio(io)
    isnull(r) && return PYNULL
    unsafe_pytextiowrapper(r, args...; encoding=encoding, kwargs...)
end
"""
    pytextio(io::IO; ...)

Wrap `io` into a Python text IO object.

The keyword options are as for `io.TextIOWrapper`. The encoding defaults to "utf8" for consistency with Julia, pass `encoding=nothing` to use the Python default encoding.
"""
pytextio(args...; kwargs...) = safe(unsafe_pytextio(args...; kwargs...))
export pytextio
