from bit import countl_zero
from external.gojo.bytes import buffer
from external.gojo.builtins.bytes import Byte, has_suffix
from external.gojo.unicode import UnicodeString
import external.gojo.io
from .ansi import Marker, is_terminator


alias ANSI_ESCAPE = String("[0m").as_bytes()
alias ANSI_RESET = String("\x1b[0m").as_bytes()


struct Writer(io.Writer):
    var forward: buffer.Buffer
    var ansi: Bool
    var ansi_seq: buffer.Buffer
    var last_seq: buffer.Buffer
    var seq_changed: Bool
    # var rune_buf: List[Byte]

    fn __init__(inout self, owned forward: buffer.Buffer):
        self.forward = forward^
        self.ansi = False
        self.ansi_seq = buffer.new_buffer()
        self.last_seq = buffer.new_buffer()
        self.seq_changed = False
        # self.rune_buf = List[Byte](capacity=4096)

    fn __moveinit__(inout self, owned other: Writer):
        self.forward = other.forward^
        self.ansi = other.ansi
        self.ansi_seq = other.ansi_seq^
        self.last_seq = other.last_seq^
        self.seq_changed = other.seq_changed
        # self.rune_buf = other.rune_buf

    fn write(inout self, src: List[Byte]) -> (Int, Error):
        """Write content to the ANSI buffer.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        var uni_str = UnicodeString(src)
        for char in uni_str:
            if char == Marker:
                # ANSI escape sequence
                self.ansi = True
                self.seq_changed = True
                _ = self.ansi_seq.write_string(char)
            elif self.ansi:
                _ = self.ansi_seq.write_string(char)
                if is_terminator(ord(char)):
                    self.ansi = False

                    if has_suffix(self.ansi_seq.bytes(), ANSI_ESCAPE):
                        # reset sequence
                        self.last_seq.reset()
                        self.seq_changed = False
                    elif char == "m":
                        # color code
                        _ = self.last_seq.write(self.ansi_seq.bytes())

                    _ = self.ansi_seq.write_to(self.forward)
            else:
                _ = self.forward.write_string(char)

        return len(src), Error()

    fn write_byte(inout self, byte: Byte) -> Int:
        _ = self.forward.write_byte(byte)
        return 1

    # fn write_rune(inout self, rune: String) -> (Int, Error):
    #     return self.forward.write(self.runeBuf[:n])

    fn last_sequence(self) -> String:
        return str(self.last_seq)

    fn reset_ansi(inout self):
        if not self.seq_changed:
            return
        var b = List[Byte](capacity=512)
        for i in range(len(ANSI_RESET)):
            b[i] = ANSI_RESET[i]
        _ = self.forward.write(b)

    fn restore_ansi(inout self):
        _ = self.forward.write(self.last_seq.bytes())


fn new_default_writer() -> Writer:
    var buf = buffer.new_buffer()
    return Writer(buf^)
