from stormlight.weave.gojo.bytes import buffer
from stormlight.weave.gojo.bytes import bytes as bt
from stormlight.weave.gojo.bytes.bytes import Byte
from stormlight.weave.ansi import writer
from stormlight.weave.ansi.ansi import is_terminator, Marker
from stormlight.weave.stdlib.builtins.string import __string__mul__, strip
from stormlight.weave.stdlib.builtins.vector import contains


@value
struct Writer:
    var padding: UInt8

    var ansi_writer: writer.Writer
    var buf: buffer.Buffer
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

        var buf = DynamicVector[Byte]()
        self.buf = buffer.Buffer(buf=buf)

        var cache = DynamicVector[Byte]()
        self.cache = buffer.Buffer(buf=cache)

        # This copies the buffer? I should probably try redoing this all with proper pointers
        self.ansi_writer = writer.Writer(self.buf)

    # write is used to write content to the padding buffer.
    fn write(inout self, b: DynamicVector[Byte]) raises -> Int:
        for i in range(len(b)):
            let c = chr(int(b[i]))

            if c == Marker:
                self.ansi = True
            elif self.ansi:
                if is_terminator(b[i]):
                    self.ansi = False
            else:
                self.line_len += len(c)

                if c == "\n":
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0

            _ = self.ansi_writer.write(c._buffer)

        return len(b)

    fn pad(inout self) raises:
        if self.padding > 0 and UInt8(self.line_len) < self.padding:
            let padding = __string__mul__(" ", int(self.padding) - self.line_len)
            _ = self.ansi_writer.write(padding._buffer)

    # close will finish the padding operation.
    fn close(inout self) raises:
        return self.flush()

    # Bytes returns the padded result as a byte slice.
    fn bytes(self) -> DynamicVector[Byte]:
        return self.cache.bytes()

    # String returns the padded result as a string.
    fn string(self) -> String:
        return self.cache.string()

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
fn bytes(
    b: DynamicVector[Byte], width: UInt8) raises -> DynamicVector[Byte]:
    var f = new_writer(width)
    _ = f.write(b)
    _ = f.flush()

    return f.bytes()


# String is shorthand for declaring a new default padding-writer instance,
# used to immediately pad a string.
fn to_string(s: String, width: UInt8) raises -> String:
    let buf = s._buffer
    let b = bytes(buf, width)

    return bt.to_string(b)
