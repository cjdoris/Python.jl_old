_pybytestype = pynulltype()
unsafe_pybytestype() =
    @unsafe_cacheget_object _pybytestype :PyBytes_Type
pybytestype() = safe(unsafe_pybytestype())
export pybytestype

function unsafe_pybytes_asstringandsize(o)
    isnull(o) && return ValueOrError{Tuple{Ptr{Cchar}, CPy_ssize_t}}()
    buf = Ref{Ptr{Cchar}}(C_NULL)
    len = Ref{CPy_ssize_t}(0)
    e = iserr(@cpycall :PyBytes_AsStringAndSize(o::CPyPtr, buf::Ptr{Ptr{Cchar}}, len::Ptr{CPy_ssize_t})::CPyInt)
    ValueOrError(e, (buf[], len[]))
end

function unsafe_pybytes_asjuliastring(o)
    x = unsafe_pybytes_asstringandsize(o)
    if iserr(x)
        return ValueOrError{String}()
    else
        return ValueOrError(unsafe_string(value(x)...))
    end
end

unsafe_pybytes(args...; kwargs...) =
    unsafe_pycall_args(unsafe_pybytestype(), args, kwargs)
export pybytes
