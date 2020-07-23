Base.@kwdef struct CPyStructSequence_Field
    name :: Cstring = C_NULL
    doc :: Cstring = C_NULL
end

Base.@kwdef struct CPyStructSequence_Desc
    name :: Cstring = C_NULL
    doc :: Cstring = C_NULL
    fields :: Ptr{CPyStructSequence_Field} = C_NULL
    count :: Cint = 0
end

# # NOTE: PyStructSequence_NewType does not make a copy of the strings, so we will need to keep the cache around for longer and magically delete it when the object is deleted.
# function unsafe_pystructsequencetype(name::Union{AbstractString,Symbol}, fields; doc::Union{Nothing,AbstractString}=nothing, count::Union{Nothing,Integer}=nothing)
#     fs = Vector{CPyStructSequence_Field}()
#     cache = []
#     for field in fields
#         x = Base.cconvert(Cstring, field)
#         push!(cache, x)
#         f = CPyStructSequence_Field(name=Base.unsafe_convert(Cstring, x))
#         push!(fs, f)
#     end
#     push!(fs, CPyStructSequence_Field())
#     n = Base.cconvert(Cstring, string(name))
#     push!(cache, n)
#     if doc===nothing
#         d = Cstring(C_NULL)
#     else
#         d = Base.cconvert(Cstring, doc)
#         push!(cache, d)
#     end
#     if count===nothing
#         count = length(fs)
#     elseif count<0 || count>length(fs)
#         error("count is out of range")
#     end
#     ref = Ref(CPyStructSequence_Desc(name=Base.unsafe_convert(Cstring, n), doc=Base.unsafe_convert(Cstring, d), fields=pointer(fs), count=count))
#     @cpycall :PyStructSequence_NewType(ref::Ref{CPyStructSequence_Desc})::CPyNewPtr
# end
# pystructsequencetype(args...; kwargs...) =
#     safe(unsafe_pystructsequencetype(args...; kwargs...))
# export pystructsequencetype
