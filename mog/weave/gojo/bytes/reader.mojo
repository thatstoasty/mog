from collections.optional import Optional
from ..builtins import cap, copy
from ..builtins._bytes import Bytes, Byte
import ..io.traits as io


# A Reader implements the io.Reader, io.ReaderAt, io.WriterTo, io.Seeker,
# io.ByteScanner, and io.RuneScanner Interfaces by reading from
# a byte slice.
# Unlike a [Buffer], a Reader is read-only and supports seeking.
# The zero value for Reader operates like a Reader of an empty slice.
@value
struct Reader(
    io.Reader, io.ReaderAt, io.WriterTo, io.Seeker, io.ByteReader, io.ByteScanner
):
    var s: Bytes
    var index: Int64  # current reading index
    var prev_rune: Int  # index of previous rune; or < 0

    # Len returns the number of bytes of the unread portion of the
    # slice.
    fn len(self) -> Int64:
        if self.index >= len(self.s):
            return 0

        return Int64(len(self.s) - self.index)

    # Size returns the original length of the underlying byte slice.
    # Size is the number of bytes available for reading via [Reader.ReadAt].
    # The result is unaffected by any method calls except [Reader.Reset].
    fn size(self) -> Int:
        return len(self.s)

    # Read implements the [io.Reader] Interface.
    fn read(inout self, inout dest: Bytes) raises -> Int:
        if self.index >= len(self.s):
            raise Error("EOF")

        self.prev_rune = -1
        var unread_bytes = self.s[int(self.index) :]
        var n = copy(dest, unread_bytes)

        self.index += n
        return n

    # ReadAt implements the [io.ReaderAt] Interface.
    fn read_at(self, inout dest: Bytes, off: Int64) raises -> Int:
        # cannot modify state - see io.ReaderAt
        if off < 0:
            raise Error("bytes.Reader.ReadAt: negative offset")

        if off >= Int64(len(self.s)):
            raise Error("EOF")

        var unread_bytes = self.s[int(off) :]
        var n = copy(dest, unread_bytes)
        if n < len(dest):
            raise Error("EOF")

        return n

    # ReadByte implements the [io.ByteReader] Interface.
    fn read_byte(inout self) raises -> Byte:
        self.prev_rune = -1
        if self.index >= len(self.s):
            raise Error("EOF")

        var byte = self.s[int(self.index)]
        self.index += 1
        return byte

    # UnreadByte complements [Reader.ReadByte] in implementing the [io.ByteScanner] Interface.
    fn unread_byte(inout self) raises:
        if self.index <= 0:
            raise Error("bytes.Reader.UnreadByte: at beginning of slice")

        self.prev_rune = -1
        self.index -= 1

    # # ReadRune implements the [io.RuneReader] Interface.
    # fn read_rune(self) (ch rune, size Int, err error):
    #     if self.index >= Int64(len(self.s)):
    #         self.prev_rune = -1
    #         return 0, 0, io.EOF

    #     self.prev_rune = Int(self.index)
    #     if c := self.s[self.index]; c < utf8.RuneSelf:
    #         self.index+= 1
    #         return rune(c), 1, nil

    #     ch, size = utf8.DecodeRune(self.s[self.index:])
    #     self.index += Int64(size)
    #     return

    # # UnreadRune complements [Reader.ReadRune] in implementing the [io.RuneScanner] Interface.
    # fn unread_rune(self) error:
    #     if self.index <= 0:
    #         return errors.New("bytes.Reader.UnreadRune: at beginning of slice")

    #     if self.prev_rune < 0:
    #         return errors.New("bytes.Reader.UnreadRune: previous operation was not ReadRune")

    #     self.index = Int64(self.prev_rune)
    #     self.prev_rune = -1
    #     return nil

    # Seek implements the [io.Seeker] Interface.
    fn seek(inout self, offset: Int64, whence: Int) raises -> Int:
        self.prev_rune = -1
        var abs: Int64 = 0

        if whence == io.seek_start:
            abs = offset
        elif whence == io.seek_current:
            abs = self.index + offset
        elif whence == io.seek_end:
            abs = len(self.s) + offset
        else:
            raise Error("bytes.Readeself.seek: invalid whence")

        if abs < 0:
            raise Error("bytes.Readeself.seek: negative position")

        self.index = abs
        return int(abs)

    # WriteTo implements the [io.WriterTo] Interface.
    fn write_to[W: io.Writer](inout self, inout w: W) raises -> Int64:
        self.prev_rune = -1
        if self.index >= len(self.s):
            return 0

        var b = self.s[int(self.index) :]
        var write_count = w.write(b)
        if write_count > len(b):
            raise Error("bytes.Reader.WriteTo: invalid Write count")

        self.index += write_count
        if write_count != len(b):
            raise Error(io.ErrShortWrite)

        return Int64(write_count)

    # Reset resets the [Reader.Reader] to be reading from b.
    fn reset(inout self, b: Bytes):
        self.s = b
        self.index = 0
        self.prev_rune = -1


# NewReader returns a new [Reader.Reader] reading from b.
fn new_reader(b: Bytes) -> Reader:
    return Reader(b, 0, -1)
