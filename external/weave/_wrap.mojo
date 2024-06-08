from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString
import external.gojo.io
from .ansi import writer, is_terminator, Marker, printable_rune_width
from .strings import repeat


alias DEFAULT_NEWLINE = "\n"
alias DEFAULT_TAB_WIDTH = 4


@value
struct Wrap(Stringable, io.Writer):
    var limit: Int
    var newline: String
    var keep_newlines: Bool
    var preserve_space: Bool
    var tab_width: Int

    var buf: buffer.Buffer
    var line_len: Int
    var ansi: Bool
    var forceful_newline: Bool

    fn __init__(
        inout self,
        limit: Int,
        newline: String = DEFAULT_NEWLINE,
        keep_newlines: Bool = True,
        preserve_space: Bool = False,
        tab_width: Int = DEFAULT_TAB_WIDTH,
        line_len: Int = 0,
        ansi: Bool = False,
        forceful_newline: Bool = False,
    ):
        self.limit = limit
        self.newline = newline
        self.keep_newlines = keep_newlines
        self.preserve_space = preserve_space
        self.tab_width = tab_width

        self.buf = buffer.new_buffer()
        self.line_len = line_len
        self.ansi = ansi
        self.forceful_newline = forceful_newline

    fn add_newline(inout self):
        """Adds a newline to the buffer and resets the line length."""
        _ = self.buf.write_byte(ord(self.newline))
        self.line_len = 0

    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        """Writes the given byte slice to the buffer, wrapping lines as needed.

        Args:
            src: The byte slice to write to the buffer.

        Returns:
            The number of bytes written to the buffer and optional error.
        """
        var tab_space = repeat(" ", self.tab_width)
        var copy = src
        copy.append(0)
        var s = String(copy)

        s = s.replace("\t", tab_space)
        if not self.keep_newlines:
            s = s.replace("\n", "")

        var width = printable_rune_width(s)
        if self.limit <= 0 or self.line_len + width <= self.limit:
            self.line_len += width
            return self.buf.write(src)

        var uni_str = UnicodeString(src)
        for char in uni_str:
            if char == Marker:
                self.ansi = True
            elif self.ansi:
                if is_terminator(ord(char)):
                    self.ansi = False
            elif char == "\n":
                self.add_newline()
                self.forceful_newline = False
                continue
            else:
                var width = printable_rune_width(char)

                if self.line_len + width > self.limit:
                    self.add_newline()
                    self.forceful_newline = True

                if self.line_len == 0:
                    if self.forceful_newline and not self.preserve_space and char == " ":
                        continue
                else:
                    self.forceful_newline = False

                self.line_len += width

            _ = self.buf.write_string(char)

        return len(src), Error()

    fn bytes(self) -> List[UInt8]:
        """Returns the wrapped result as a byte slice.

        Returns:
            The wrapped result as a byte slice.
        """
        return self.buf.bytes()

    # String returns the wrapped result as a string.
    fn __str__(self) -> String:
        return str(self.buf)


fn new_writer(limit: Int) -> Wrap:
    """Returns a new instance of a wrapping writer, initialized with
    default settings.

    Args:
        limit: The maximum line length before wrapping.

    Returns:
        A new instance of a wrapping writer.
    """
    return Wrap(limit=limit)


fn apply_wrap_to_bytes(b: List[UInt8], limit: Int) -> List[UInt8]:
    """Shorthand for declaring a new default Wrap instance,
    used to immediately wrap a byte slice.

    Args:
        b: The byte slice to wrap.
        limit: The maximum line length before wrapping.

    Returns:
        The wrapped byte slice.
    """
    var f = new_writer(limit)
    _ = f.write(b)

    return f.bytes()


fn wrap(s: String, limit: Int) -> String:
    """Shorthand for declaring a new default Wrap instance,
    used to immediately wrap a string.

    Args:
        s: The string to wrap.
        limit: The maximum line length before wrapping.

    Returns:
        The wrapped string.
    """
    var buf = s.as_bytes()
    var b = apply_wrap_to_bytes(buf^, limit)
    b.append(0)

    return String(b)
