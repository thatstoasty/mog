from external.gojo.bytes import buffer
from external.gojo.builtins import Result, Byte
import external.gojo.io
from .ansi import writer, is_terminator, Marker
from .strings import repeat, strip


@value
struct Writer(Stringable, io.Writer):
    var buf: buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, owned pw: padding.Writer, owned iw: indent.Writer):
        self.buf = buffer.new_buffer()
        self.pw = pw^
        self.iw = iw^

    fn close(inout self):
        """Will finish the margin operation. Always call it before trying to retrieve the final result.
        """
        _ = self.pw.close()
        _ = self.buf.write(self.pw.bytes())

    fn bytes(self) -> List[Byte]:
        """Returns the result as a byte slice."""
        return self.buf.bytes()

    fn __str__(self) -> String:
        return str(self.buf)

    fn write(inout self, src: List[Byte]) -> Result[Int]:
        """Writes the given byte slice to the writer.
        Args:
            src: The byte slice to write.

        Returns:
            The number of bytes written and optional error.
        """
        var result = self.iw.write(src)
        if result.error:
            return result

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


fn apply_margin_to_bytes(
    b: List[Byte], width: UInt8, margin: UInt8
) -> List[Byte]:
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


fn apply_margin(s: String, width: UInt8, margin: UInt8) -> String:
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
