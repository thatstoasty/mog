from math.bit import ctlz
from external.gojo.bytes import buffer
from external.gojo.builtins import Byte
import external.gojo.io
from .ansi import writer, is_terminator, Marker, printable_rune_width
from .strings import repeat, strip


@value
struct Writer(Stringable, io.Writer):
    var padding: UInt8

    var ansi_writer: writer.Writer
    var cache: buffer.Buffer
    var line_len: Int
    var ansi: Bool

    fn __init__(
        inout self,
        padding: UInt8,
        line_len: Int = 0,
        ansi: Bool = False,
    ):
        self.padding = padding
        self.line_len = line_len
        self.ansi = ansi

        self.cache = buffer.new_buffer()
        self.ansi_writer = writer.new_default_writer()

    fn write(inout self, src: List[Byte]) -> (Int, Error):
        """Pads content to the given printable cell width.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        var err = Error()
        # Rune iterator
        var bytes = len(src)
        var p = DTypePointer[DType.int8](src.data).bitcast[DType.uint8]()
        while bytes > 0:
            var char_length = int((p.load() >> 7 == 0).cast[DType.uint8]() * 1 + ctlz(~p.load()))
            var sp = DTypePointer[DType.int8].alloc(char_length + 1)
            memcpy(sp, p.bitcast[DType.int8](), char_length)
            sp[char_length] = 0

            # Functional logic
            var char = String(sp, char_length + 1)
            if char == Marker:
                self.ansi = True
            elif self.ansi:
                if is_terminator(ord(char)):
                    self.ansi = False
            else:
                if char == "\n":
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0
                else:
                    self.line_len += printable_rune_width(char)

            var bytes_written = 0

            bytes_written, err = self.ansi_writer.write(char.as_bytes())
            if err:
                return bytes_written, err

            # Move iterator forward
            bytes -= char_length
            p += char_length

        return len(src), err

    fn pad(inout self):
        """Pads the current line with spaces to the given width."""
        if self.padding > 0 and UInt8(self.line_len) < self.padding:
            var padding = repeat(" ", int(self.padding) - self.line_len)
            _ = self.ansi_writer.write(padding.as_bytes())

    fn close(inout self):
        """Finishes the padding operation."""
        return self.flush()

    fn bytes(self) -> List[Byte]:
        """Returns the padded result as a byte slice."""
        return self.cache.bytes()

    fn __str__(self) -> String:
        return str(self.cache)

    fn flush(inout self):
        """Finishes the padding operation. Always call it before trying to retrieve the final result."""
        if self.line_len != 0:
            self.pad()

        self.cache.reset()
        _ = self.ansi_writer.forward.write_to(self.cache)
        self.line_len = 0
        self.ansi = False


fn new_writer(width: UInt8) -> Writer:
    """Creates a new padding writer instance.

    Args:
        width: The padding width.

    Returns:
        A new padding writer instance.
    """
    return Writer(padding=width)


# fn NewWriterPipe(forward io.Writer, width: UInt8) -> Writer:
# 	return &Writer
# 		padding: width,
# 		Padfn: paddingfn,
# 		ansi_writer: &ansi.Writer
# 			Forward: forward,
# 		,


fn apply_padding_to_bytes(b: List[Byte], width: UInt8) -> List[Byte]:
    """Pads a byte slice to the given printable cell width.

    Args:
        b: The byte slice to pad.
        width: The padding width.

    Returns:
        The padded byte slice.
    """
    var f = new_writer(width)
    _ = f.write(b)
    _ = f.flush()

    return f.bytes()


fn apply_padding(s: String, width: UInt8) -> String:
    """Shorthand for declaring a new default padding-writer instance, used to immediately pad a string.

    Args:
        s: The string to pad.
        width: The padding width.

    Returns:
        The padded string.
    """
    var buf = s.as_bytes()
    var b = apply_padding_to_bytes(buf^, width)
    b.append(0)

    return String(b)
