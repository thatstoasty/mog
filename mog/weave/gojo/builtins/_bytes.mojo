alias Byte = Int8


@value
struct Bytes(StringableRaising, Sized, CollectionElement):
    """A mutable sequence of Bytes. Behaves like the python version.

    Note that some_bytes[i] returns an Int8.
    some_bytes *= 2 modifies the sequence in-place. Same with +=.

    Also __setitem__ is available, meaning you can do some_bytes[7] = 105 or
    even some_bytes[7] = some_other_byte (the latter must be only one byte long).
    """

    var _vector: DynamicVector[Int8]

    fn __init__(inout self):
        self._vector = DynamicVector[Int8]()

    fn __init__(inout self, owned vector: DynamicVector[Int8]):
        self._vector = vector

    fn __init__(inout self, size: Int):
        self._vector = DynamicVector[Int8](capacity=size)

    fn __init__(inout self, owned s: String):
        self._vector = s.as_bytes()

    fn __len__(self) -> Int:
        return len(self._vector)

    fn __getitem__(self, index: Int) -> Int8:
        return self._vector[index]

    fn __getitem__(self: Self, limits: Slice) raises -> Self:
        # TODO: Specifying no end to the span sets span end to this super large int for some reason.
        # Set it to len of the vector if that happens. Otherwise, if end is just too large in general, throw OOB error.
        var end = limits.end
        if limits.end == 9223372036854775807:
            end = len(self._vector)
        elif limits.end > len(self._vector):
            var error = "Bytes: Index out of range for limits.end. Received: " + str(
                limits.end
            ) + " but the length is " + str((len(self._vector)))
            raise Error(error)

        var new_bytes = Self()
        for i in range(limits.start, end, limits.step):
            new_bytes.append(self._vector[i])
        return new_bytes

    fn __setitem__(inout self, index: Int, value: Int8):
        self._vector[index] = value

    fn __setitem__(inout self, index: Int, value: Self):
        self._vector[index] = value[0]

    fn __eq__(self, other: Self) -> Bool:
        if self.__len__() != other.__len__():
            return False
        for i in range(self.__len__()):
            if self[i] != other[i]:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __add__(self, other: Self) -> Self:
        var new_vector = DynamicVector[Int8](capacity=self.__len__() + other.__len__())
        for i in range(self.__len__()):
            new_vector.push_back(self[i])
        for i in range(other.__len__()):
            new_vector.push_back(other[i])
        return Bytes(new_vector)

    fn __iadd__(inout self: Self, other: Self):
        var added_size = self.__len__() + other.__len__()
        if self._vector.capacity < added_size:
            self._vector.reserve(added_size * 2)
        self._vector.reserve(self.__len__() + other.__len__())
        self._vector.extend(other._vector)

    fn __str__(self) raises -> String:
        # Copy vector and add null terminator
        var s = self._vector
        s.append(0)

        return String(s)

    fn __repr__(self) raises -> String:
        return self.__str__()

    fn append(inout self, value: Int8):
        self._vector.append(value)

    fn extend(inout self, value: String):
        self += value

    fn extend(inout self, value: DynamicVector[Int8]):
        self += value

    fn index_byte(self, c: Byte) -> Int:
        var i = 0
        for i in range(self.__len__()):
            if self[i] == c:
                return i

        return -1

    fn has_prefix(self, prefix: Self) raises -> Bool:
        """Reports whether the byte slice s begins with prefix."""
        var len_comparison = len(self._vector) >= len(prefix)
        var prefix_comparison = self[0 : len(prefix)] == prefix
        return len_comparison and prefix_comparison

    fn has_suffix(self, suffix: Self) raises -> Bool:
        """Reports whether the byte slice s ends with suffix."""
        var len_comparison = len(self._vector) >= len(suffix)
        var suffix_comparison = self[
            self.__len__() - len(suffix) : self.__len__()
        ] == suffix
        return len_comparison and suffix_comparison

    fn capacity(self) -> Int:
        return self._vector.capacity


fn trim_null_characters(b: Bytes) -> Bytes:
    """Limits characters to the ASCII range of 1-127. Excludes null characters, extended characters, and unicode characters.
    """
    var new_b = Bytes(len(b))
    for i in range(len(b)):
        if b[i] > 0 and b[i] < 127:
            new_b[i] = b[i]
    return new_b
