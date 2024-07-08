from bit import countl_zero
from algorithm.functional import vectorize
from sys.info import simdwidthof


alias simd_width_u8 = simdwidthof[DType.uint8]()


@value
struct UnicodeString(Stringable, Sized):
    """A string that supports Unicode characters.

    The algorithms to handle UTF-8 are from @maxim on the Mojo Discord. Thanks!
    """

    var inner: String

    @always_inline
    fn __init__(inout self, owned s: String):
        self.inner = s^

    @always_inline
    fn __init__(inout self, owned bytes: List[UInt8]):
        if bytes[-1] != 0:
            bytes.append(0)
        self.inner = String(bytes^)

    @always_inline
    fn __len__(self) -> Int:
        """Count the number of runes in a string.

        Returns:
            The number of runes in the string.
        """
        var data = DTypePointer[DType.uint8](self.inner.unsafe_uint8_ptr())
        var byte_count = len(self.inner)
        var result = 0

        @parameter
        fn count[simd_width: Int](offset: Int):
            result += int(((data.load[width=simd_width](offset) >> 6) != 0b10).cast[DType.uint8]().reduce_add())

        vectorize[count, simd_width_u8](byte_count)
        return result

    @always_inline
    fn __str__(self) -> String:
        return self.inner

    @always_inline
    fn __getitem__(self: Reference[Self], slice: Slice) -> StringSlice[self.is_mutable, self.lifetime]:
        """TODO: Doesn't handle negative indices."""
        var bytes_left = len(self[].inner)
        var total_char_length: Int = 0
        for _ in range(slice.start, slice.end):
            # Number of bytes of the current character
            var char_length = int(
                (DTypePointer[DType.uint8](self[].inner.unsafe_uint8_ptr() + total_char_length).load() >> 7 == 0).cast[
                    DType.uint8
                ]()
                * 1
                + countl_zero(~DTypePointer[DType.uint8](self[].inner.unsafe_uint8_ptr() + total_char_length).load())
            )

            # Move iterator forward
            bytes_left -= char_length
            total_char_length += char_length

        return StringSlice[self.is_mutable, self.lifetime](
            unsafe_from_utf8_ptr=self[].inner.unsafe_uint8_ptr(), len=total_char_length
        )

    @always_inline
    fn bytecount(self) -> Int:
        return len(self.inner)

    @always_inline
    fn __iter__(
        self: Reference[Self],
    ) -> _StringIter[self.is_mutable, self.lifetime]:
        return _StringIter(self[].inner)


@value
struct _StringIter[mutability: Bool, lifetime: AnyLifetime[mutability].type]():
    var bytes_left: Int
    var ptr: UnsafePointer[UInt8]

    @always_inline
    fn __init__(inout self, src: Reference[String, mutability, lifetime]):
        self.bytes_left = len(src[])
        self.ptr = src[].unsafe_uint8_ptr()

    fn __next__(inout self) -> StringSlice[mutability, lifetime]:
        # Number of bytes of the current character
        var char_length = int(
            (DTypePointer[DType.uint8](self.ptr).load() >> 7 == 0).cast[DType.uint8]() * 1
            + countl_zero(~DTypePointer[DType.uint8](self.ptr).load())
        )

        # Move iterator forward
        self.bytes_left -= char_length
        self.ptr += char_length

        return StringSlice[mutability, lifetime](unsafe_from_utf8_ptr=self.ptr - char_length, len=char_length)

    @always_inline
    fn __len__(self) -> Int:
        return self.bytes_left
