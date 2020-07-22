const PYVERSION = v"3.6"
const PYLIB = "python3"
const PYHOME = Conda.PYTHONDIR
const PYWHOME = Base.cconvert(Cwstring, PYHOME)
const PYLIBPATH = joinpath(PYHOME, PYLIB)
const PYLIBPTR = Ref(C_NULL)
const PYISSTACKLESS = false

function __init__()
    PYLIBPTR[] = dlopen(PYLIBPATH)
    ccall((:Py_SetPythonHome, PYLIB), Cvoid, (Cwstring,), pointer(PYWHOME))
    ccall((:Py_Initialize, PYLIB), Cvoid, ())
end
