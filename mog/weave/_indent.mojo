from utils import Span, StringSlice
import .ansi


struct Writer(Stringable, Movable):
    """A writer that indents content by a given number of spaces.

    Example Usage:
    ```mojo
    from weave import _indent as indent

    fn main():
        var writer = indent.Writer(4)
        _ = writer.write("Hello, World!")
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

    fn as_bytes_slice(ref [_]self) -> Span[UInt8, __lifetime_of(self)]:
        """Returns the indented result as a byte slice."""
        return self.ansi_writer.forward.as_bytes_slice()

    fn as_string_slice(ref [_]self) -> StringSlice[__lifetime_of(self)]:
        """Returns the indented result as a string slice."""
        return StringSlice(unsafe_from_utf8=self.ansi_writer.forward.as_bytes_slice())

    fn write(inout self, src: String) -> (Int, Error):
        """Writes the given byte slice to the writer.

        Args:
            src: The byte slice to write.

        Returns:
            The number of bytes written and optional error.
        """
        var err = Error()
        for rune in src:
            if rune == ansi.Marker:
                # ANSI escape sequence
                self.in_ansi = True
            elif self.in_ansi:
                if ansi.is_terminator(ord(rune)):
                    # ANSI sequence terminated
                    self.in_ansi = False
            else:
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    var bytes_written = 0
                    bytes_written, err = self.ansi_writer.write(SPACE * int(self.indent))
                    if err:
                        return bytes_written, err

                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                if rune == NEWLINE:
                    # end of current line
                    self.skip_indent = False

            var bytes_written = 0
            bytes_written, err = self.ansi_writer.write(rune)
            if err:
                return bytes_written, err

        return len(src), err


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
    _ = writer.write(text)
    return String(writer.as_string_slice())
