from external.gojo.bytes import buffer
from external.gojo.builtins._bytes import Bytes
import external.gojo.io
from weave.ansi import writer
from weave.ansi.ansi import is_terminator
from weave.utils import __string__mul__


@value
struct Writer(StringableRaising, io.Writer):
    var indent: UInt8

    var ansi_writer: writer.Writer
    var skip_indent: Bool
    var ansi: Bool

    fn __init__(inout self, indent: UInt8) raises:
        self.indent = indent

        self.ansi_writer = writer.new_default_writer()
        self.skip_indent = False
        self.ansi = False

    # Bytes returns the indented result as a byte slice.
    fn bytes(self) raises -> Bytes:
        return self.ansi_writer.forward.bytes()

    # String returns the indented result as a string.
    fn __str__(self) raises -> String:
        return str(self.ansi_writer.forward)

    # write is used to write content to the indent buffer.
    fn write(inout self, src: Bytes) raises -> Int:
        for i in range(len(src)):
            var c = chr(int(src[i]))
            if c == "\x1B":
                # ANSI escape sequence
                self.ansi = True
            elif self.ansi:
                if is_terminator(src[i]):
                    # ANSI sequence terminated
                    self.ansi = False
            else:
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    var indent = Bytes(__string__mul__(String(" "), int(self.indent)))
                    _ = self.ansi_writer.write(indent)

                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                if c == "\n":
                    # end of current line
                    self.skip_indent = False

            _ = self.ansi_writer.write(Bytes(c))

        return len(src)


fn new_writer(indent: UInt8) raises -> Writer:
    return Writer(
        indent=indent,
    )


# fn NewWriterPipe(forward io.Writer, indent UInt8, indent_fn Indentfn)-> Writer:
# 	return &Writer
# 		Indent:     indent,
# 		Indentfn: indent_fn,
# 		ansi_writer: &ansi.Writer
# 			Forward: forward,
# 		,
#
#


# Bytes is shorthand for declaring a new default indent-writer instance,
# used to immediately indent a byte slice.
fn apply_indent_to_bytes(owned b: Bytes, indent: UInt8) raises -> Bytes:
    var f = new_writer(indent)
    _ = f.write(b)

    return f.bytes()


# String is shorthand for declaring a new default indent-writer instance,
# used to immediately indent a string.
fn apply_indent(owned s: String, indent: UInt8) raises -> String:
    var buf = Bytes(s)
    var b = apply_indent_to_bytes(buf ^, indent)

    return str(b)
