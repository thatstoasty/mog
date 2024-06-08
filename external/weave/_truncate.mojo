from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString
import external.gojo.io
from .ansi import writer, is_terminator, Marker, printable_rune_width
from .strings import repeat, strip


@value
struct Writer(Stringable, io.Writer):
    var width: UInt8
    var tail: String

    var ansi_writer: writer.Writer
    var ansi: Bool

    fn __init__(inout self, width: UInt8, tail: String, ansi: Bool = False):
        self.width = width
        self.tail = tail
        self.ansi = ansi

        self.ansi_writer = writer.new_default_writer()

    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        """Truncates content at the given printable cell width, leaving any ANSI sequences intact.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        var tw = printable_rune_width(self.tail)
        if self.width < UInt8(tw):
            return self.ansi_writer.forward.write_string(self.tail)

        self.width -= UInt8(tw)
        var cur_width: UInt8 = 0

        var uni_str = UnicodeString(src)
        for char in uni_str:
            if char == Marker:
                # ANSI escape sequence
                self.ansi = True
            elif self.ansi:
                if is_terminator(ord(char)):
                    # ANSI sequence terminated
                    self.ansi = False
            else:
                cur_width += UInt8(printable_rune_width(char))

            if cur_width > self.width:
                var n = self.ansi_writer.forward.write_string(self.tail)
                if self.ansi_writer.last_sequence() != "":
                    self.ansi_writer.reset_ansi()
                return n^

            _ = self.ansi_writer.write(char.as_bytes())

        return len(src), Error()

    fn bytes(self) -> List[UInt8]:
        """Returns the truncated result as a byte slice.

        Returns:
            The truncated result as a byte slice.
        """
        return self.ansi_writer.forward.bytes()

    fn __str__(self) -> String:
        return str(self.ansi_writer.forward)


fn new_writer(width: UInt8, tail: String) -> Writer:
    """Creates a new truncate-writer instance.

    Args:
        width: The maximum printable cell width.
        tail: The tail to append to the truncated content.

    Returns:
        A new truncate-writer instance.
    """
    return Writer(width, tail)


fn apply_truncate_to_bytes(b: List[UInt8], width: UInt8) -> List[UInt8]:
    """Truncates a byte slice at the given printable cell width.

    Args:
        b: The byte slice to truncate.
        width: The maximum printable cell width.

    Returns:
        The truncated byte slice.
    """
    return apply_truncate_to_bytes_with_tail(b, width, "")


fn apply_truncate_to_bytes_with_tail(b: List[UInt8], width: UInt8, tail: String) -> List[UInt8]:
    """Shorthand for declaring a new default truncate-writer instance, used to immediately truncate a byte slice. A tail is then added to the end of the byte slice.

    Args:
        b: The byte slice to truncate.
        width: The maximum printable cell width.
        tail: The tail to append to the truncated content.

    Returns:
        The truncated byte slice.
    """
    var f = new_writer(width, str(tail))
    _ = f.write(b)

    return f.bytes()


fn truncate(s: String, width: UInt8) -> String:
    """Shorthand for declaring a new default truncate-writer instance, used to immediately truncate a String.

    Args:
        s: The string to truncate.
        width: The maximum printable cell width.

    Returns:
        The truncated string.
    """
    return truncate_with_tail(s, width, "")


fn truncate_with_tail(s: String, width: UInt8, tail: String) -> String:
    """Shorthand for declaring a new default truncate-writer instance, used to immediately truncate a String.
    A tail is then added to the end of the string.

    Args:
        s: The string to truncate.
        width: The maximum printable cell width.
        tail: The tail to append to the truncated content.

    Returns:
        The truncated string.
    """
    var buf = s.as_bytes()
    var b = apply_truncate_to_bytes_with_tail(buf^, width, tail)
    b.append(0)
    return String(b)
