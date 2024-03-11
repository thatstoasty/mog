from external.gojo.bytes import buffer
from external.gojo.builtins._bytes import Bytes
import external.gojo.io
from .ansi import writer
from .ansi.ansi import is_terminator, Marker, printable_rune_width
from .utils import __string__mul__, strip


alias default_newline = "\n"
alias default_tab_width = 4
alias default_breakpoint = "-"


# WordWrap contains settings and state for customisable text reflowing with
# support for ANSI escape sequences. This means you can style your terminal
# output without affecting the word wrapping algorithm.
@value
struct WordWrap(StringableRaising, io.Writer):
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

    fn add_space(inout self) raises:
        """Write the content of the space buffer to the word-wrap buffer."""
        self.line_len += len(self.space)
        _ = self.buf.write(self.space.bytes())
        self.space.reset()

    fn add_word(inout self) raises:
        """Write the content of the word buffer to the word-wrap buffer."""
        if len(self.word) > 0:
            self.add_space()
            self.line_len += printable_rune_width(str(self.word))
            _ = self.buf.write(self.word.bytes())
            self.word.reset()

    fn add_newline(inout self) raises:
        """Write a newline to the word-wrap buffer and reset the line length & space buffer.
        """
        _ = self.buf.write_byte(ord(self.newline))
        self.line_len = 0
        self.space.reset()

    # write is used to write more content to the word-wrap buffer.
    fn write(inout self, src: Bytes) raises -> Int:
        if self.limit == 0:
            return self.buf.write(src)

        var s = str(src)
        if not self.keep_newlines:
            s = strip(s)
            s = s.replace("\n", " ")

        for i in range(len(s)):
            var c = ord(s[i])
            if c == ord(Marker):
                # ANSI escape sequence
                _ = self.word.write_byte(c)
                self.ansi = True
            elif self.ansi:
                _ = self.word.write_byte(c)
                if is_terminator(c):
                    # ANSI sequence terminated
                    self.ansi = False
            elif c == ord(self.newline):
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
            elif s[i] == " ":
                # end of current word
                self.add_word()
                _ = self.space.write_byte(c)
            elif s[i] == self.breakpoint:
                # valid breakpoint
                self.add_space()
                self.add_word()
                _ = self.buf.write_byte(c)
            else:
                # any other character
                _ = self.word.write_byte(c)

                # add a line break if the current word would exceed the line's
                # character limit
                if (
                    self.line_len
                    + len(self.space)
                    + printable_rune_width(str(self.word))
                    > self.limit
                    and printable_rune_width(str(self.word)) < self.limit
                ):
                    self.add_newline()

        return len(src)

    # close will finish the word-wrap operation. Always call it before trying to
    # retrieve the final result.
    fn close(inout self) raises:
        self.add_word()

    # Bytes returns the word-wrapped result as a byte slice.
    fn bytes(self) raises -> Bytes:
        return self.buf.bytes()

    # String returns the word-wrapped result as a string.
    fn __str__(self) raises -> String:
        return str(self.buf)


# new_writer returns a new instance of a word-wrapping writer, initialized with
# default settings.
fn new_writer(limit: Int) -> WordWrap:
    return WordWrap(limit=limit)


# Bytes is shorthand for declaring a new default WordWrap instance,
# used to immediately word-wrap a byte slice.
fn apply_wordwrap_to_bytes(owned b: Bytes, limit: Int) raises -> Bytes:
    var f = new_writer(limit)
    _ = f.write(b)
    _ = f.close()

    return f.bytes()


# String is shorthand for declaring a new default WordWrap instance,
# used to immediately wrap a string.
fn apply_wordwrap(s: String, limit: Int) raises -> String:
    var buf = Bytes(s)
    # buf = trim_null_characters(buf)
    var b = apply_wordwrap_to_bytes(buf ^, limit)

    return str(b)
