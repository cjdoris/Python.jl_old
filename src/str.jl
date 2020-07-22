_pystrtype = pynulltype()
unsafe_pystrtype() = @unsafe_cacheget_object _pystrtype :PyUnicode_Type
pystrtype() = safe(unsafe_pystrtype())
export pystrtype

unsafe_pystr_asutf8string(o) =
    isnull(o) ? pynull() : @cpycall :PyUnicode_AsUTF8String(o::CPyPtr)::CPyNewPtr

unsafe_pystr_asjuliastring(o) =
    unsafe_pybytes_asjuliastring(unsafe_pystr_asutf8string(o))

unsafe_pyunicode_decodeutf8(buf, len, errs=C_NULL) =
    @cpycall :PyUnicode_DecodeUTF8(buf::Cstring, len::CPy_ssize_t, errs::Cstring)::CPyNewPtr

unsafe_pystr(o::Union{String,SubString{String}}) =
    unsafe_pyunicode_decodeutf8(pointer(o), sizeof(o))
unsafe_pystr(o::AbstractString) =
    unsafe_pystr(convert(String, o))
unsafe_pystr(o::Symbol) =
    unsafe_pystr(string(o))
unsafe_pystr(args...; kwargs...) = unsafe_pycall_args(unsafe_pystrtype(), args, kwargs)
