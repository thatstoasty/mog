from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString
import .ansi


struct Writer(Stringable, Movable):
    """A writer that indents content by a given number of spaces.

    Example Usage:
    ```mojo
    from weave import _indent as indent

    fn main():
        var writer = indent.Writer(4)
        _ = writer.write("Hello, World!".as_bytes_slice())
        print(String(writer.as_string_slice()))
    ```
    """

    var indent: UInt8
    """The number of spaces to indent each line."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores the text content."""
    var skip_indent: Bool
    """Whether to skip the indentation for the next line."""
    var in_ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(inout self, indent: UInt8):
        """Initializes a new indent-writer instance.

        Args:
            indent: The number of spaces to indent each line.
        """
        self.indent = indent
        self.ansi_writer = ansi.Writer()
        self.skip_indent = False
        self.in_ansi = False

    fn __moveinit__(inout self, owned other: Self):
        self.indent = other.indent
        self.ansi_writer = other.ansi_writer^
        self.skip_indent = other.skip_indent
        self.in_ansi = other.in_ansi

    fn __str__(self) -> String:
        return str(self.ansi_writer.forward)

    fn as_bytes(self) -> List[UInt8]:
        """Returns the indented result as a byte list."""
        return self.ansi_writer.forward.bytes()

    fn as_bytes_slice(self: Reference[Self]) -> Span[UInt8, self.is_mutable, self.lifetime]:
        """Returns the indented result as a byte slice."""
        return self[].ansi_writer.forward.as_bytes_slice()

    fn as_string_slice(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """Returns the indented result as a string slice."""
        return StringSlice(unsafe_from_utf8=self[].ansi_writer.forward.as_bytes_slice())

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Writes the given byte slice to the writer.

        Args:
            src: The byte slice to write.

        Returns:
            The number of bytes written and optional error.
        """
        var err = Error()
        for rune in UnicodeString(src):
            var char = String(rune)
            if char == ansi.Marker:
                # ANSI escape sequence
                self.in_ansi = True
            elif self.in_ansi:
                if ansi.is_terminator(ord(char)):
                    # ANSI sequence terminated
                    self.in_ansi = False
            else:
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    var bytes_written = 0
                    bytes_written, err = self.ansi_writer.write((SPACE * int(self.indent)).as_bytes_slice())
                    if err:
                        return bytes_written, err

                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                if char == "\n":
                    # end of current line
                    self.skip_indent = False

            var bytes_written = 0
            bytes_written, err = self.ansi_writer.write(char.as_bytes_slice())
            if err:
                return bytes_written, err

        return len(src), err


fn apply_indent_to_bytes(span: Span[UInt8], indent: UInt8) -> List[UInt8]:
    """Shorthand for declaring a new default indent-writer instance, used to immediately indent a byte slice.
    Returns a NEW list of bytes.

    Args:
        span: The byte slice to indent.
        indent: The number of spaces to indent.

    Returns:
        A new indented list of bytes.
    """
    var writer = Writer(indent)
    _ = writer.write(span)

    return writer.as_bytes()


fn indent(text: String, indent: UInt8) -> String:
    """Shorthand for declaring a new default indent-writer instance,
    used to immediately indent a string.

    Args:
        text: The string to indent.
        indent: The number of spaces to indent.

    Returns:
        A new indented string.

    Example Usage:
    ```mojo
    from weave import indent

    fn main():
        var indented = indent("Hello, World!", 4)
        print(indented)
    ```
    .
    """
    var writer = Writer(indent)
    _ = writer.write(text.as_bytes_slice())
    return String(writer.as_string_slice())
