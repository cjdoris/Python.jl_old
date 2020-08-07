unsafe_pylist_new() = unsafe_pylist_new(0)

function unsafe_pylist_fromiter(xs)
    t = unsafe_pylist_new()
    isnull(t) && return PYNULL
    for x in xs
        iserr(unsafe_pylist_append(t, x)) && return PYNULL
    end
    return t
end
pylist_fromiter(xs) =
    safe(unsafe_pylist_fromiter(xs))
export pylist_fromiter

function unsafe_pylist_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    R = VNE{T}
    # fall back to iterator conversion
    it = unsafe_pyiter(o)
    isnull(it) ? R() : convert(R, unsafe_pyiter_tryconvert(T, it))
end
