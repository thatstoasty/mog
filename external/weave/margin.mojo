from external.gojo.bytes import buffer
from external.gojo.builtins.bytes import Byte
from external.gojo.builtins import Result
import external.gojo.io
from .ansi import writer
from .ansi.ansi import is_terminator, Marker
from .utils import __string__mul__, strip


@value
struct Writer(Stringable, io.Writer):
    var buf: buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, inout pw: padding.Writer, inout iw: indent.Writer):
        self.buf = buffer.new_buffer()
        self.pw = pw
        self.iw = iw

    # close will finish the margin operation. Always call it before trying to
    # retrieve the final result.
    fn close(inout self):
        _ = self.pw.close()
        _ = self.buf.write(self.pw.bytes())

    # List[Byte] returns the result as a byte slice.
    fn bytes(self) -> List[Byte]:
        return self.buf.bytes()

    # String returns the result as a string.
    fn __str__(self) -> String:
        return str(self.buf)

    fn write(inout self, src: List[Byte]) -> Result[Int]:
        _ = self.iw.write(src)
        var n = self.pw.write(self.iw.bytes())

        return n


fn new_writer(width: UInt8, margin: UInt8) -> Writer:
    var pw = padding.new_writer(width)
    var iw = indent.new_writer(margin)

    return Writer(pw, iw)


# List[Byte] is shorthand for declaring a new default margin-writer instance,
# used to immediately apply a margin to a byte slice.
fn apply_margin_to_bytes(
    owned b: List[Byte], width: UInt8, margin: UInt8
) -> List[Byte]:
    var f = new_writer(width, margin)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


# String is shorthand for declaring a new default margin-writer instance,
# used to immediately apply margin a string.
fn apply_margin(owned s: String, width: UInt8, margin: UInt8) -> String:
    var buf = s.as_bytes()
    var b = apply_margin_to_bytes(buf ^, width, margin)
    b.append(0)

    return String(b)
