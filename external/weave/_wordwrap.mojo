from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString
import external.gojo.io
from .ansi import writer, is_terminator, Marker, printable_rune_width


alias DEFAULT_NEWLINE = "\n"
alias DEFAULT_TAB_WIDTH = 4
alias DEFAULT_BREAKPOINT = "-"


# WordWrap contains settings and state for customisable text reflowing with
# support for ANSI escape sequences. This means you can style your terminal
# output without affecting the word wrapping algorithm.
struct WordWrap(Stringable, io.Writer):
    var limit: Int
    var breakpoint: String
    var newline: String
    var keep_newlines: Bool

    var buf: buffer.Buffer
    var space: buffer.Buffer
    var word: buffer.Buffer

    var line_len: Int
    var ansi: Bool

    fn __init__(
        inout self,
        limit: Int,
        breakpoint: String = DEFAULT_BREAKPOINT,
        newline: String = DEFAULT_NEWLINE,
        keep_newlines: Bool = True,
        line_len: Int = 0,
        ansi: Bool = False,
    ):
        self.limit = limit
        self.breakpoint = breakpoint
        self.newline = newline
        self.keep_newlines = keep_newlines
        self.buf = buffer.new_buffer()
        self.space = buffer.new_buffer()
        self.word = buffer.new_buffer()

        self.line_len = line_len
        self.ansi = ansi

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self.limit = other.limit
        self.breakpoint = other.breakpoint
        self.newline = other.newline
        self.keep_newlines = other.keep_newlines
        self.buf = other.buf^
        self.space = other.space^
        self.word = other.word^
        self.line_len = other.line_len
        self.ansi = other.ansi

    fn add_space(inout self):
        """Write the content of the space buffer to the word-wrap buffer."""
        self.line_len += len(self.space)
        _ = self.buf.write(self.space.bytes())
        self.space.reset()

    fn add_word(inout self):
        """Write the content of the word buffer to the word-wrap buffer."""
        if len(self.word) > 0:
            self.add_space()
            self.line_len += printable_rune_width(str(self.word))
            _ = self.buf.write(self.word.bytes())
            self.word.reset()

    fn add_newline(inout self):
        """Write a newline to the word-wrap buffer and reset the line length & space buffer."""
        _ = self.buf.write_byte(ord(self.newline))
        self.line_len = 0
        self.space.reset()

    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        """Write more content to the word-wrap buffer.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written. and optional error.
        """
        if self.limit == 0:
            return self.buf.write(src)

        var copy = src
        copy.append(0)
        var s = String(copy)
        if not self.keep_newlines:
            s = s.strip()
            s = s.replace("\n", " ")

        var uni_str = UnicodeString(s)
        for char in uni_str:
            if char == Marker:
                # ANSI escape sequence
                _ = self.word.write(char.as_bytes())
                self.ansi = True
            elif self.ansi:
                _ = self.word.write(char.as_bytes())
                if is_terminator(ord(char)):
                    # ANSI sequence terminated
                    self.ansi = False
            elif char == self.newline:
                # end of current line
                # see if we can add the content of the space buffer to the current line
                if len(self.word) == 0:
                    if self.line_len + len(self.space) > self.limit:
                        self.line_len = 0
                    else:
                        # preserve whitespace
                        _ = self.buf.write(self.space.bytes())

                    self.space.reset()

                self.add_word()
                self.add_newline()
            elif char == " ":
                # end of current word
                self.add_word()
                _ = self.space.write(char.as_bytes())
            elif char == self.breakpoint:
                # valid breakpoint
                self.add_space()
                self.add_word()
                _ = self.buf.write(char.as_bytes())
            else:
                # any other character
                _ = self.word.write(char.as_bytes())

                # add a line break if the current word would exceed the line's
                # character limit
                if (
                    self.line_len + len(self.space) + printable_rune_width(str(self.word)) > self.limit
                    and printable_rune_width(str(self.word)) < self.limit
                ):
                    self.add_newline()

        return len(src), Error()

    fn close(inout self):
        """Finishes the word-wrap operation. Always call it before trying to retrieve the final result."""
        self.add_word()

    fn bytes(self) -> List[UInt8]:
        """Returns the word-wrapped result as a byte slice.

        Returns:
            The word-wrapped result as a byte slice.
        """
        return self.buf.bytes()

    fn __str__(self) -> String:
        return str(self.buf)


fn new_writer(limit: Int) -> WordWrap:
    """Returns a new instance of a word-wrapping writer, initialized with
    default settings.

    Args:
        limit: The maximum number of characters per line.

    Returns:
        A new instance of a word-wrapping writer.
    """
    return WordWrap(limit=limit)


fn apply_wordwrap_to_bytes(b: List[UInt8], limit: Int) -> List[UInt8]:
    """Shorthand for declaring a new default WordWrap instance,
    used to immediately word-wrap a byte slice.

    Args:
        b: The byte slice to word-wrap.
        limit: The maximum number of characters per line.

    Returns:
        The word-wrapped byte slice.
    """
    var f = new_writer(limit)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


fn wordwrap(s: String, limit: Int) -> String:
    """Shorthand for declaring a new default WordWrap instance,
    used to immediately wrap a string.

    Args:
        s: The string to wrap.
        limit: The maximum number of characters per line.

    Returns:
        The wrapped string.
    """
    var buf = s.as_bytes()
    var b = apply_wordwrap_to_bytes(buf^, limit)
    b.append(0)

    return String(b)
