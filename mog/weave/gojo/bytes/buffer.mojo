from tensor import Tensor
from ..io.traits import (
    Reader,
    Writer,
    ByteReader,
    ByteWriter,
    WriterTo,
    StringWriter,
    ReaderFrom,
)
from ..builtins import cap, copy
from ..builtins._bytes import (
    Bytes,
    Byte,
    trim_null_characters,
)


alias Rune = Int32

# TODO: Maybe I need to use static vectors here?
# smallbuffer_size is an initial allocation minimal capacity.
alias smallbuffer_size: Int = 64

# The ReadOp constants describe the last action performed on
# the buffer, so that unread_rune and unread_byte can check for
# invalid usage. op_read_runeX constants are chosen such that
# converted to Int they correspond to the rune size that was read.
alias ReadOp = Int8

# Don't use iota for these, as the values need to correspond with the
# names and comments, which is easier to see when being explicit.
alias op_read: ReadOp = -1  # Any other read operation.
alias op_invalid: ReadOp = 0  # Non-read operation.
alias op_read_rune1: ReadOp = 1  # read rune of size 1.
alias op_read_rune2: ReadOp = 2  # read rune of size 2.
alias op_read_rune3: ReadOp = 3  # read rune of size 3.
alias op_read_rune4: ReadOp = 4  # read rune of size 4.

alias max_int: Int = 2147483647
# MinRead is the minimum slice size passed to a read call by
# [Buffer.read_from]. As long as the [Buffer] has at least MinRead bytes beyond
# what is required to hold the contents of r, read_from will not grow the
# underlying buffer.
alias MinRead: Int8 = 512

# # ErrTooLarge is passed to panic if memory cannot be allocated to store data in a buffer.
alias ErrTooLarge = "buffer.Buffer: too large"
alias errNegativeRead = "buffer.Buffer: reader returned negative count from read"
alias ErrShortWrite = "short write"


# A Buffer is a variable-sized buffer of bytes with [Buffer.read] and [Buffer.write] methods.
# The zero value for Buffer is an empty buffer ready to use.
@value
struct Buffer(
    Writer,
    StringWriter,
    Reader,
    ByteReader,
    ByteWriter,
    WriterTo,
    ReaderFrom,
    StringableRaising,
    Sized,
):
    var buf: Bytes  # contents are the bytes buf[off : len(buf)]
    var off: Int  # read at &buf[off], write at &buf[len(buf)]
    var last_read: ReadOp  # last read operation, so that unread* can work correctly.

    fn __init__(inout self, owned buf: Bytes):
        self.buf = buf
        self.off = 0
        self.last_read = op_invalid

    fn bytes(self) raises -> Bytes:
        """Returns a slice of length self.__len__() holding the unread portion of the buffer.
        The slice is valid for use only until the next buffer modification (that is,
        only until the next call to a method like [Buffer.read], [Buffer.write], [Buffer.reset], or [Buffer.truncate]).
        The slice aliases the buffer content at least until the next buffer modification,
        so immediate changes to the slice will affect the result of future reads.
        """
        return self.buf[self.off :]

    fn available_buffer(self) raises -> Bytes:
        """Returns an empty buffer with self.Available() capacity.
        This buffer is intended to be appended to and
        passed to an immediately succeeding [Buffer.write] call.
        The buffer is only valid until the next write operation on self.
        """
        return self.buf[len(self.buf) :]

    fn __str__(self) raises -> String:
        """Returns the contents of the unread portion of the buffer
        as a string. If the [Buffer] is a nil pointer, it returns "<nil>".

        To build strings more efficiently, see the strings.Builder type.
        """
        return str(self.buf[self.off :])

    fn empty(self) -> Bool:
        """Reports whether the unread portion of the buffer is empty."""
        return len(self.buf) <= self.off

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the buffer;
        self.__len__() == len(self.Bytes())."""
        return len(self.buf) - self.off

    fn cap(self) -> Int:
        """Cap returns the capacity of the buffer's underlying byte slice, that is, the
        total space allocated for the buffer's data."""
        return cap(self.buf)

    fn available(self) -> Int:
        """Returns how many bytes are unused in the buffer."""
        return cap(self.buf) - len(self.buf)

    fn truncate(inout self, n: Int) raises:
        """Discards all but the first n unread bytes from the buffer
        but continues to use the same allocated storage.
        It panics if n is negative or greater than the length of the buffer.
        """
        if n == 0:
            self.reset()
            return

        self.last_read = op_invalid
        if n < 0 or n > self.__len__():
            raise Error("buffer.Buffer: truncation out of range")

        self.buf = self.buf[: self.off + n]

    fn reset(inout self) raises:
        """Resets the buffer to be empty,
        but it retains the underlying storage for use by future writes.
        reset is the same as [buffer.truncate](0)."""
        self.buf = self.buf[0:0]
        self.off = 0
        self.last_read = op_invalid

    fn try_grow_by_reslice(inout self, n: Int) raises -> (Int, Bool):
        """Inlineable version of grow for the fast-case where the
        internal buffer only needs to be resliced.
        It returns the index where bytes should be written and whether it succeeded."""
        var l = self.__len__()

        if n <= cap(self.buf) - l:
            # FIXME: It seems like reslicing in go can extend the length of the slice. Doens't work like that for my get slice impl.
            # Instead, just add bytes of len(n) to the end of the buffer for now.
            # self.buf = self.buf[: l + n]
            self.buf += Bytes(n)
            return l, True

        return 0, False

    fn grow(inout self, n: Int) raises -> Int:
        """Grows the buffer to guarantee space for n more bytes.
        It returns the index where bytes should be written.
        If the buffer can't grow it will panic with ErrTooLarge."""
        var m: Int = self.__len__()
        # If buffer is empty, reset to recover space.
        if m == 0 and self.off != 0:
            self.reset()

        # Try to grow by means of a reslice.
        var i: Int
        var ok: Bool
        i, ok = self.try_grow_by_reslice(n)
        if ok:
            return i

        # TODO: What are the implications of using len 0 instead of nil check for bytes buffer?
        if len(self.buf) == 0 and n <= smallbuffer_size:
            self.buf = Bytes(smallbuffer_size)
            # self.buf._vector.reserve(smallbuffer_size)
            # Returning 0 messed things up by inserting on the first index twice, but why?
            # return 0
            pass

        var c = cap(self.buf)
        if Float64(n) <= c / 2 - m:
            # We can slide things down instead of allocating a new
            # slice. We only need m+n <= c to slide, but
            # we instead var capacity get twice as large so we
            # don't spend all our time copying.
            _ = copy(self.buf, self.buf[self.off :])
        elif c > max_int - c - n:
            raise Error("buffer.Buffer: too large")
        else:
            # Add self.off to account for self.buf[:self.off] being sliced off the front.
            var sl = self.buf[self.off :]
            self.buf = self.grow_slice(sl, self.off + n)
            # self.buf = sl

        # Restore self.off and len(self.buf).
        self.off = 0
        # FIXME: It seems like reslicing in go can extend the length of the slice. Doens't work like that for my get slice impl.
        # Instead, just add bytes of len(n) to the end of the buffer for now.
        # self.buf = self.buf[: m + n]
        self.buf += Bytes(n)
        return m

    fn Grow(inout self, n: Int) raises:
        """Grows the buffer's capacity, if necessary, to guarantee space for
        another n bytes. After grow(n), at least n bytes can be written to the
        buffer without another allocation.
        If n is negative, grow will panic.
        If the buffer can't grow it will panic with [ErrTooLarge].
        """
        if n < 0:
            raise Error("buffer.Buffer.grow: negative count")

        var m = self.grow(n)
        self.buf = self.buf[:m]

    fn write(inout self, src: Bytes) raises -> Int:
        """Appends the contents of p to the buffer, growing the buffer as
        needed. The return value n is the length of p; err is always nil. If the
        buffer becomes too large, write will panic with [ErrTooLarge].
        """
        self.last_read = op_invalid
        # var m: Int
        # var ok: Bool
        # # TODO: This logic explodes when using write_to. for some reason it ends up trying to take a slice of an empty buffer and gets an OOB error.
        # # IDK why, but for now we can var the dynamicvector grow on its own and not try to mess w the capacity and growing it.
        # m, ok = self.try_grow_by_reslice(len(src))
        # if not ok:
        #     m = self.grow(len(src))
        # var b = self.buf[m:]
        return copy(self.buf, src, len(self.buf))

    fn write_string(inout self, src: String) raises -> Int:
        """Appends the contents of s to the buffer, growing the buffer as
        needed. The return value n is the length of s; err is always nil. If the
        buffer becomes too large, write_string will panic with [ErrTooLarge].
        """
        # self.last_read = op_invalid
        # var m: Int
        # var ok: Bool
        # m, ok = self.try_grow_by_reslice(len(src))
        # if not ok:
        #     m = self.grow(len(src))
        # var b = self.buf[m:]
        return self.write(Bytes(src))

    fn read_from[R: Reader](inout self, inout reader: R) raises -> Int64:
        """Reads data from r until EOF and appends it to the buffer, growing
        the buffer as needed. The return value n is the number of bytes read. Any
        error except io.EOF encountered during the read is also returned. If the
        buffer becomes too large, read_from will panic with [ErrTooLarge].
        """
        self.last_read = op_invalid
        var read_count: Int64 = 0
        while True:
            try:
                read_count = reader.read(self.buf)
            except e:
                if e.__str__() == "EOF":
                    break
                raise

        return len(self.buf)

    fn grow_slice(self, inout b: Bytes, n: Int) raises -> Bytes:
        """Grows b by n, preserving the original content of self.
        If the allocation fails, it panics with ErrTooLarge.
        """
        # TODO(http:#golang.org/issue/51462): We should rely on the append-make
        # pattern so that the compiler can call runtime.growslice. For example:
        # 	return append(b, make(bytes, n)...)
        # This avoids unnecessary zero-ing of the first len(b) bytes of the
        # allocated slice, but this pattern causes b to escape onto the heap.
        #
        # Instead use the append-make pattern with a nil slice to ensure that
        # we allocate buffers rounded up to the closest size class.
        var c = len(b) + n  # ensure enough space for n elements
        if c < 2 * cap(b):
            # The growth rate has historically always been 2x. In the future,
            # we could rely purely on append to determine the growth rate.
            c = 2 * cap(b)

        var resizedbuffer = Bytes(c)
        _ = copy(resizedbuffer, b)
        # var b2: Bytes = Bytes()
        # b2._vector.reserve(c)

        # # var b2 = append(bytes(nil), make(bytes, c)...)
        # _ = copy(b2, b)
        # return b2[:len(b)]
        # b._vector.reserve(c)
        return resizedbuffer[: len(b)]

    fn write_to[W: Writer](inout self, inout writer: W) raises -> Int64:
        """Writes data to w until the buffer is drained or an error occurs.
        The return value n is the number of bytes written; it always fits into an
        Int, but it is int64 to match the io.WriterTo interface. Any error
        encountered during the write is also returned.
        """
        self.last_read = op_invalid
        var n_bytes: Int = self.__len__()
        var n: Int64 = 0
        if n_bytes > 0:
            var sl = self.buf[self.off :]
            var m = writer.write(sl)
            if m > n_bytes:
                raise Error("buffer.Buffer.write_to: invalid write count")

            self.off += m
            n = Int64(m)

            # all bytes should have been written, by definition of
            # write method in io.Writer
            if m != n_bytes:
                raise Error(ErrShortWrite)

        # Buffer is now empty; reset.
        self.reset()
        return n

    fn write_byte(inout self, byte: Byte) raises -> Int:
        """Appends the byte c to the buffer, growing the buffer as needed.
        The returned error is always nil, but is included to match [bufio.Writer]'s
        write_byte. If the buffer becomes too large, write_byte will panic with
        [ErrTooLarge].
        """
        # TODO: Skipping all 0 bytes for now until I figure out how to handle the grow function indexing
        # not working correctly and the 0s remaining in the empty dynamic vector indices.
        # if byte != 0:
        #     self.last_read = op_invalid
        #     var m: Int
        #     var ok: Bool
        #     m, ok = self.try_grow_by_reslice(1)
        #     if not ok:
        #         m = self.grow(1)

        #     # why is m 0 twice in a row?
        #     self.buf[m] = byte
        #     return m
        # return 0
        self.last_read = op_invalid
        self.buf.append(byte)
        return 1

    # fn write_rune(inout self, r: Rune) -> Int:
    #     """Appends the UTF-8 encoding of Unicode code point r to the
    #     buffer, returning its length and an error, which is always nil but is
    #     included to match [bufio.Writer]'s write_rune. The buffer is grown as needed;
    #     if it becomes too large, write_rune will panic with [ErrTooLarge].
    #     """
    #     # Compare as uint32 to correctly handle negative runes.
    #     if UInt32(r) < utf8.RuneSelf:
    #         self.write_byte(Byte(r))
    #         return 1

    #     self.last_read = op_invalid
    #     var m: Int
    #     var ok: Bool
    #     m, ok = self.try_grow_by_reslice(utf8.UTFMax)
    #     if not ok:
    #         m = self.grow(utf8.UTFMax)

    #     self.buf = utf8.AppendRune(self.buf[:m], r)
    #     return len(self.buf) - m

    fn read(inout self, inout dest: Bytes) raises -> Int:
        """Reads the next len(p) bytes from the buffer or until the buffer
        is drained. The return value n is the number of bytes read. If the
        buffer has no data to return, err is io.EOF (unless len(p) is zero);
        otherwise it is nil.
        """
        self.last_read = op_invalid
        if self.empty():
            # Buffer is empty, reset to recover space.
            self.reset()
            if len(dest) == 0:
                return 0

            return 0

        var bytebuffer = self.buf[self.off :]
        var index = copy(dest, bytebuffer)
        self.off += index
        if index > 0:
            self.last_read = op_read

        return index

    fn next(inout self, inout n: Int) raises -> Bytes:
        """Returns a slice containing the next n bytes from the buffer,
        advancing the buffer as if the bytes had been returned by [Buffer.read].
        If there are fewer than n bytes in the buffer, next returns the entire buffer.
        The slice is only valid until the next call to a read or write method.
        """
        self.last_read = op_invalid
        var m = self.__len__()
        if n > m:
            n = m

        var data = self.buf[self.off : self.off + n]
        self.off += n
        if n > 0:
            self.last_read = op_read

        return data

    fn read_byte(inout self) raises -> Byte:
        """Reads and returns the next byte from the buffer.
        If no byte is available, it returns error io.EOF.
        """
        if self.empty():
            # Buffer is empty, reset to recover space.
            self.reset()
            return 0

        var c = self.buf[self.off]
        self.off += 1
        self.last_read = op_read

        return c

    # read_rune reads and returns the next UTF-8-encoded
    # Unicode code point from the buffer.
    # If no bytes are available, the error returned is io.EOF.
    # If the bytes are an erroneous UTF-8 encoding, it
    # consumes one byte and returns U+FFFD, 1.
    # fn read_rune(self) (r rune, size Int, err error)
    #     if self.empty()
    #         # Buffer is empty, reset to recover space.
    #         self.reset()
    #         return 0, 0, io.EOF
    #
    #     c := self.buf[self.off]
    #     if c < utf8.RuneSelf
    #         self.off+= 1
    #         self.last_read = op_read_rune1
    #         return rune(c), 1, nil
    #
    #     r, n := utf8.DecodeRune(self.buf[self.off:])
    #     self.off += n
    #     self.last_read = ReadOp(n)
    #     return r, n, nil
    #

    # unread_rune unreads the last rune returned by [Buffer.read_rune].
    # If the most recent read or write operation on the buffer was
    # not a successful [Buffer.read_rune], unread_rune returns an error.  (In this regard
    # it is stricter than [Buffer.unread_byte], which will unread the last byte
    # from any read operation.)
    # fn unread_rune(self):
    #     if self.last_read <= op_invalid
    #         return errors.New("buffer.Buffer: unread_rune: previous operation was not a successful read_rune")
    #
    #     if self.off >= Int(self.last_read)
    #         self.off -= Int(self.last_read)
    #
    #     self.last_read = op_invalid
    #     return nil

    # var err_unread_byte = errors.New("buffer.Buffer: unread_byte: previous operation was not a successful read")

    fn unread_byte(inout self) raises -> None:
        """Unreads the last byte returned by the most recent successful
        read operation that read at least one byte. If a write has happened since
        the last read, if the last read returned an error, or if the read read zero
        bytes, unread_byte returns an error.
        """
        if self.last_read == op_invalid:
            raise Error(
                "buffer.Buffer: unread_byte: previous operation was not a successful"
                " read"
            )

        self.last_read = op_invalid
        if self.off > 0:
            self.off -= 1

    fn read_bytes(inout self, delim: Byte) raises -> Bytes:
        """Reads until the first occurrence of delim in the input,
        returning a slice containing the data up to and including the delimiter.
        If read_bytes encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often io.EOF).
        read_bytes returns err != nil if and only if the returned data does not end in
        delim.
        """
        var sl = self.read_slice(delim)
        # return a copy of slice. The buffer's backing array may
        # be overwritten by later calls.
        var lines = Bytes()
        for i in range(len(sl)):
            lines[i] = sl[i]
        return lines

    fn read_slice(inout self, delim: Byte) raises -> Bytes:
        """Like read_bytes but returns a reference to internal buffer data."""
        var i = self.buf[self.off :].index_byte(delim)
        var end = self.off + i + 1
        if i < 0:
            end = len(self.buf)

        var line = self.buf[self.off : end]
        self.off = end
        self.last_read = op_read
        return line

    fn read_string(inout self, delim: Byte) raises -> String:
        """Reads until the first occurrence of delim in the input,
        returning a string containing the data up to and including the delimiter.
        If read_string encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often io.EOF).
        read_string returns err != nil if and only if the returned data does not end
        in delim.
        """
        var sl = self.read_slice(delim)
        return str(sl)


fn new_buffer() -> Buffer:
    """Creates and initializes a new [Buffer] using buf as its`
    initial contents. The new [Buffer] takes ownership of buf, and the
    caller should not use buf after this call. new_buffer is intended to
    prepare a [Buffer] to read existing data. It can also be used to set
    the initial size of the internal buffer for writing. To do that,
    buf should have the desired capacity but a length of zero.

    In most cases, new([Buffer]) (or just declaring a [Buffer] variable) is
    sufficient to initialize a [Buffer].
    """
    var b = Bytes()
    return Buffer(b ^)


fn new_buffer(owned buf: Bytes) -> Buffer:
    """Creates and initializes a new [Buffer] using buf as its`
    initial contents. The new [Buffer] takes ownership of buf, and the
    caller should not use buf after this call. new_buffer is intended to
    prepare a [Buffer] to read existing data. It can also be used to set
    the initial size of the internal buffer for writing. To do that,
    buf should have the desired capacity but a length of zero.

    In most cases, new([Buffer]) (or just declaring a [Buffer] variable) is
    sufficient to initialize a [Buffer].
    """
    return Buffer(buf ^)


fn new_buffer_string(owned s: String) -> Buffer:
    """Creates and initializes a new [Buffer] using string s as its
    initial contents. It is intended to prepare a buffer to read an existing
    string.

    In most cases, new([Buffer]) (or just declaring a [Buffer] variable) is
    sufficient to initialize a [Buffer].
    """
    var bytes_buffer = Bytes(s.as_bytes())
    return Buffer(bytes_buffer ^)
