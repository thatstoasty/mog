from external.gojo.bytes import buffer
from external.gojo.builtins.bytes import Byte
from external.gojo.builtins import Result
import external.gojo.io
from weave.ansi import writer
from weave.ansi.ansi import is_terminator
from weave.utils import __string__mul__


@value
struct Writer(Stringable, io.Writer):
    var indent: UInt8

    var ansi_writer: writer.Writer
    var skip_indent: Bool
    var ansi: Bool

    fn __init__(inout self, indent: UInt8):
        self.indent = indent

        self.ansi_writer = writer.new_default_writer()
        self.skip_indent = False
        self.ansi = False

    # List[Byte] returns the indented result as a byte slice.
    fn bytes(self) -> List[Byte]:
        return self.ansi_writer.forward.bytes()

    # String returns the indented result as a string.
    fn __str__(self) -> String:
        return str(self.ansi_writer.forward)

    # write is used to write content to the indent buffer.
    fn write(inout self, src: List[Byte]) -> Result[Int]:
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
                    var indent = __string__mul__(
                        String(" "), int(self.indent)
                    ).as_bytes()
                    _ = self.ansi_writer.write(indent)

                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                if c == "\n":
                    # end of current line
                    self.skip_indent = False

            _ = self.ansi_writer.write(c.as_bytes())

        return len(src)


fn new_writer(indent: UInt8) -> Writer:
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


# List[Byte] is shorthand for declaring a new default indent-writer instance,
# used to immediately indent a byte slice.
fn apply_indent_to_bytes(
    owned b: List[Byte], indent: UInt8
) raises -> List[Byte]:
    var f = new_writer(indent)
    _ = f.write(b)

    return f.bytes()


# String is shorthand for declaring a new default indent-writer instance,
# used to immediately indent a string.
fn apply_indent(owned s: String, indent: UInt8) raises -> String:
    var buf = s.as_bytes()
    var b = apply_indent_to_bytes(buf^, indent)
    b.append(0)

    return String(b)
