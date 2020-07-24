unsafe_pyset() = unsafe_pyset_new(C_NULL)
unsafe_pyfrozenset() = unsafe_pyfrozenset_new(C_NULL)

function unsafe_pyset_fromiter(xs)
    t = unsafe_pyset()
    isnull(t) && return PYNULL
    for x in xs
        iserr(unsafe_pyset_add(t, x)) && return PYNULL
    end
    return t
end
pyset_fromiter(xs) =
    safe(unsafe_pyset_fromiter(xs))
export pyset_fromiter

function unsafe_pyfrozenset_fromiter(xs)
    t = unsafe_pyfrozenset()
    isnull(t) && return PYNULL
    for x in xs
        iserr(unsafe_pyset_add(t, x)) && return PYNULL
    end
    return t
end
pyfrozenset_fromiter(xs) =
    safe(unsafe_pyfrozenset_fromiter(xs))
export pyfrozenset_fromiter
