from external.gojo.bytes import buffer
from external.gojo.builtins._bytes import Bytes
import external.gojo.io
from .ansi import writer
from .ansi.ansi import is_terminator, Marker
from .utils import __string__mul__, strip


@value
struct Writer(StringableRaising, io.Writer):
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
    ) raises:
        self.padding = padding
        self.line_len = line_len
        self.ansi = ansi

        self.cache = buffer.new_buffer()
        self.ansi_writer = writer.new_default_writer()

    # write is used to write content to the padding buffer.
    fn write(inout self, src: Bytes) raises -> Int:
        for i in range(len(src)):
            var c = chr(int(src[i]))

            if c == Marker:
                self.ansi = True
            elif self.ansi:
                if is_terminator(src[i]):
                    self.ansi = False
            else:
                if c == "\n":
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0
                else:
                    self.line_len += len(c)

            _ = self.ansi_writer.write(Bytes(c))

        return len(src)

    fn pad(inout self) raises:
        if self.padding > 0 and UInt8(self.line_len) < self.padding:
            var padding = __string__mul__(" ", int(self.padding) - self.line_len)
            _ = self.ansi_writer.write(Bytes(padding))

    # close will finish the padding operation.
    fn close(inout self) raises:
        return self.flush()

    # Bytes returns the padded result as a byte slice.
    fn bytes(self) raises -> Bytes:
        return self.cache.bytes()

    # String returns the padded result as a string.
    fn __str__(self) raises -> String:
        return str(self.cache)

    # flush will finish the padding operation. Always call it before trying to
    # retrieve the final result.
    fn flush(inout self) raises:
        if self.line_len != 0:
            self.pad()

        self.cache.reset()
        _ = self.ansi_writer.forward.write_to(self.cache)
        self.line_len = 0
        self.ansi = False


fn new_writer(width: UInt8) raises -> Writer:
    return Writer(padding=width)


# fn NewWriterPipe(forward io.Writer, width: UInt8) -> Writer:
# 	return &Writer
# 		padding: width,
# 		Padfn: paddingfn,
# 		ansi_writer: &ansi.Writer
# 			Forward: forward,
# 		,


# Bytes is shorthand for declaring a new default padding-writer instance,
# used to immediately pad a byte slice.
fn apply_padding_to_bytes(owned b: Bytes, width: UInt8) raises -> Bytes:
    var f = new_writer(width)
    _ = f.write(b)
    _ = f.flush()

    return f.bytes()


# String is shorthand for declaring a new default padding-writer instance,
# used to immediately pad a string.
fn apply_padding(owned s: String, width: UInt8) raises -> String:
    var buf = Bytes(s)
    var b = apply_padding_to_bytes(buf ^, width)

    return str(b)
