from mog.external.weave.gojo.bytes import buffer
from mog.external.weave.gojo.bytes.bytes import Byte, has_suffix
from mog.external.weave.ansi.ansi import Marker, is_terminator


@value
struct Writer:
    var forward: buffer.Buffer
    var ansi: Bool
    var ansi_seq: buffer.Buffer
    var last_seq: buffer.Buffer
    var seq_changed: Bool
    var rune_buf: DynamicVector[Byte]

    fn __init__(inout self, inout forward: buffer.Buffer) raises:
        self.forward = forward
        self.ansi = False
        var ansi_buf = DynamicVector[Byte]()
        var last_buf = DynamicVector[Byte]()
        self.ansi_seq = buffer.Buffer(buf=ansi_buf)
        self.last_seq = buffer.Buffer(buf=last_buf)
        self.seq_changed = False
        self.rune_buf = DynamicVector[Byte]()

    # write is used to write content to the ANSI buffer.
    fn write(inout self, b: DynamicVector[Byte]) raises -> Int:
        """TODO: Writing bytes instead of encoded runes rn."""
        for i in range(len(b)):
            let char = chr(int(b[i]))
            # TODO: Skipping null terminator bytes for now until I figure out how to deal with them. They come from the empty spaces in a dynamicvector
            if b[i] == 0:
                pass
            elif char == Marker:
                # ANSI escape sequence
                self.ansi = True
                self.seq_changed = True
                _ = self.ansi_seq.write_byte(b[i])
            elif self.ansi:
                _ = self.ansi_seq.write_byte(b[i])
                if is_terminator(b[i]):
                    self.ansi = False

                    if has_suffix(self.ansi_seq.bytes(), (String("[0m")._buffer)):
                        # reset sequence
                        self.last_seq.reset()
                        self.seq_changed = False
                    elif char == "m":
                        # color code
                        _ = self.last_seq.write(self.ansi_seq.bytes())

                    _ = self.ansi_seq.write_to(self.forward)
            else:
                _ = self.write_byte(b[i])

        return len(b)

    fn write_byte(inout self, b: Byte) raises -> Int:
        _ = self.forward.write_byte(b)
        return 1

    # fn writeRune(r rune) (Int, error)
    #     if self.runeBuf == nil
    #         self.runeBuf = make(DynamicVector[Byte], utf8.UTFMax)
    #
    #     n := utf8.EncodeRune(self.runeBuf, r)
    #     return self.Forward.write(self.runeBuf[:n])
    #

    fn last_sequence(self) -> String:
        return self.last_seq.string()

    fn reset_ansi(inout self) raises:
        if not self.seq_changed:
            return
        let ansi_code = String("\x1b[0m")._buffer
        var b = DynamicVector[Byte]()
        for i in range(len(ansi_code)):
            b.append(ansi_code[i])
        _ = self.forward.write(b)

    fn restore_ansi(inout self) raises:
        _ = self.forward.write(self.last_seq.bytes())
