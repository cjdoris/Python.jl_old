unsafe_pypow(x1, x2) = unsafe_pypow(x1, x2, pynone())
unsafe_pyipow(x1, x2) = unsafe_pyipow(x1, x2, pynone())

Base.:+(x::PyObject, y::PyObject) = pyadd(x, y)
Base.:-(x::PyObject, y::PyObject) = pysub(x, y)
Base.:*(x::PyObject, y::PyObject) = pymul(x, y)
Base.fld(x::PyObject, y::PyObject) = pyfld(x, y)
Base.:/(x::PyObject, y::PyObject) = pydiv(x, y)
Base.mod(x::PyObject, y::PyObject) = pymod(x, y)
Base.:^(x::PyObject, y::PyObject) = pypow(x, y)
Base.powermod(x::PyObject, y::PyObject, z::PyObject) = pypow(x, y, z)
Base.:-(x::PyObject) = pyneg(x)
Base.:+(x::PyObject) = pypos(x)
Base.abs(x::PyObject) = pyabs(x)
Base.:~(x::PyObject) = pyinv(x)
Base.:(<<)(x::PyObject, n) = pylshift(x, n)
Base.:(>>)(x::PyObject, n) = pyrshift(x, n)
Base.:(&)(x::PyObject, y::PyObject) = pyand(x, y)
Base.:(|)(x::PyObject, y::PyObject) = pyor(x, y)
Base.xor(x::PyObject, y::PyObject) = pyxor(x, y)

# TODO: matrix multiply
# TODO: inplace operations
