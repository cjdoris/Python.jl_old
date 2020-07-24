unsafe_pystr_asjuliastring(o) =
    unsafe_pybytes_asjuliastring(unsafe_pystr_asutf8string(o))

unsafe_pyunicode_decodeutf8(buf, len) =
    unsafe_pystr_decodeutf8(buf, len, C_NULL)

unsafe_pystr(o::Union{String,SubString{String}}) =
    unsafe_pyunicode_decodeutf8(pointer(o), sizeof(o))
unsafe_pystr(o::AbstractString) =
    unsafe_pystr(convert(String, o))
unsafe_pystr(o::Symbol) =
    unsafe_pystr(string(o))
