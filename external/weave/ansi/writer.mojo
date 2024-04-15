from math.bit import ctlz
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
        # Rune iterator
        var bytes = len(src)
        var p = DTypePointer[DType.int8](src.data.value).bitcast[DType.uint8]()
        while bytes > 0:
            var char_length = (
                (p.load() >> 7 == 0).cast[DType.uint8]() * 1 + ctlz(~p.load())
            ).to_int()
            var sp = DTypePointer[DType.int8].alloc(char_length + 1)
            memcpy(sp, p.bitcast[DType.int8](), char_length)
            sp[char_length] = 0

            # Functional logic
            var char = String(sp, char_length + 1)
            if char == Marker:
                # ANSI escape sequence
                self.ansi = True
                self.seq_changed = True
                _ = self.ansi_seq.write_string(char)
            elif self.ansi:
                _ = self.ansi_seq.write_string(char)
                if is_terminator(ord(char)):
                    self.ansi = False

                    if has_suffix(
                        self.ansi_seq.bytes(), String("[0m").as_bytes()
                    ):
                        # reset sequence
                        self.last_seq.reset()
                        self.seq_changed = False
                    elif char == "m":
                        # color code
                        _ = self.last_seq.write(self.ansi_seq.bytes())

                    _ = self.ansi_seq.write_to(self.forward)
            else:
                var result = self.forward.write_string(char)

            # move forward iterator
            bytes -= char_length
            p += char_length

        # TODO: Should this be returning just len(src)?
        return len(src)

    fn write_byte(inout self, byte: Byte) -> Int:
        _ = self.forward.write_byte(byte)
        return 1

    # fn write_rune(inout self, rune: String) -> Result[Int]:
    #     return self.forward.write(self.runeBuf[:n])

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
    return Writer(buf^)
