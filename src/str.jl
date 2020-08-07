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

function unsafe_pystr_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    r = unsafe_pystr_asjuliastring(o)::VE{String}
    if T >: String
        convert(VNE, r)
    elseif T >: Symbol
        r.iserr ? VNE{Symbol}() : VNE{Symbol}(Some(Symbol(r.value)))
    elseif ((S = typeintersect(T, AbstractChar)) !== Union{})
        if r.iserr
            VNE{S}()
        elseif length(r.value) == 1
            convert(VNE{S}, tryconvert(S, first(r.value)))
        else
            pyerror_set_ValueError("only strings of length 1 can be converted to a character")
            VNE{S}()
        end
    else
        tryconvert(T, r)
    end
end

unsafe_pystr_convert(::Type{T}, o::AbstractPyRef) where {T} =
    tryconvtoconv(o, unsafe_pystr_tryconvert(T, o))
pystr_tryconvert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pystr_tryconvert(T, o))
pystr_convert(::Type{T}, o::AbstractPyRef) where {T} =
    safe(unsafe_pystr_convert(T, o))
export pystr_tryconvert, pystr_convert
