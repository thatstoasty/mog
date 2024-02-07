from mog.external.weave.gojo.bytes import buffer
from mog.external.weave.gojo.bytes import bytes as bt
from mog.external.weave.gojo.bytes.bytes import Byte
from mog.external.weave.ansi import writer
from mog.external.weave.ansi.ansi import is_terminator, Marker
from mog.external.weave.stdlib.builtins.string import (
    __string__mul__,
    strip,
    _ALL_WHITESPACES,
)
from mog.external.weave.stdlib.builtins.vector import contains


struct Writer:
    var buf: buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, pw: padding.Writer, iw: indent.Writer):
        var buf = DynamicVector[Byte]()
        self.buf = buffer.Buffer(buf=buf)
        self.pw = pw
        self.iw = iw

    # close will finish the margin operation. Always call it before trying to
    # retrieve the final result.
    fn close(inout self) raises:
        _ = self.pw.close()
        _ = self.buf.write(self.pw.bytes())

    # Bytes returns the result as a byte slice.
    fn bytes(self) -> DynamicVector[Byte]:
        return self.buf.bytes()

    # String returns the result as a string.
    fn string(self) -> String:
        return self.buf.string()

    fn write(inout self, b: DynamicVector[Byte]) raises -> Int:
        _ = self.iw.write(b)
        let n = self.pw.write(self.iw.bytes())

        return n


fn new_writer(width: UInt8, margin: UInt8) raises -> Writer:
    let pw = padding.new_writer(width)
    let iw = indent.new_writer(margin)

    return Writer(pw=pw, iw=iw)


# Bytes is shorthand for declaring a new default margin-writer instance,
# used to immediately apply a margin to a byte slice.
fn bytes(
    b: DynamicVector[Byte], width: UInt8, margin: UInt8
) raises -> DynamicVector[Byte]:
    var f = new_writer(width, margin)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


# String is shorthand for declaring a new default margin-writer instance,
# used to immediately apply margin a string.
fn string(s: String, width: UInt8, margin: UInt8) raises -> String:
    let buf = s._buffer
    let b = bytes(buf, width, margin)

    return bt.to_string(b)
