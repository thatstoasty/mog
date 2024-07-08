from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString, string_width
import .ansi


struct Writer(Stringable, Movable):
    """A padding writer that pads content to the given printable cell width.

    Example Usage:
    ```mojo
    from weave import _padding as padding

    fn main():
        var writer = padding.Writer(4)
        _ = writer.write("Hello, World!".as_bytes_slice())
        writer.flush()
        print(String(writer.as_string_slice()))
    ```
    """

    var padding: UInt8
    """Padding width to apply to each line."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores intermediary text content."""
    var cache: buffer.Buffer
    """The buffer that stores the padded content after it's been flushed."""
    var line_len: Int
    """The current line length."""
    var in_ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(
        inout self,
        padding: UInt8,
        line_len: Int = 0,
        in_ansi: Bool = False,
    ):
        """Initializes a new padding-writer instance.

        Args:
            padding: The padding width.
            line_len: The current line length.
            in_ansi: Whether the current character is part of an ANSI escape sequence.
        """
        self.padding = padding
        self.line_len = line_len
        self.in_ansi = in_ansi
        self.cache = buffer.new_buffer()
        self.ansi_writer = ansi.Writer()

    fn __moveinit__(inout self, owned other: Self):
        self.padding = other.padding
        self.ansi_writer = other.ansi_writer^
        self.cache = other.cache^
        self.line_len = other.line_len
        self.in_ansi = other.in_ansi

    fn __str__(self) -> String:
        return str(self.cache)

    fn as_bytes(self) -> List[UInt8]:
        """Returns the padded result as a byte list."""
        return self.cache.bytes()

    fn as_bytes_slice(self: Reference[Self]) -> Span[UInt8, self.is_mutable, self.lifetime]:
        """Returns the padded result as a byte slice."""
        return self[].cache.as_bytes_slice()

    fn as_string_slice(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """Returns the padded result as a string slice."""
        return StringSlice(unsafe_from_utf8=self[].cache.as_bytes_slice())

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Pads content to the given printable cell width.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        var err = Error()
        for rune in UnicodeString(src):
            var char = String(rune)
            if char == ansi.Marker:
                self.in_ansi = True
            elif self.in_ansi:
                if ansi.is_terminator(ord(char)):
                    self.in_ansi = False
            else:
                if char == "\n":
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0
                else:
                    self.line_len += string_width(char)

            var bytes_written = 0

            bytes_written, err = self.ansi_writer.write(char.as_bytes_slice())
            if err:
                return bytes_written, err

        return len(src), err

    fn pad(inout self):
        """Pads the current line with spaces to the given width."""
        if self.padding > 0 and UInt8(self.line_len) < self.padding:
            var padding = SPACE * (int(self.padding) - self.line_len)
            _ = self.ansi_writer.write(padding.as_bytes_slice())

    fn close(inout self):
        """Finishes the padding operation."""
        return self.flush()

    fn flush(inout self):
        """Finishes the padding operation. Always call it before trying to retrieve the final result."""
        if self.line_len != 0:
            self.pad()

        self.cache.reset()
        _ = self.ansi_writer.forward.write_to(self.cache)
        self.line_len = 0
        self.in_ansi = False


fn apply_padding_to_bytes(bytes: Span[UInt8], width: UInt8) -> List[UInt8]:
    """Pads a byte slice to the given printable cell width.

    Args:
        bytes: The byte slice to pad.
        width: The padding width.

    Returns:
        A new padded list of bytes.
    """
    var writer = Writer(width)
    _ = writer.write(bytes)
    _ = writer.flush()
    return writer.as_bytes()


fn padding(text: String, width: UInt8) -> String:
    """Shorthand for declaring a new default padding-writer instance, used to immediately pad a string.

    Args:
        text: The string to pad.
        width: The padding width.

    Returns:
        A new padded string.

    Example Usage:
    ```mojo
    from weave import padding

    fn main():
        var padded = padding("Hello, World!", 5)
        print(padded)
    ```
    .
    """
    var writer = Writer(width)
    _ = writer.write(text.as_bytes_slice())
    _ = writer.flush()
    return String(writer.as_string_slice())
