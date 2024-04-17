from math.bit import ctlz
from external.gojo.bytes import buffer
from external.gojo.builtins import Byte
import external.gojo.io
from .ansi import writer, is_terminator, Marker, printable_rune_width
from .strings import repeat, strip


alias default_newline = "\n"
alias default_tab_width = 4
alias default_breakpoint = "-"


# WordWrap contains settings and state for customisable text reflowing with
# support for ANSI escape sequences. This means you can style your terminal
# output without affecting the word wrapping algorithm.
@value
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
        breakpoint: String = default_breakpoint,
        newline: String = default_newline,
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

    fn write(inout self, src: List[Byte]) -> (Int, Error):
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
            s = strip(s)
            s = s.replace("\n", " ")

        # Rune iterator
        var bytes = len(s)
        var s_bytes = s.as_bytes()  # needs to be mutable, so we steal the data of the copy
        var p = DTypePointer[DType.int8](s_bytes.steal_data()).bitcast[DType.uint8]()
        while bytes > 0:
            var char_length = int((p.load() >> 7 == 0).cast[DType.uint8]() * 1 + ctlz(~p.load()))
            var sp = DTypePointer[DType.int8].alloc(char_length + 1)
            memcpy(sp, p.bitcast[DType.int8](), char_length)
            sp[char_length] = 0

            # Functional logic
            var char = String(sp, char_length + 1)
            if char == ord(Marker):
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

            # Move iterator forward
            bytes -= char_length
            p += char_length

        return len(src), Error()

    fn close(inout self):
        """Finishes the word-wrap operation. Always call it before trying to retrieve the final result."""
        self.add_word()

    fn bytes(self) -> List[Byte]:
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


fn apply_wordwrap_to_bytes(b: List[Byte], limit: Int) -> List[Byte]:
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


fn apply_wordwrap(s: String, limit: Int) -> String:
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
