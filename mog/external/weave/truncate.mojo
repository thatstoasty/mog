from mog.external.weave.gojo.bytes import buffer
from mog.external.weave.gojo.bytes import bytes as bt
from mog.external.weave.gojo.bytes.bytes import Byte
from mog.external.weave.ansi import writer
from mog.external.weave.ansi.ansi import is_terminator, Marker, printable_rune_width
from mog.external.weave.stdlib.builtins.string import __string__mul__, strip
from mog.external.weave.stdlib.builtins.vector import contains


struct Writer:
    var width: UInt8
    var tail: String

    var ansi_writer: writer.Writer
    var buf: buffer.Buffer
    var ansi: Bool

    fn __init__(inout self, width: UInt8, tail: String, ansi: Bool = False) raises:
        self.width = width
        self.tail = tail
        self.ansi = ansi

        var buf = DynamicVector[Byte]()
        self.buf = buffer.Buffer(buf=buf)

        # I think it's copying the buffer for now instead of using the actual buffer
        self.ansi_writer = writer.Writer(self.buf)

    # write truncates content at the given printable cell width, leaving any
    # ansi sequences intact.
    fn write(inout self, b: DynamicVector[Byte]) raises -> Int:
        # TODO: Normally rune length
        let tw = printable_rune_width(self.tail)
        if self.width < UInt8(tw):
            return self.ansi_writer.forward.write_string(self.tail)

        self.width -= UInt8(tw)
        var cur_width: UInt8 = 0

        for i in range(len(b)):
            let c = chr(int(b[i]))
            if c == Marker:
                # ANSI escape sequence
                self.ansi = True
            elif self.ansi:
                if is_terminator(b[i]):
                    # ANSI sequence terminated
                    self.ansi = False
            else:
                cur_width += UInt8(len(c))

            if cur_width > self.width:
                let n = self.ansi_writer.forward.write_string(self.tail)
                if self.ansi_writer.last_sequence() != "":
                    self.ansi_writer.reset_ansi()
                return n

            _ = self.ansi_writer.write_byte(b[i])

        return len(b)

    # Bytes returns the truncated result as a byte slice.
    fn bytes(self) -> DynamicVector[Byte]:
        return self.ansi_writer.forward.bytes()

    # String returns the truncated result as a string.
    fn string(self) -> String:
        return self.ansi_writer.forward.string()


fn new_writer(width: UInt8, tail: String) raises -> Writer:
    return Writer(width, tail)


# fn NewWriterPipe(forward io.Writer, width: UInt8, tail string)-> Writer:
# 	return &Writer
# 		width: width,
# 		tail:  tail,
# 		ansi_writer: &ansi.Writer
# 			Forward: forward,
# 		,


# Bytes is shorthand for declaring a new default truncate-writer instance,
# used to immediately truncate a byte slice.
fn bytes(b: DynamicVector[Byte], width: UInt8) raises -> DynamicVector[Byte]:
    let tail = DynamicVector[Byte]()
    return bytes_with_tail(b, width, tail)


# Bytes is shorthand for declaring a new default truncate-writer instance,
# used to immediately truncate a byte slice. A tail is then added to the
# end of the byte slice.
fn bytes_with_tail(
    b: DynamicVector[Byte], width: UInt8, tail: DynamicVector[Byte]
) raises -> DynamicVector[Byte]:
    var f = new_writer(width, bt.to_string(tail))
    _ = f.write(b)

    return f.bytes()


# String is shorthand for declaring a new default truncate-writer instance,
# used to immediately truncate a string.
fn string(s: String, width: UInt8) raises -> String:
    return string_with_tail(s, width, "")


# string_with_tail is shorthand for declaring a new default truncate-writer instance,
# used to immediately truncate a string. A tail is then added to the end of the
# string.
fn string_with_tail(s: String, width: UInt8, tail: String) raises -> String:
    let buf = s._buffer
    let b = bytes_with_tail(buf, width, tail._buffer)
    return bt.to_string(b)
