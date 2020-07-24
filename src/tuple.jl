function unsafe_pytuple_fromiter(xs)
    t = unsafe_pytuple_new(length(xs))
    isnull(t) && return PYNULL
    for (i,x) in enumerate(xs)
        iserr(unsafe_pytuple_setitem(t, i-1, x)) && return PYNULL
    end
    return t
end
pytuple_fromiter(xs) = safe(unsafe_pytuple_fromiter(xs))
export pytuple_fromiter
