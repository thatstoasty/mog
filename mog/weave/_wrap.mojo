from utils import Span, StringSlice
from .gojo.bytes import buffer
from .gojo.unicode import rune_width
import .ansi

alias DEFAULT_NEWLINE = "\n"
alias DEFAULT_TAB_WIDTH = 4


struct Writer(Stringable, Movable):
    """A line-wrapping writer that wraps content based on the given limit.

    Example Usage:
    ```mojo
    from weave import _wrap as wrap

    fn main():
        var writer = wrap.Writer(5)
        _ = writer.write("Hello, World!")
        print(String(writer.as_string_slice()))
    ```
    """

    var limit: Int
    """The maximum number of characters per line."""
    var newline: String
    """The character to use as a newline."""
    var keep_newlines: Bool
    """Whether to keep newlines in the content."""
    var preserve_space: Bool
    """Whether to preserve space characters."""
    var tab_width: Int
    """The width of a tab character."""
    var buf: buffer.Buffer
    """The buffer that stores the wrapped content."""
    var line_len: Int
    """The current line length."""
    var ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""
    var forceful_newline: Bool
    """Whether to force a newline at the end of the line."""

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
        """Initializes a new line-wrap writer instance.

        Args:
            limit: The maximum number of characters per line.
            newline: The character to use as a newline.
            keep_newlines: Whether to keep newlines in the content.
            preserve_space: Whether to preserve space characters.
            tab_width: The width of a tab character.
            line_len: The current line length.
            ansi: Whether the current character is part of an ANSI escape sequence.
            forceful_newline: Whether to force a newline at the end of the line.
        """
        self.limit = limit
        self.newline = newline
        self.keep_newlines = keep_newlines
        self.preserve_space = preserve_space
        self.tab_width = tab_width
        self.buf = buffer.Buffer()
        self.line_len = line_len
        self.ansi = ansi
        self.forceful_newline = forceful_newline

    fn __moveinit__(inout self, owned other: Self):
        self.limit = other.limit
        self.newline = other.newline
        self.keep_newlines = other.keep_newlines
        self.preserve_space = other.preserve_space
        self.tab_width = other.tab_width
        self.buf = other.buf^
        self.line_len = other.line_len
        self.ansi = other.ansi
        self.forceful_newline = other.forceful_newline

    fn __str__(self) -> String:
        return str(self.buf)

    fn as_bytes(self) -> List[UInt8]:
        """Returns the wrapped result as a byte list."""
        return self.buf.bytes()

    fn as_bytes_slice(ref [_]self) -> Span[UInt8, __lifetime_of(self)]:
        """Returns the  wrapped result as a byte slice."""
        return self.buf.as_bytes_slice()

    fn as_string_slice(ref [_]self) -> StringSlice[__lifetime_of(self)]:
        """Returns the wrapped result as a string slice."""
        return StringSlice(unsafe_from_utf8=self.buf.as_bytes_slice())

    fn add_newline(inout self):
        """Adds a newline to the buffer and resets the line length."""
        _ = self.buf.write_byte(ord(self.newline))
        self.line_len = 0

    fn write(inout self, owned src: String) -> (Int, Error):
        """Writes the given byte slice to the buffer, wrapping lines as needed.

        Args:
            src: The byte slice to write to the buffer.

        Returns:
            The number of bytes written to the buffer and optional error.
        """
        var tab_space = SPACE * self.tab_width
        src = src.replace("\t", tab_space)
        if not self.keep_newlines:
            src = src.replace("\n", "")

        var width = ansi.printable_rune_width(src)
        if self.limit <= 0 or self.line_len + width <= self.limit:
            self.line_len += width
            return self.buf.write(src.as_bytes_slice())

        for rune in src:
            if rune == ansi.Marker:
                self.ansi = True
            elif self.ansi:
                if ansi.is_terminator(ord(rune)):
                    self.ansi = False
            elif rune == NEWLINE:
                self.add_newline()
                self.forceful_newline = False
                continue
            else:
                var width = rune_width(ord(rune))

                if self.line_len + width > self.limit:
                    self.add_newline()
                    self.forceful_newline = True

                if self.line_len == 0:
                    if self.forceful_newline and not self.preserve_space and rune == SPACE:
                        continue
                else:
                    self.forceful_newline = False

                self.line_len += width
            _ = self.buf.write(rune.as_bytes_slice())

        return len(src), Error()


fn wrap(text: String, limit: Int) -> String:
    """Shorthand for declaring a new default Wrap instance,
    used to immediately wrap a string.

    Args:
        text: The string to wrap.
        limit: The maximum line length before wrapping.

    Returns:
        A new wrapped string.

    ```mojo
    from weave import wrap

    fn main():
        var wrapped = wrap("Hello, World!", 5)
        print(wrapped)
    ```
    .
    """
    var writer = Writer(limit)
    _ = writer.write(text)
    return String(writer.as_string_slice())
