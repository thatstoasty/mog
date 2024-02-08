from .ansi import writer
from .ansi.ansi import is_terminator, Marker
from .gojo.buffers import _buffer
from .gojo.buffers import _bytes as bt
from .gojo.stdlib_extensions.builtins import bytes
from .stdlib_extensions.builtins.string import __string__mul__, strip
from .stdlib_extensions.builtins.vector import contains


struct Writer:
    var buf: _buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, pw: padding.Writer, iw: indent.Writer):
        var buf = bytes()
        self.buf = _buffer.Buffer(buf=buf)
        self.pw = pw
        self.iw = iw

    # close will finish the margin operation. Always call it before trying to
    # retrieve the final result.
    fn close(inout self) raises:
        _ = self.pw.close()
        _ = self.buf.write(self.pw.bytes())

    # Bytes returns the result as a byte slice.
    fn bytes(self) -> bytes:
        return self.buf.bytes()

    # String returns the result as a string.
    fn string(self) -> String:
        return self.buf.string()

    fn write(inout self, b: bytes) raises -> Int:
        _ = self.iw.write(b)
        let n = self.pw.write(self.iw.bytes())

        return n


fn new_writer(width: UInt8, margin: UInt8) raises -> Writer:
    let pw = padding.new_writer(width)
    let iw = indent.new_writer(margin)

    return Writer(pw=pw, iw=iw)


# Bytes is shorthand for declaring a new default margin-writer instance,
# used to immediately apply a margin to a byte slice.
fn to_bytes(b: bytes, width: UInt8, margin: UInt8) raises -> bytes:
    var f = new_writer(width, margin)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


# String is shorthand for declaring a new default margin-writer instance,
# used to immediately apply margin a string.
fn string(s: String, width: UInt8, margin: UInt8) raises -> String:
    var buf = bt.to_bytes(s)
    let b = to_bytes(buf, width, margin)

    return bt.to_string(b)
