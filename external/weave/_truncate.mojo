from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString, rune_width
import .ansi


struct Writer(Stringable, Movable):
    """A truncating writer that truncates content at the given printable cell width.

    Example Usage:
    ```mojo
    from weave import _truncate as truncate

    fn main():
        var writer = truncate.Writer(4, tail=".")
        _ = writer.write("Hello, World!".as_bytes_slice())
        print(String(writer.as_string_slice()))
    ```
    .
    """

    var width: UInt8
    """The maximum printable cell width."""
    var tail: String
    """The tail to append to the truncated content."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores the text content."""
    var in_ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(inout self, width: UInt8, tail: String, in_ansi: Bool = False):
        """Initializes a new truncate-writer instance.

        Args:
            width: The maximum printable cell width.
            tail: The tail to append to the truncated content.
            in_ansi: Whether the current character is part of an ANSI escape sequence.
        """
        self.width = width
        self.tail = tail
        self.in_ansi = in_ansi
        self.ansi_writer = ansi.Writer()

    fn __moveinit__(inout self, owned other: Self):
        self.width = other.width
        self.tail = other.tail
        self.ansi_writer = other.ansi_writer^
        self.in_ansi = other.in_ansi

    fn __str__(self) -> String:
        return str(self.ansi_writer.forward)

    fn as_bytes(self) -> List[UInt8]:
        """Returns the truncated result as a byte list."""
        return self.ansi_writer.forward.bytes()

    fn as_bytes_slice(self: Reference[Self]) -> Span[UInt8, self.is_mutable, self.lifetime]:
        """Returns the truncated result as a byte slice."""
        return self[].ansi_writer.forward.as_bytes_slice()

    fn as_string_slice(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """Returns the truncated result as a string slice."""
        return StringSlice(unsafe_from_utf8=self[].ansi_writer.forward.as_bytes_slice())

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Truncates content at the given printable cell width, leaving any ANSI sequences intact.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        var tw = ansi.printable_rune_width(self.tail)
        if self.width < UInt8(tw):
            return self.ansi_writer.forward._write(self.tail.as_bytes_slice())

        self.width -= UInt8(tw)
        var cur_width: UInt8 = 0

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
                cur_width += UInt8(rune_width(ord(char)))

            if cur_width > self.width:
                var n = self.ansi_writer.forward.write_string(self.tail)
                if self.ansi_writer.last_sequence() != "":
                    self.ansi_writer.reset_ansi()
                return n^

            _ = self.ansi_writer.write(char.as_bytes_slice())

        return len(src), Error()


fn apply_truncate_to_bytes(span: Span[UInt8], width: UInt8) -> List[UInt8]:
    """Truncates a byte slice at the given printable cell width.

    Args:
        span: The byte slice to truncate.
        width: The maximum printable cell width.

    Returns:
        A new truncated byte slice.
    """
    return apply_truncate_to_bytes_with_tail(span, width, "")


fn apply_truncate_to_bytes_with_tail(span: Span[UInt8], width: UInt8, tail: String) -> List[UInt8]:
    """Shorthand for declaring a new default truncate-writer instance,
    used to immediately truncate a byte slice. A tail is then added to the end of the byte slice.

    Args:
        span: The byte slice to truncate.
        width: The maximum printable cell width.
        tail: The tail to append to the truncated content.

    Returns:
        A new truncated byte slice.
    """
    var writer = Writer(width, str(tail))
    _ = writer.write(span)
    return writer.as_bytes()


fn truncate(text: String, width: UInt8) -> String:
    """Shorthand for declaring a new default truncate-writer instance,
    used to immediately truncate a String.

    Args:
        text: The string to truncate.
        width: The maximum printable cell width.

    Returns:
        A new truncated string.

    ```mojo
    from weave import truncate

    fn main():
        var truncated = truncate("Hello, World!", 5)
        print(truncated)
    ```
    .
    """
    return truncate_with_tail(text, width, "")


fn truncate_with_tail(text: String, width: UInt8, tail: String) -> String:
    """Shorthand for declaring a new default truncate-writer instance,
    used to immediately truncate a String. A tail is then added to the end of the string.

    Args:
        text: The string to truncate.
        width: The maximum printable cell width.
        tail: The tail to append to the truncated content.

    Returns:
        A new truncated string.

    ```mojo
    from weave import truncate_with_tail

    fn main():
        var truncated = truncate_with_tail("Hello, World!", 5, ".")
        print(truncated)
    ```
    .
    """
    var writer = Writer(width, str(tail))
    _ = writer.write(text.as_bytes_slice())
    return String(writer.as_string_slice())
