from .ansi import writer
from .ansi.ansi import is_terminator, Marker, printable_rune_width
from .gojo.buffers import _buffer
from .gojo.buffers import _bytes as bt
from .stdlib_extensions.builtins.string import __string__mul__
from .gojo.stdlib_extensions.builtins import bytes


alias default_newline = "\n"
alias default_tab_width = 4


struct Wrap():
    var limit: Int
    var newline: String
    var keep_newlines: Bool
    var preserve_space: Bool
    var tab_width: Int

    var buf: _buffer.Buffer
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

        # TODO: Ownership of the DynamicVector should be moved to the buffer
        var buf = bytes()
        self.buf = _buffer.new_buffer(buf=buf)
        self.line_len = line_len
        self.ansi = ansi
        self.forceful_newline = forceful_newline

    fn add_newline(inout self) raises:
        _ = self.buf.write_byte(ord(self.newline))
        self.line_len = 0

    fn write(inout self, b: bytes) raises -> Int:
        let tab_space = __string__mul__(" ", self.tab_width)
        var s = bt.to_string(b)

        s = s.replace("\t", tab_space)
        if not self.keep_newlines:
            s = s.replace("\n", "")

        let width = printable_rune_width(s)
        if self.limit <= 0 or self.line_len + width <= self.limit:
            self.line_len += width
            return self.buf.write(b)

        for i in range(len(s)):
            let c = s[i]
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
                let width = len(c)

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

        return len(b)

    # Bytes returns the wrapped result as a byte slice.
    fn bytes(self) -> bytes:
        return self.buf.bytes()

    # String returns the wrapped result as a string.
    fn string(self) -> String:
        return self.buf.string()


# new_writer returns a new instance of a wrapping writer, initialized with
# default settings.
fn new_writer(limit: Int) -> Wrap:
    return Wrap(limit=limit)


# Bytes is shorthand for declaring a new default Wrap instance,
# used to immediately wrap a byte slice.
fn to_bytes(inout b: bytes, limit: Int) raises -> bytes:
    var f = new_writer(limit)
    _ = f.write(b)

    return f.bytes()


# String is shorthand for declaring a new default Wrap instance,
# used to immediately wrap a string.
fn string(s: String, limit: Int) raises -> String:
    var buf = bt.to_bytes(s)
    let b = to_bytes(buf, limit)

    return bt.to_string(b)
