from external.gojo.bytes import buffer
from external.gojo.unicode import UnicodeString
import .ansi


alias DEFAULT_NEWLINE = "\n"
alias DEFAULT_TAB_WIDTH = 4
alias DEFAULT_BREAKPOINT = "-"


struct Writer(Stringable, Movable):
    """A word-wrapping writer that wraps content based on words at the given limit.

    Example Usage:
    ```mojo
    from weave import _wordwrap as wordwrap

    fn main():
        var writer = wordwrap.Writer(5)
        _ = writer.write("Hello, World!".as_bytes_slice())
        _ = writer.close()
        print(String(writer.as_string_slice()))
    ```
    .
    """

    var limit: Int
    """The maximum number of characters per line."""
    var breakpoint: String
    """The character to use as a breakpoint."""
    var newline: String
    """The character to use as a newline."""
    var keep_newlines: Bool
    """Whether to keep newlines in the content."""
    var buf: buffer.Buffer
    """The buffer that stores the word-wrapped content."""
    var space: buffer.Buffer
    """The buffer that stores the space between words."""
    var word: buffer.Buffer
    """The buffer that stores the current word."""
    var line_len: Int
    """The current line length."""
    var ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(
        inout self,
        limit: Int,
        breakpoint: String = DEFAULT_BREAKPOINT,
        newline: String = DEFAULT_NEWLINE,
        keep_newlines: Bool = True,
        line_len: Int = 0,
        ansi: Bool = False,
    ):
        """Initializes a new word-wrap writer instance.

        Args:
            limit: The maximum number of characters per line.
            breakpoint: The character to use as a breakpoint.
            newline: The character to use as a newline.
            keep_newlines: Whether to keep newlines in the content.
            line_len: The current line length.
            ansi: Whether the current character is part of an ANSI escape sequence.
        """
        self.limit = limit
        self.breakpoint = breakpoint
        self.newline = newline
        self.keep_newlines = keep_newlines
        self.buf = buffer.new_buffer()
        self.space = buffer.new_buffer()
        self.word = buffer.new_buffer()
        self.line_len = line_len
        self.ansi = ansi

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

    fn __str__(self) -> String:
        return str(self.buf)

    fn as_bytes(self) -> List[UInt8]:
        """Returns the word wrapped result as a byte list."""
        return self.buf.bytes()

    fn as_bytes_slice(self: Reference[Self]) -> Span[UInt8, self.is_mutable, self.lifetime]:
        """Returns the word wrapped result as a byte slice."""
        return self[].buf.as_bytes_slice()

    fn as_string_slice(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """Returns the word wrapped result as a string slice."""
        return StringSlice(unsafe_from_utf8=self[].buf.as_bytes_slice())

    fn add_space(inout self):
        """Write the content of the space buffer to the word-wrap buffer."""
        self.line_len += len(self.space)
        _ = self.buf.write(self.space.bytes())
        self.space.reset()

    fn add_word(inout self):
        """Write the content of the word buffer to the word-wrap buffer."""
        if len(self.word) > 0:
            self.add_space()
            self.line_len += ansi.printable_rune_width(str(self.word))
            _ = self.buf.write(self.word.bytes())
            self.word.reset()

    fn add_newline(inout self):
        """Write a newline to the word-wrap buffer and reset the line length & space buffer."""
        _ = self.buf.write_byte(NEWLINE_BYTE)
        self.line_len = 0
        self.space.reset()

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Write more content to the word-wrap buffer.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written. and optional error.
        """
        if self.limit == 0:
            return self.buf._write(src)

        var buf = List[UInt8](src)
        buf.append(0)
        var s = String(buf^)
        if not self.keep_newlines:
            s = s.strip()
            s = s.replace("\n", " ")

        for rune in UnicodeString(s):
            var char = String(rune)
            if char == ansi.Marker:
                # ANSI escape sequence
                _ = self.word._write(char.as_bytes_slice())
                self.ansi = True
            elif self.ansi:
                _ = self.word._write(char.as_bytes_slice())
                if ansi.is_terminator(ord(char)):
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
                        _ = self.buf._write(self.space.as_bytes_slice())

                    self.space.reset()

                self.add_word()
                self.add_newline()
            elif char == " ":
                # end of current word
                self.add_word()
                _ = self.space._write(char.as_bytes_slice())
            elif char == self.breakpoint:
                # valid breakpoint
                self.add_space()
                self.add_word()
                _ = self.buf._write(char.as_bytes_slice())
            else:
                # any other character
                _ = self.word._write(char.as_bytes_slice())

                # add a line break if the current word would exceed the line's
                # character limit
                if (
                    self.line_len + len(self.space) + ansi.printable_rune_width(str(self.word)) > self.limit
                    and ansi.printable_rune_width(str(self.word)) < self.limit
                ):
                    self.add_newline()

        return len(src), Error()

    fn close(inout self):
        """Finishes the word-wrap operation. Always call it before trying to retrieve the final result."""
        self.add_word()


fn apply_wordwrap_to_bytes(span: Span[UInt8], limit: Int) -> List[UInt8]:
    """Shorthand for declaring a new default WordWrap instance,
    used to immediately word-wrap a byte slice.

    Args:
        span: The byte slice to word-wrap.
        limit: The maximum number of characters per line.

    Returns:
        A new word-wrapped byte slice.
    """
    var writer = Writer(limit)
    _ = writer.write(span)
    _ = writer.close()
    return writer.as_bytes()


fn wordwrap(text: String, limit: Int) -> String:
    """Shorthand for declaring a new default WordWrap instance,
    used to immediately wrap a string.

    Args:
        text: The string to wrap.
        limit: The maximum number of characters per line.

    Returns:
        A new word-wrapped string.

    ```mojo
    from weave import wordwrap

    fn main():
        var wrapped = wordwrap("Hello, World!", 5)
        print(wrapped)
    ```
    .
    """
    var writer = Writer(limit)
    _ = writer.write(text.as_bytes_slice())
    _ = writer.close()
    return String(writer.as_string_slice())
