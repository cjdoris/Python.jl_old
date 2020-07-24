unsafe_pydate(o::Date) =
    unsafe_pydate(year(o), month(o), day(o))

unsafe_pytime(o::Time) =
    if iszero(nanosecond(o))
        unsafe_pytime(hour(o), minute(o), second(o), millisecond(o)*1000 + microsecond(o))
    else
        throw(InexactError(:pytime, PyObject, o))
    end

unsafe_pydatetime(o::DateTime) =
    unsafe_pydatetime(year(o), month(o), day(o), hour(o), minute(o), second(o), millisecond(o)*1000)
