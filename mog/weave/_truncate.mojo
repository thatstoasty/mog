from utils import Span, StringSlice
from .gojo.bytes import buffer
from .gojo.unicode import rune_width
import .ansi


struct Writer(Stringable, Movable):
    """A truncating writer that truncates content at the given printable cell width.

    Example Usage:
    ```mojo
    from weave import _truncate as truncate

    fn main():
        var writer = truncate.Writer(4, tail=".")
        _ = writer.write("Hello, World!")
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

    fn as_bytes_slice(ref [_]self) -> Span[UInt8, __lifetime_of(self)]:
        """Returns the truncated result as a byte slice."""
        return self.ansi_writer.forward.as_bytes_slice()

    fn as_string_slice(ref [_]self) -> StringSlice[__lifetime_of(self)]:
        """Returns the truncated result as a string slice."""
        return StringSlice(unsafe_from_utf8=self.ansi_writer.forward.as_bytes_slice())

    fn write(inout self, src: String) -> (Int, Error):
        """Truncates content at the given printable cell width, leaving any ANSI sequences intact.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        var tw = ansi.printable_rune_width(self.tail)
        if self.width < UInt8(tw):
            return self.ansi_writer.forward.write(self.tail.as_bytes_slice())

        self.width -= UInt8(tw)
        var cur_width: UInt8 = 0

        for rune in src:
            if rune == ansi.Marker:
                # ANSI escape sequence
                self.in_ansi = True
            elif self.in_ansi:
                if ansi.is_terminator(ord(rune)):
                    # ANSI sequence terminated
                    self.in_ansi = False
            else:
                cur_width += UInt8(rune_width(ord(rune)))

            if cur_width > self.width:
                var n = self.ansi_writer.forward.write_string(self.tail)
                if self.ansi_writer.last_sequence() != "":
                    self.ansi_writer.reset_ansi()
                return n^

            _ = self.ansi_writer.write(rune)

        return len(src), Error()


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
    var writer = Writer(width, tail)
    _ = writer.write(text)
    return String(writer.as_string_slice())
