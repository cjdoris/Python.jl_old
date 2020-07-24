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
