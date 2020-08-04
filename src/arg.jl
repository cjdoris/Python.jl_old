macro unsafe_pyargparse(args, spec)
    unsafe_pyargparse_macro(args, nothing, spec)
end
macro unsafe_pyargparse(args, kwargs, spec)
    unsafe_pyargparse_macro(args, kwargs, spec)
end

function unsafe_pyargparse_macro(theargs, thekwargs, spec)
    (spec isa Expr) && (spec.head == :tuple) || error("argument specifications must be a tuple")
    # parse the spec
    args = []
    kwargs = Dict{Symbol, Int}()
    posonly = true
    kwonly = false
    numposonly = 0
    maxposargs = 0
    for (idx, argspec) in enumerate(spec.args)
        if argspec === :/
            posonly = false
            continue
        elseif argspec === :*
            posonly = false
            kwonly = true
            continue
        end
        dflt = nothing
        typ = nothing
        name = nothing
        if argspec isa Expr && argspec.head === :(=)
            length(argspec.args) == 2 || @goto badarg
            argspec, dflt = argspec.args
            dflt = Some(dflt)
        end
        if argspec isa Expr && argspec.head == :(::)
            length(argspec.args) == 2 || @goto badarg
            name, typ = argspec.args
            name isa Symbol || @goto badarg
            typ !== nothing || @goto badarg
        elseif argspec isa Symbol
            name = argspec
            typ = PyPtr
        else
            @goto badarg
        end
        push!(args, (name=name, typ=typ, dflt=dflt, idx=idx, var=gensym()))
        kwonly || (maxposargs += 1)
        posonly || setindex!(kwargs, idx, name)
        posonly && (numposonly += 1)
        continue
        @label badarg
        error("bad argument specification: $argspec")
    end
    # check what's left
    minposargs = 0
    while minposargs < numposonly && args[minposargs+1].dflt === nothing
        minposargs += 1
    end
    # make the parsing code
    quote
        let args=$(esc(theargs)), kwargs=$(esc(thekwargs))
            NT = NamedTuple{($(map(a->esc(QuoteNode(a.name)), args)...),), Tuple{$(map(a->esc(a.typ), args)...),}}
            R = ValueOrError{NT}
            r::R = R()
            # basic checks
            pyistuple(args) || (pyerror_set_TypeError("args must be a tuple"); @goto error)
            nargs = ccall((:PyTuple_Size, PYLIB), CPy_ssize_t, (PyPtr,), args)
            if $(minposargs == maxposargs)
                if nargs != $minposargs
                    pyerror_set_TypeError("require $($minposargs) positional arguments, got $nargs")
                    @goto error
                end
            else
                if nargs < $minposargs
                    pyerror_set_TypeError("require at least $($minposargs) positional arguments, got $nargs")
                    @goto error
                elseif nargs > $maxposargs
                    pyerror_set_TypeError("require at most $($maxposargs) positional arguments, got $nargs")
                    @goto error
                end
            end
            # initialize arguments to `nothing` or `Some(default)`
            $(map(a->:($(a.var) = $(a.dflt === nothing ? nothing : :(Some($(esc(something(a.dflt))))))), args)...)
            # parse positional arguments
            $(map(a->quote
                if $(a.idx) ≤ nargs
                    $(a.var) =
                        let x = PyBorrowedRef(ccall((:PyTuple_GetItem, PYLIB), PyPtr, (PyPtr, CPy_ssize_t), args, $(a.idx-1)))
                            let y = unsafe_pytryconvert($(esc(a.typ)), x)
                                if y.iserr
                                    @goto error
                                elseif y.isnothing
                                    pyerror_set_TypeError($("argument '$(a.name)' has incorrect type"))
                                    @goto error
                                else
                                    y.value
                                end
                            end
                        end
                end
            end, args[1:maxposargs])...)
            # parse keyword arguments
            if kwargs !== nothing
                error("parsing keyword arguments not implemented")
            end
            # anything missed?
            $(map(a->quote
                if $(a.var) === nothing
                    pyerror_set_TypeError($("missing required argument '$(a.name)'"))
                    @goto error
                end
            end, args)...)
            # construct the answer
            r = R(NT(($(map(a->:(something($(a.var))), args)...),)))
            @label error
            r
        end
    end
end
