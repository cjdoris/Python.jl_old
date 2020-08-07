pyisnone(o::AbstractPyRef) = pyis(o, pynone())
export pyisnone

function unsafe_pynone_tryconvert(::Type{T}, o::AbstractPyRef) where {T}
    if Nothing <: T
        if pyisnone(o)
            return VNE{Nothing}(Some(nothing))
        else
            pyerror_set_TypeError("expecting `none`")
            return VNE{Nothing}()
        end
    else
        if pyisnone(o)
            return convert(VNE{T}, tryconvert(T, nothing))
        else
            pyerror_set_TypeError("expecting `none`")
            return VNE{T}()
        end
    end
end
