from .ansi import writer
from .ansi.ansi import is_terminator, Marker
from .gojo.buffers import _buffer
from .gojo.buffers import _bytes as bt
from .gojo.stdlib_extensions.builtins import bytes
from .stdlib_extensions.builtins.string import __string__mul__, strip
from .stdlib_extensions.builtins.vector import contains


@value
struct Writer:
    var padding: UInt8

    var ansi_writer: writer.Writer
    var buf: _buffer.Buffer
    var cache: _buffer.Buffer
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

        var buf = bytes()
        self.buf = _buffer.Buffer(buf=buf)

        var cache = bytes()
        self.cache = _buffer.Buffer(buf=cache)

        # This copies the buffer? I should probably try redoing this all with proper pointers
        self.ansi_writer = writer.Writer(self.buf)

    # write is used to write content to the padding buffer.
    fn write(inout self, b: bytes) raises -> Int:
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

            _ = self.ansi_writer.write(bt.to_bytes(c))

        return len(b)

    fn pad(inout self) raises:
        if self.padding > 0 and UInt8(self.line_len) < self.padding:
            let padding = __string__mul__(" ", int(self.padding) - self.line_len)
            _ = self.ansi_writer.write(bt.to_bytes(padding))

    # close will finish the padding operation.
    fn close(inout self) raises:
        return self.flush()

    # Bytes returns the padded result as a byte slice.
    fn bytes(self) -> bytes:
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
fn to_bytes(b: bytes, width: UInt8) raises -> bytes:
    var f = new_writer(width)
    _ = f.write(b)
    _ = f.flush()

    return f.bytes()


# String is shorthand for declaring a new default padding-writer instance,
# used to immediately pad a string.
fn string(s: String, width: UInt8) raises -> String:
    var buf = bt.to_bytes(s)
    let b = to_bytes(buf, width)

    return bt.to_string(b)
