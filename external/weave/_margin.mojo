import external.gojo.io
from external.gojo.bytes import buffer
import . _padding as padding
import . _indent as indent


struct Writer(Stringable, io.Writer):
    var buf: buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, owned pw: padding.Writer, owned iw: indent.Writer):
        self.buf = buffer.new_buffer()
        self.pw = pw^
        self.iw = iw^

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self.buf = other.buf^
        self.pw = other.pw^
        self.iw = other.iw^

    fn close(inout self):
        """Will finish the margin operation. Always call it before trying to retrieve the final result."""
        _ = self.pw.close()
        _ = self.buf.write(self.pw.bytes())

    fn bytes(self) -> List[UInt8]:
        """Returns the result as a byte slice."""
        return self.buf.bytes()

    fn __str__(self) -> String:
        return str(self.buf)

    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        """Writes the given byte slice to the writer.
        Args:
            src: The byte slice to write.

        Returns:
            The number of bytes written and optional error.
        """
        var bytes_written = 0
        var err = Error()
        bytes_written, err = self.iw.write(src)
        if err:
            return bytes_written, err

        return self.pw.write(self.iw.bytes())


fn new_writer(width: UInt8, margin: UInt8) -> Writer:
    """Creates a new margin-writer instance.

    Args:
        width: The width of the margin.
        margin: The margin to apply.

    Returns:
        A new margin-writer instance.
    """
    return Writer(padding.new_writer(width), indent.new_writer(margin))


fn apply_margin_to_bytes(b: List[UInt8], width: UInt8, margin: UInt8) -> List[UInt8]:
    """Shorthand for declaring a new default margin-writer instance,
    used to immediately apply a margin to a byte slice.

    Args:
        b: The byte slice to apply the margin to.
        width: The width of the margin.
        margin: The margin to apply.

    Returns:
        The byte slice with the margin applied.
    """
    var f = new_writer(width, margin)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


fn margin(s: String, width: UInt8, margin: UInt8) -> String:
    """Shorthand for declaring a new default margin-writer instance,
    used to immediately apply a margin to a String.

    Args:
        s: The byte slice to apply the margin to.
        width: The width of the margin.
        margin: The margin to apply.

    Returns:
        The byte slice with the margin applied.
    """
    var buf = s.as_bytes()
    var b = apply_margin_to_bytes(buf^, width, margin)
    b.append(0)

    return String(b)
