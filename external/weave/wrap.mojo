from external.gojo.bytes import buffer
from external.gojo.builtins import Result
from external.gojo.builtins.bytes import Byte
import external.gojo.io
from .ansi import writer
from .ansi.ansi import is_terminator, Marker, printable_rune_width
from .utils import __string__mul__


alias default_newline = "\n"
alias default_tab_width = 4


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
        newline: String = default_newline,
        keep_newlines: Bool = True,
        preserve_space: Bool = False,
        tab_width: Int = default_tab_width,
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
        _ = self.buf.write_byte(ord(self.newline))
        self.line_len = 0

    fn write(inout self, src: List[Byte]) -> Result[Int]:
        var tab_space = __string__mul__(" ", self.tab_width)
        var copy = List[Byte](src)
        copy.append(0)
        var s = String(copy)

        s = s.replace("\t", tab_space)
        if not self.keep_newlines:
            s = s.replace("\n", "")

        var width = printable_rune_width(s)
        if self.limit <= 0 or self.line_len + width <= self.limit:
            self.line_len += width
            return self.buf.write(src)

        for i in range(len(s)):
            var c = s[i]
            if c == Marker:
                self.ansi = True
            elif self.ansi:
                if is_terminator(ord(c)):
                    self.ansi = False
            elif c == "\n":
                self.add_newline()
                self.forceful_newline = False
                continue
            else:
                var width = len(c)

                if self.line_len + width > self.limit:
                    self.add_newline()
                    self.forceful_newline = True

                if self.line_len == 0:
                    if self.forceful_newline and not self.preserve_space and c == " ":
                        continue
                else:
                    self.forceful_newline = False

                self.line_len += width

            _ = self.buf.write_string(c)

        return len(src)

    # List[Byte] returns the wrapped result as a byte slice.
    fn bytes(self) -> List[Byte]:
        return self.buf.bytes()

    # String returns the wrapped result as a string.
    fn __str__(self) -> String:
        return str(self.buf)


# new_writer returns a new instance of a wrapping writer, initialized with
# default settings.
fn new_writer(limit: Int) -> Wrap:
    return Wrap(limit=limit)


# List[Byte] is shorthand for declaring a new default Wrap instance,
# used to immediately wrap a byte slice.
fn apply_wrap_to_bytes(owned b: List[Byte], limit: Int) -> List[Byte]:
    var f = new_writer(limit)
    _ = f.write(b)

    return f.bytes()


# String is shorthand for declaring a new default Wrap instance,
# used to immediately wrap a string.
fn apply_wrap(s: String, limit: Int) -> String:
    var buf = s.as_bytes()
    var b = apply_wrap_to_bytes(buf ^, limit)
    b.append(0)

    return String(b)
