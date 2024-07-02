from ..builtins import copy, panic
import ..io


# TODO: Maybe try a non owning reader, but I'm concerned about the lifetime of the buffer.
# Is making it unsafe a good idea? The source data would need to be ensured to outlive the reader by the user.
struct Reader(
    Sized,
    io.Reader,
    io.ReaderAt,
    io.WriterTo,
    io.Seeker,
    io.ByteReader,
    io.ByteScanner,
):
    """A Reader implements the io.Reader, io.ReaderAt, io.WriterTo, io.Seeker,
    io.ByteScanner, and io.RuneScanner Interfaces by reading from
    a byte slice.
    Unlike a [Buffer], a Reader is read-only and supports seeking.
    The zero value for Reader operates like a Reader of an empty slice.
    """

    var data: UnsafePointer[UInt8]  # contents are the bytes buf[index : size]
    var size: Int
    var capacity: Int
    var index: Int  # current reading index
    var prev_rune: Int  # index of previous rune; or < 0

    @always_inline
    fn __init__(inout self, owned buffer: List[UInt8]):
        """Initializes a new [Reader.Reader] struct."""
        self.capacity = buffer.capacity
        self.size = buffer.size
        self.data = buffer.steal_data()
        self.index = 0
        self.prev_rune = -1

    @always_inline
    fn __moveinit__(inout self, owned other: Reader):
        """Initializes a new [Reader.Reader] struct by moving the data from another [Reader.Reader] struct."""
        self.capacity = other.capacity
        self.size = other.size
        self.data = other.data
        self.index = other.index
        self.prev_rune = other.prev_rune

        other.data = UnsafePointer[UInt8]()
        other.size = 0
        other.capacity = 0
        other.index = 0
        other.prev_rune = -1

    @always_inline
    fn __len__(self) -> Int:
        """len returns the number of bytes of the unread portion of the
        slice."""
        return self.size - int(self.index)

    @always_inline
    fn __del__(owned self):
        if self.data:
            self.data.free()

    @always_inline
    fn as_bytes_slice(self: Reference[Self]) -> Span[UInt8, self.is_mutable, self.lifetime]:
        """Returns the internal data as a Span[UInt8]."""
        return Span[UInt8, self.is_mutable, self.lifetime](unsafe_ptr=self[].data, len=self[].size)

    @always_inline
    fn _read(inout self, inout dest: Span[UInt8, True], capacity: Int) -> (Int, Error):
        """Reads from the internal buffer into the dest List[UInt8] struct.
        Implements the [io.Reader] Interface.

        Args:
            dest: The destination Span[UInt8] struct to read into.
            capacity: The capacity of the destination buffer.

        Returns:
            Int: The number of bytes read into dest."""

        if self.index >= self.size:
            return 0, io.EOF

        # Copy the data of the internal buffer from offset to len(buf) into the destination buffer at the given index.
        self.prev_rune = -1
        var bytes_written = copy(dest, self.as_bytes_slice()[self.index : self.size], len(dest))
        dest._len += bytes_written
        self.index += bytes_written

        return bytes_written, Error()

    @always_inline
    fn read(inout self, inout dest: List[UInt8]) -> (Int, Error):
        """Reads from the internal buffer into the dest List[UInt8] struct.
        Implements the [io.Reader] Interface.

        Args:
            dest: The destination List[UInt8] struct to read into.

        Returns:
            Int: The number of bytes read into dest."""
        var span = Span(dest)

        var bytes_read: Int
        var err: Error
        bytes_read, err = self._read(span, dest.capacity)
        dest.size += bytes_read

        return bytes_read, err

    @always_inline
    fn _read_at(self, inout dest: Span[UInt8, True], off: Int, capacity: Int) -> (Int, Error):
        """Reads len(dest) bytes into dest beginning at byte offset off.
        Implements the [io.ReaderAt] Interface.

        Args:
            dest: The destination List[UInt8] struct to read into.
            off: The offset to start reading from.

        Returns:
            Int: The number of bytes read into dest.
        """
        # cannot modify state - see io.ReaderAt
        if off < 0:
            return 0, Error("bytes.Reader.read_at: negative offset")

        if off >= Int(self.size):
            return 0, io.EOF

        var unread_bytes = self.as_bytes_slice()[off : self.size]
        var bytes_written = copy(dest, unread_bytes)
        if bytes_written < len(dest):
            return 0, io.EOF

        return bytes_written, Error()

    @always_inline
    fn read_at(self, inout dest: List[UInt8], off: Int) -> (Int, Error):
        """Reads len(dest) bytes into dest beginning at byte offset off.
        Implements the [io.ReaderAt] Interface.

        Args:
            dest: The destination List[UInt8] struct to read into.
            off: The offset to start reading from.

        Returns:
            Int: The number of bytes read into dest.
        """
        var span = Span(dest)

        var bytes_read: Int
        var err: Error
        bytes_read, err = self._read_at(span, off, dest.capacity)
        dest.size += bytes_read

        return bytes_read, err

    @always_inline
    fn read_byte(inout self) -> (UInt8, Error):
        """Reads and returns a single byte from the internal buffer. Implements the [io.ByteReader] Interface."""
        self.prev_rune = -1
        if self.index >= self.size:
            return UInt8(0), io.EOF

        var byte = self.data[self.index]
        self.index += 1
        return byte, Error()

    @always_inline
    fn unread_byte(inout self) -> Error:
        """Unreads the last byte read by moving the read position back by one.
        Complements [Reader.read_byte] in implementing the [io.ByteScanner] Interface.
        """
        if self.index <= 0:
            return Error("bytes.Reader.unread_byte: at beginning of slice")

        self.prev_rune = -1
        self.index -= 1

        return Error()

    # # read_rune implements the [io.RuneReader] Interface.
    # fn read_rune(self) (ch rune, size Int, err error):
    #     if self.index >= Int(self.size):
    #         self.prev_rune = -1
    #         return 0, 0, io.EOF

    #     self.prev_rune = Int(self.index)
    #     if c := self.buffer[self.index]; c < utf8.RuneSelf:
    #         self.index+= 1
    #         return rune(c), 1, nil

    #     ch, size = utf8.DecodeRune(self.buffer[self.index:])
    #     self.index += Int(size)
    #     return

    # # unread_rune complements [Reader.read_rune] in implementing the [io.RuneScanner] Interface.
    # fn unread_rune(self) error:
    #     if self.index <= 0:
    #         return errors.New("bytes.Reader.unread_rune: at beginning of slice")

    #     if self.prev_rune < 0:
    #         return errors.New("bytes.Reader.unread_rune: previous operation was not read_rune")

    #     self.index = Int(self.prev_rune)
    #     self.prev_rune = -1
    #     return nil

    @always_inline
    fn seek(inout self, offset: Int, whence: Int) -> (Int, Error):
        """Moves the read position to the specified offset from the specified whence.

        Args:
            offset: The offset to move to.
            whence: The reference point for offset.

        Returns:
            The new position in which the next read will start from.
        """
        self.prev_rune = -1
        var position: Int = 0

        if whence == io.SEEK_START:
            position = offset
        elif whence == io.SEEK_CURRENT:
            position = self.index + offset
        elif whence == io.SEEK_END:
            position = self.size + offset
        else:
            return Int(0), Error("bytes.Reader.seek: invalid whence")

        if position < 0:
            return Int(0), Error("bytes.Reader.seek: negative position")

        self.index = position
        return position, Error()

    @always_inline
    fn write_to[W: io.Writer](inout self, inout writer: W) -> (Int, Error):
        """Writes data to w until the buffer is drained or an error occurs.
        implements the [io.WriterTo] Interface.

        Args:
            writer: The writer to write to.
        """
        self.prev_rune = -1
        if self.index >= self.size:
            return 0, Error()

        var bytes = self.as_bytes_slice()[self.index : self.size]
        var write_count: Int
        var err: Error
        write_count, err = writer.write(bytes)
        if write_count > len(bytes):
            panic("bytes.Reader.write_to: invalid Write count")

        self.index += write_count
        if write_count != len(bytes):
            return write_count, io.ERR_SHORT_WRITE

        return write_count, Error()

    @always_inline
    fn reset(inout self, owned buffer: List[UInt8]):
        """Resets the [Reader.Reader] to be reading from buffer.

        Args:
            buffer: The new buffer to read from.
        """
        self.capacity = buffer.capacity
        self.size = buffer.size
        self.data = buffer.steal_data()
        self.index = 0
        self.prev_rune = -1


fn new_reader(owned buffer: List[UInt8]) -> Reader:
    """Returns a new [Reader.Reader] reading from b.

    Args:
        buffer: The new buffer to read from.

    """
    return Reader(buffer)


fn new_reader(owned buffer: String) -> Reader:
    """Returns a new [Reader.Reader] reading from b.

    Args:
        buffer: The new buffer to read from.

    """
    return Reader(buffer.as_bytes())
