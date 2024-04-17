from math.bit import ctlz
from external.gojo.bytes import buffer
from external.gojo.builtins import Byte
import external.gojo.io
from .ansi import writer, is_terminator, Marker
from .strings import repeat


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

    fn bytes(self) -> List[Byte]:
        """Returns the indented result as a byte slice."""
        return self.ansi_writer.forward.bytes()

    fn __str__(self) -> String:
        return str(self.ansi_writer.forward)

    fn write(inout self, src: List[Byte]) -> (Int, Error):
        """Writes the given byte slice to the writer.

        Args:
            src: The byte slice to write.

        Returns:
            The number of bytes written and optional error.
        """
        var err = Error()
        # Rune iterator
        var bytes = len(src)
        var p = DTypePointer[DType.int8](src.data).bitcast[DType.uint8]()
        while bytes > 0:
            var char_length = int((p.load() >> 7 == 0).cast[DType.uint8]() * 1 + ctlz(~p.load()))
            var sp = DTypePointer[DType.int8].alloc(char_length + 1)
            memcpy(sp, p.bitcast[DType.int8](), char_length)
            sp[char_length] = 0

            # Functional logic
            var char = String(sp, char_length + 1)
            if char == Marker:
                # ANSI escape sequence
                self.ansi = True
            elif self.ansi:
                if is_terminator(ord(char)):
                    # ANSI sequence terminated
                    self.ansi = False
            else:
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    var indent = repeat(" ", int(self.indent)).as_bytes()

                    var bytes_written = 0
                    bytes_written, err = self.ansi_writer.write(indent)
                    if err:
                        return bytes_written, err

                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                if char == "\n":
                    # end of current line
                    self.skip_indent = False

            var bytes_written = 0
            bytes_written, err = self.ansi_writer.write(char.as_bytes())
            if err:
                return bytes_written, err

            # Move iterator forward
            bytes -= char_length
            p += char_length

        return len(src), err


fn new_writer(indent: UInt8) -> Writer:
    """Creates a new indent-writer instance with the given indent level.

    Args:
        indent: The number of spaces to indent.
    """
    return Writer(indent=indent)


# fn NewWriterPipe(forward io.Writer, indent UInt8, indent_fn Indentfn)-> Writer:
# 	return &Writer
# 		Indent:     indent,
# 		Indentfn: indent_fn,
# 		ansi_writer: &ansi.Writer
# 			Forward: forward,
# 		,
#
#


fn apply_indent_to_bytes(b: List[Byte], indent: UInt8) -> List[Byte]:
    """Shorthand for declaring a new default indent-writer instance, used to immediately indent a byte slice.

    Args:
        b: The byte slice to indent.
        indent: The number of spaces to indent.

    Returns:
        The indented byte slice.
    """
    var f = new_writer(indent)
    _ = f.write(b)

    return f.bytes()


fn apply_indent(s: String, indent: UInt8) -> String:
    """Shorthand for declaring a new default indent-writer instance,
    used to immediately indent a string.

    Args:
        s: The string to indent.
        indent: The number of spaces to indent.

    Returns:
        The indented string.
    """
    var buf = s.as_bytes()
    var b = apply_indent_to_bytes(buf^, indent)
    b.append(0)

    return String(b)
