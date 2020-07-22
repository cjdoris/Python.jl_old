unsafe_pyiter_next(o::PyObject) =
    isnull(o) ? pynull() : @cpycall :PyIter_Next(o::CPyPtr)::CPyAmbigErr{CPyNewPtr}
