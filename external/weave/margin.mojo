from external.gojo.bytes import buffer
from external.gojo.builtins._bytes import Bytes
import external.gojo.io
from .ansi import writer
from .ansi.ansi import is_terminator, Marker
from .utils import __string__mul__, strip


@value
struct Writer(StringableRaising, io.Writer):
    var buf: buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, inout pw: padding.Writer, inout iw: indent.Writer):
        self.buf = buffer.new_buffer()
        self.pw = pw
        self.iw = iw

    # close will finish the margin operation. Always call it before trying to
    # retrieve the final result.
    fn close(inout self) raises:
        _ = self.pw.close()
        _ = self.buf.write(self.pw.bytes())

    # Bytes returns the result as a byte slice.
    fn bytes(self) raises -> Bytes:
        return self.buf.bytes()

    # String returns the result as a string.
    fn __str__(self) raises -> String:
        return str(self.buf)

    fn write(inout self, src: Bytes) raises -> Int:
        _ = self.iw.write(src)
        var n = self.pw.write(self.iw.bytes())

        return n


fn new_writer(width: UInt8, margin: UInt8) raises -> Writer:
    var pw = padding.new_writer(width)
    var iw = indent.new_writer(margin)

    return Writer(pw, iw)


# Bytes is shorthand for declaring a new default margin-writer instance,
# used to immediately apply a margin to a byte slice.
fn apply_margin_to_bytes(owned b: Bytes, width: UInt8, margin: UInt8) raises -> Bytes:
    var f = new_writer(width, margin)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


# String is shorthand for declaring a new default margin-writer instance,
# used to immediately apply margin a string.
fn apply_margin(owned s: String, width: UInt8, margin: UInt8) raises -> String:
    var buf = Bytes(s)
    var b = apply_margin_to_bytes(buf ^, width, margin)

    return str(b)
