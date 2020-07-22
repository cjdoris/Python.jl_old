const CPy_hash_t = Cssize_t

const CPy_ssize_t = Cssize_t

# const PtrVoid = Ptr{Cvoid}

Base.@kwdef struct CPyMethodDefStruct
    name :: Cstring = C_NULL
    meth :: Ptr{Cvoid} = C_NULL
    flags :: Cint = 0
    doc :: Cstring = C_NULL
end

const CPy_METH_VARARGS = 0x0001 # args are a tuple of arguments
const CPy_METH_KEYWORDS = 0x0002  # two arguments: the varargs and the kwargs
const CPy_METH_NOARGS = 0x0004  # no arguments (NULL argument pointer)
const CPy_METH_O = 0x0008       # single argument (not wrapped in tuple)
const CPy_METH_CLASS = 0x0010 # for class methods
const CPy_METH_STATIC = 0x0020 # for static methods

Base.@kwdef struct CPyGetSetDefStruct
    name :: Cstring = C_NULL
    get :: Ptr{Cvoid} = C_NULL
    set :: Ptr{Cvoid} = C_NULL
    doc :: Cstring = C_NULL
    closure :: Ptr{Cvoid} = C_NULL
end

Base.@kwdef struct CPyMemberDefStruct
    name :: Cstring = C_NULL
    typ :: Cint = C_NULL
    offset :: CPy_ssize_t = 0
    flags :: Cint = 0
    doc :: Cstring = C_NULL
end

const CPy_T_SHORT        =0
const CPy_T_INT          =1
const CPy_T_LONG         =2
const CPy_T_FLOAT        =3
const CPy_T_DOUBLE       =4
const CPy_T_STRING       =5
const CPy_T_OBJECT       =6
const CPy_T_CHAR         =7
const CPy_T_BYTE         =8
const CPy_T_UBYTE        =9
const CPy_T_USHORT       =10
const CPy_T_UINT         =11
const CPy_T_ULONG        =12
const CPy_T_STRING_INPLACE       =13
const CPy_T_BOOL         =14
const CPy_T_OBJECT_EX    =16
const CPy_T_LONGLONG     =17 # added in Python 2.5
const CPy_T_ULONGLONG    =18 # added in Python 2.5
const CPy_T_PYSSIZET     =19 # added in Python 2.6
const CPy_T_NONE         =20 # added in Python 3.0

const CPy_READONLY = 1
const CPy_READ_RESTRICTED = 2
const CPy_WRITE_RESTRICTED = 4
const CPy_RESTRICTED = (CPy_READ_RESTRICTED | CPy_WRITE_RESTRICTED)

Base.@kwdef struct CPyNumberMethodsStruct
    add :: Ptr{Cvoid} = C_NULL # (o,o)->o
    subtract :: Ptr{Cvoid} = C_NULL # (o,o)->o
    multiply :: Ptr{Cvoid} = C_NULL # (o,o)->o
    remainder :: Ptr{Cvoid} = C_NULL # (o,o)->o
    divmod :: Ptr{Cvoid} = C_NULL # (o,o)->o
    power :: Ptr{Cvoid} = C_NULL # (o,o,o)->o
    negative :: Ptr{Cvoid} = C_NULL # (o)->o
    positive :: Ptr{Cvoid} = C_NULL # (o)->o
    absolute :: Ptr{Cvoid} = C_NULL # (o)->o
    bool :: Ptr{Cvoid} = C_NULL # (o)->Cint
    invert :: Ptr{Cvoid} = C_NULL # (o)->o
    lshift :: Ptr{Cvoid} = C_NULL # (o,o)->o
    rshift :: Ptr{Cvoid} = C_NULL # (o,o)->o
    and :: Ptr{Cvoid} = C_NULL # (o,o)->o
    xor :: Ptr{Cvoid} = C_NULL # (o,o)->o
    or :: Ptr{Cvoid} = C_NULL # (o,o)->o
    int :: Ptr{Cvoid} = C_NULL # (o)->o
    _reserved :: Ptr{Cvoid} = C_NULL
    float :: Ptr{Cvoid} = C_NULL # (o)->o
    inplace_add :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_subtract :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_multiply :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_remainder :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_power :: Ptr{Cvoid} = C_NULL # (o,o,o)->o
    inplace_lshift :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_rshift :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_and :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_xor :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_or :: Ptr{Cvoid} = C_NULL # (o,o)->o
    floordivide :: Ptr{Cvoid} = C_NULL # (o,o)->o
    truedivide :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_floordivide :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_truedivide :: Ptr{Cvoid} = C_NULL # (o,o)->o
    index :: Ptr{Cvoid} = C_NULL # (o)->o
    matrixmultiply :: Ptr{Cvoid} = C_NULL # (o,o)->o
    imatrixmultiply :: Ptr{Cvoid} = C_NULL # (o,o)->o
end

Base.@kwdef struct CPySequenceMethodsStruct
    length :: Ptr{Cvoid} = C_NULL # (o)->Py_ssize_t
    concat :: Ptr{Cvoid} = C_NULL # (o,o)->o
    repeat :: Ptr{Cvoid} = C_NULL # (o,Py_ssize_t)->o
    item :: Ptr{Cvoid} = C_NULL # (o,Py_ssize_t)->o
    _was_item :: Ptr{Cvoid} = C_NULL
    ass_item :: Ptr{Cvoid} = C_NULL # (o,Py_ssize_t,o)->Cint
    _was_ass_slice :: Ptr{Cvoid} = C_NULL
    contains :: Ptr{Cvoid} = C_NULL # (o,o)->Cint
    inplace_concat :: Ptr{Cvoid} = C_NULL # (o,o)->o
    inplace_repeat :: Ptr{Cvoid} = C_NULL # (o,Py_ssize_t)->o
end

Base.@kwdef struct CPyMappingMethodsStruct
    length :: Ptr{Cvoid} = C_NULL # (o)->Py_ssize_t
    subscript :: Ptr{Cvoid} = C_NULL # (o,o)->o
    ass_subscript :: Ptr{Cvoid} = C_NULL # (o,o,o)->Cint
end



################################################################
# type-flag constants

# Python 2.7
const Py_TPFLAGS_HAVE_GETCHARBUFFER  = (0x00000001<<0)
const Py_TPFLAGS_HAVE_SEQUENCE_IN = (0x00000001<<1)
const Py_TPFLAGS_GC = 0 # was sometimes (0x00000001<<2) in Python <= 2.1
const Py_TPFLAGS_HAVE_INPLACEOPS = (0x00000001<<3)
const Py_TPFLAGS_CHECKTYPES = (0x00000001<<4)
const Py_TPFLAGS_HAVE_RICHCOMPARE = (0x00000001<<5)
const Py_TPFLAGS_HAVE_WEAKREFS = (0x00000001<<6)
const Py_TPFLAGS_HAVE_ITER = (0x00000001<<7)
const Py_TPFLAGS_HAVE_CLASS = (0x00000001<<8)
const Py_TPFLAGS_HAVE_INDEX = (0x00000001<<17)
const Py_TPFLAGS_HAVE_NEWBUFFER = (0x00000001<<21)
const Py_TPFLAGS_STRING_SUBCLASS       = (0x00000001<<27)

# Python 3.0+ has only these:
const Py_TPFLAGS_HEAPTYPE = (0x00000001<<9)
const Py_TPFLAGS_BASETYPE = (0x00000001<<10)
const Py_TPFLAGS_READY = (0x00000001<<12)
const Py_TPFLAGS_READYING = (0x00000001<<13)
const Py_TPFLAGS_HAVE_GC = (0x00000001<<14)
const Py_TPFLAGS_HAVE_VERSION_TAG   = (0x00000001<<18)
const Py_TPFLAGS_VALID_VERSION_TAG  = (0x00000001<<19)
const Py_TPFLAGS_IS_ABSTRACT = (0x00000001<<20)
const Py_TPFLAGS_INT_SUBCLASS         = (0x00000001<<23)
const Py_TPFLAGS_LONG_SUBCLASS        = (0x00000001<<24)
const Py_TPFLAGS_LIST_SUBCLASS        = (0x00000001<<25)
const Py_TPFLAGS_TUPLE_SUBCLASS       = (0x00000001<<26)
const Py_TPFLAGS_BYTES_SUBCLASS       = (0x00000001<<27)
const Py_TPFLAGS_UNICODE_SUBCLASS     = (0x00000001<<28)
const Py_TPFLAGS_DICT_SUBCLASS        = (0x00000001<<29)
const Py_TPFLAGS_BASE_EXC_SUBCLASS    = (0x00000001<<30)
const Py_TPFLAGS_TYPE_SUBCLASS        = (0x00000001<<31)

# only use this if we have the stackless extension
const Py_TPFLAGS_HAVE_STACKLESS_EXTENSION = (0x00000003<<15)
