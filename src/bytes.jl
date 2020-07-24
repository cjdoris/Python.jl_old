function unsafe_pybytes_asstringandsize(o)
    R = ValueOrError{Tuple{Ptr{Cchar}, CPy_ssize_t}}
    isnull(o) && return R()
    buf = Ref{Ptr{Cchar}}(C_NULL)
    len = Ref{CPy_ssize_t}(0)
    e = ccall((:PyBytes_AsStringAndSize, PYLIB), Cint, (Ptr{Cvoid}, Ptr{Ptr{Cchar}}, Ptr{CPy_ssize_t}), o, buf, len)
    e == -1 && return R()
    return R((buf[], len[]))
end

function unsafe_pybytes_asjuliastring(o)
    R = ValueOrError{String}
    x = unsafe_pybytes_asstringandsize(o)
    if iserr(x)
        return R()
    else
        return R(unsafe_string(value(x)...))
    end
end
