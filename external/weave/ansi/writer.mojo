from external.gojo.bytes import buffer
from external.gojo.builtins import Result
from external.gojo.builtins.bytes import Byte, has_suffix
from external.gojo.io import traits as io
from .ansi import Marker, is_terminator


@value
struct Writer(io.Writer):
    var forward: buffer.Buffer
    var ansi: Bool
    var ansi_seq: buffer.Buffer
    var last_seq: buffer.Buffer
    var seq_changed: Bool
    # var rune_buf: List[Byte]

    fn __init__(inout self, owned forward: buffer.Buffer):
        self.forward = forward
        self.ansi = False
        self.ansi_seq = buffer.new_buffer()
        self.last_seq = buffer.new_buffer()
        self.seq_changed = False
        # self.rune_buf = List[Byte](capacity=4096)

    # write is used to write content to the ANSI buffer.
    fn write(inout self, src: List[Byte]) -> Result[Int]:
        """TODO: Writing List[Byte] instead of encoded runes rn."""
        for i in range(len(src)):
            var char = chr(int(src[i]))
            # TODO: Skipping null terminator List[Byte] for now until I figure out how to deal with them. They come from the empty spaces in a List
            if src[i] == 0:
                pass
            elif char == Marker:
                # ANSI escape sequence
                self.ansi = True
                self.seq_changed = True
                _ = self.ansi_seq.write_byte(src[i])
            elif self.ansi:
                _ = self.ansi_seq.write_byte(src[i])
                if is_terminator(src[i]):
                    self.ansi = False

                    if has_suffix(self.ansi_seq.bytes(), String("[0m").as_bytes()):
                        # reset sequence
                        self.last_seq.reset()
                        self.seq_changed = False
                    elif char == "m":
                        # color code
                        _ = self.last_seq.write(self.ansi_seq.bytes())

                    _ = self.ansi_seq.write_to(self.forward)
            else:
                _ = self.write_byte(src[i])

        return len(src)

    fn write_byte(inout self, byte: Byte) -> Int:
        _ = self.forward.write_byte(byte)
        return 1

    # fn writeRune(r rune) (Int, error)
    #     if self.runeBuf == nil
    #         self.runeBuf = make(List[Byte], utf8.UTFMax)
    #
    #     n := utf8.EncodeRune(self.runeBuf, r)
    #     return self.Forward.write(self.runeBuf[:n])
    #

    fn last_sequence(self) -> String:
        return str(self.last_seq)

    fn reset_ansi(inout self):
        if not self.seq_changed:
            return
        var ansi_code = String("\x1b[0m").as_bytes()
        var b = List[Byte](capacity=512)
        for i in range(len(ansi_code)):
            b[i] = ansi_code[i]
        _ = self.forward.write(b)

    fn restore_ansi(inout self):
        _ = self.forward.write(self.last_seq.bytes())


fn new_default_writer() -> Writer:
    var buf = buffer.new_buffer()
    return Writer(buf ^)
