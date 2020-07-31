const GEN_TOML = joinpath(@__DIR__, "generated.toml")
const GEN_JL = joinpath(@__DIR__, "generated.jl")

open(GEN_JL, "w") do io

    ### From generated.toml
    for (name, data) in open(Pkg.TOML.parse, GEN_TOML)
        unsafe = get(data, "unsafe", true)
        uname = unsafe ? "unsafe_$name" : name

        # wrap a C function
        cfuncs = get(data, "cfunc", [])
        cfuncs isa AbstractString && (cfuncs = [cfuncs])
        for cfunc in cfuncs
            words = split(cfunc)
            @assert length(words) ≥ 2
            cname = words[1]
            arginfo = words[2:end-1]
            ret = words[end]
            # process the return type
            if ret == "O"
                crettype = "Ptr{Cvoid}"
                iserr = "r == C_NULL"
                errval = "PYNULL"
                retval = "unsafe_pyobj(PyRef(r, false))"
            elseif ret == "?O"
                crettype = "Ptr{Cvoid}"
                iserr = "(r == C_NULL) && pyerror_occurred()"
                errval = "PYNULL"
                retval = "unsafe_pyobj(PyRef(r, false))"
            elseif ret == "B"
                crettype = "Cint"
                iserr = "r == -1"
                errval = "ValueOrError{Bool}()"
                retval = "ValueOrError{Bool}(r != 0)"
            elseif ret == "=B"
                crettype = "Cint"
                iserr = "false"
                errval = "false"
                retval = "(r != 0)"
            elseif ret == "V"
                crettype = "Cint"
                iserr = "r == -1"
                errval = "ValueOrError{Nothing}()"
                retval = "ValueOrError{Nothing}(nothing)"
            elseif startswith(ret, "!")
                crettype = ret[2:end]
                iserr = "iszero(r + one(r))"
                errval = "ValueOrError{$crettype}()"
                retval = "ValueOrError{$crettype}(r)"
            elseif startswith(ret, "?")
                crettype = ret[2:end]
                iserr = "iszero(r + one(r)) && pyerror_occurred()"
                errval = "ValueOrError{$crettype}()"
                retval = "ValueOrError{$crettype}(r)"
            elseif startswith(ret, "==")
                crettype = ret[3:end]
                iserr = "false"
                errval = "nothing"
                retval = "r"
            elseif startswith(ret, "=")
                crettype = ret[2:end]
                iserr = "false"
                errval = "ValueOrError{$crettype}()"
                retval = "ValueOrError{$crettype}(r)"
            else
                error("invalid return type: $ret")
            end
            # process the arguments
            args = []
            cargs = []
            cargtypes = []
            pre = []
            epre = []
            epost = []
            for (i, arg) in enumerate(arginfo)
                argname = "x$i"
                if arg == "O"
                    # Any -> PyObject
                    # returns an error if the conversion failed
                    argtype = "Any"
                    cargtype = "Ptr{Cvoid}"
                    push!(pre, """
                        if !isa($argname, AbstractPyRef)
                            $argname = unsafe_pyobj($argname)
                            isnull($argname) && return $errval
                        end
                    """)
                elseif arg == "!O"
                    # Any -> PyObject
                    # like "O" but steals a reference
                    argtype = "Any"
                    cargtype = "Ptr{Cvoid}"
                    push!(pre, """
                        if !isa($argname, AbstractPyRef)
                            $argname = unsafe_pyobj($argname)
                            isnull($argname) && return $errval
                        end
                    """)
                    push!(epre, """    incref($argname)""")
                    push!(epost, """        decref($argname)""")
                elseif arg == "?O"
                    # Any -> PyObject
                    # NULL is ok
                    argtype = "Any"
                    cargtype = "Ptr{Cvoid}"
                    push!(pre, """
                        if !isa($argname, AbstractPyRef)
                            $argname = unsafe_pyobj($argname)
                        end
                    """)
                elseif arg == "S"
                    # AbstractString -> Cstring
                    argtype = "AbstractString"
                    cargtype = "Cstring"
                elseif startswith(arg, "=")
                    # literal type, no conversion
                    i = findfirst('/', arg)
                    if i === nothing
                        argtype = cargtype = arg[2:end]
                    else
                        argtype = arg[2:i-1]
                        cargtype = arg[i+1:end]
                    end
                else
                    error("invalid arg type: $arg")
                end
                push!(cargs, argname)
                push!(cargtypes, cargtype)
                push!(args, "$argname::$argtype")
            end
            println(io, "function $uname($(join(args, ", ")))")
            for x in pre
                println(io, x)
            end
            for x in epre
                println(io, x)
            end
            println(io, """    r = ccall((:$cname, PYLIB), $crettype, ($(join(cargtypes, ", "))$(length(cargtypes)==1 ? "," : "")), $(join(cargs, ", ")))""")
            if iserr == "false"
                println(io, "    return $retval")
            else
                println(io, "    if $iserr")
                for x in epost
                    println(io, x)
                end
                println(io, "        return $errval")
                println(io, "    else")
                println(io, "        return $retval")
                println(io, "    end")
            end
            println(io, "end")
        end

        # cache a computed object
        cobj = get(data, "cachedobj", nothing)
        if cobj !== nothing
            _name = "_$name"
            if haskey(cobj, "expr")
                ex = cobj["expr"]
            elseif haskey(cobj, "cobj")
                ex = """cglobal((:$(cobj["cobj"]), PYLIB), CPyObject)"""
            elseif haskey(cobj, "cobjptr")
                ex = """unsafe_load(cglobal((:$(cobj["cobj"]), PYLIB), PyPtr))"""
            else
                error("cachedobj has no defining info")
            end
            println(io, """const $_name = pynull()""")
            println(io, "$uname() = unsafe_cacheget!($_name) do; $ex; end")
        end

        # defer to a python object
        defer = get(data, "defer", nothing)
        if defer !== nothing
            println(io, "$uname(args...; kwargs...) = unsafe_pycall_args(unsafe_$defer(), args, kwargs)")
        end

        # make the safe API version
        safe = get(data, "safe", unsafe)
        if safe
            println(io, "$name(args...; kwargs...) = safe($uname(args...; kwargs...))")
        end

        # export the API version
        doexport = get(data, "export", safe)
        if doexport
            println(io, "export $name")
        end

        println(io)
        println(io)
    end

    ### Exception types
    for name in [:BaseException, :Exception, :StopIteration, :GeneratorExit, :ArithmeticError, :LookupError, :AssertionError, :AttributeError, :BufferError, :EOFError, :FloatingPointError, :OSError, :ImportError, :IndexError, :KeyError, :KeyboardInterrupt, :MemoryError, :NameError, :OverflowError, :RuntimeError, :NotImplementedError, :SyntaxError, :IndentationError, :TabError, :ReferenceError, :SystemError, :SystemExit, :TypeError, :UnboundLocalError, :UnicodeError, :UnicodeEncodeError, :UnicodeDecodeError, :UnicodeTranslateError, :ValueError, :ZeroDivisionError]
        cname = "PyExc_$name"
        tname = "pyexc_$(name)_type"
        utname = "unsafe_$tname"
        _tname = "_$tname"
        setname = "pyerror_set_$name"
        occname = "pyerror_occurred_$name"
        println(io, "const $_tname = pynull()")
        println(io, "$utname() = unsafe_cacheget!($_tname) do; unsafe_load(cglobal((:$cname, PYLIB), PyPtr)); end")
        println(io, "$tname(args...; kwargs...) = safe($utname(args...; kwargs...))")
        println(io, "export $tname")
        println(io)
        println(io, "$setname(args...; kwargs...) = pyerror_set($utname(), args...; kwargs...)")
        println(io, "export $setname")
        println(io)
        println(io, "$occname() = pyerror_occurred($utname())")
        println(io, "export $occname")
        println(io)
    end

end

include_dependency("generated.toml")
include("generated.jl")
