abstract type AbstractCPyTypeObject <: AbstractCPyVarObject end

"""
    CPyTypeObject

The common layout of all Python type objects.
"""
Base.@kwdef struct CPyTypeObject <: AbstractCPyTypeObject
    ob_base :: CPyVarObject = CPyVarObject()
    name :: Cstring = C_NULL

    basicsize :: CPy_ssize_t = 0
    itemsize :: CPy_ssize_t = 0

    dealloc :: Ptr{Cvoid} = C_NULL
    vectorcall_offset :: CPy_ssize_t = C_NULL
    getattr :: Ptr{Cvoid} = C_NULL
    setattr :: Ptr{Cvoid} = C_NULL
    as_async :: Ptr{Cvoid} = C_NULL
    repr :: Ptr{Cvoid} = C_NULL

    as_number :: Ptr{CPyNumberMethodsStruct} = C_NULL
    as_sequence :: Ptr{CPySequenceMethodsStruct} = C_NULL
    as_mapping :: Ptr{CPyMappingMethodsStruct} = C_NULL

    hash :: Ptr{Cvoid} = C_NULL
    call :: Ptr{Cvoid} = C_NULL
    str :: Ptr{Cvoid} = C_NULL
    getattro :: Ptr{Cvoid} = C_NULL
    setattro :: Ptr{Cvoid} = C_NULL

    as_buffer :: Ptr{Cvoid} = C_NULL

    flags :: Culong = 0

    doc :: Cstring = C_NULL

    traverse :: Ptr{Cvoid} = C_NULL

    clear :: Ptr{Cvoid} = C_NULL

    richcompare :: Ptr{Cvoid} = C_NULL

    weaklistoffset :: CPy_ssize_t = 0

    iter :: Ptr{Cvoid} = C_NULL
    iternext :: Ptr{Cvoid} = C_NULL

    methods :: Ptr{CPyMethodDefStruct} = C_NULL
    members :: Ptr{CPyMemberDefStruct} = C_NULL
    getset :: Ptr{CPyGetSetDefStruct} = C_NULL
    base :: Ptr{CPyObject} = C_NULL
    dict :: Ptr{CPyObject} = C_NULL
    descr_get :: Ptr{Cvoid} = C_NULL
    descr_set :: Ptr{Cvoid} = C_NULL
    dictoffset :: CPy_ssize_t = 0
    init :: Ptr{Cvoid} = C_NULL
    alloc :: Ptr{Cvoid} = C_NULL
    new :: Ptr{Cvoid} = C_NULL
    free :: Ptr{Cvoid} = C_NULL
    is_gc :: Ptr{Cvoid} = C_NULL
    bases :: Ptr{CPyObject} = C_NULL
    mro :: Ptr{CPyObject} = C_NULL
    cache :: Ptr{CPyObject} = C_NULL
    subclasses :: Ptr{CPyObject} = C_NULL
    weaklist :: Ptr{CPyObject} = C_NULL
    del :: Ptr{Cvoid} = C_NULL

    version_tag :: Cuint = 0

    finalize :: Ptr{Cvoid} = C_NULL
    vectorcall :: Ptr{Cvoid} = C_NULL
end

pynulltype() = pynull(CPyTypeObject)

_pytypetype = pynulltype()
unsafe_pytypetype() = @unsafe_cacheget_object _pytypetype :PyType_Type
pytypetype() = safe(unsafe_pytypetype())
export pytypetype

_pyobjecttype = pynulltype()
unsafe_pyobjecttype() = @unsafe_cacheget_object _pyobjecttype :PyBaseObject_Type
pyobjecttype() = safe(unsafe_pyobjecttype())
export pyobjecttype

_pysupertype = pynulltype()
unsafe_pysupertype() = @unsafe_cacheget_object _pysupertype :PySuper_Type
pysupertype() = safe(unsafe_pysupertype())
export pysupertype

unsafe_pytype(o::PyObject) =
    unsafe_pyobj(PyBorrowedObjRef(isnull(o) ? C_NULL : uptr(CPyObject, o).type[]))
unsafe_pytype(o) =
    unsafe_pytype(unsafe_pyobj(o))
pytype(o) =
    safe(unsafe_pytype(o))
export pytype
