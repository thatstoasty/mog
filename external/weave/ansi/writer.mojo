from external.gojo.bytes import buffer
from external.gojo.builtins.bytes import has_suffix
from external.gojo.unicode import UnicodeString
from .ansi import Marker, is_terminator


alias ANSI_ESCAPE = String("[0m").as_bytes()
alias ANSI_RESET = String("\x1b[0m").as_bytes()


struct Writer:
    """A writer that handles ANSI escape sequences in the content.

    Example Usage:
    ```mojo
    from weave import ansi

    fn main():
        var writer = ansi.Writer()
        _ = writer.write("Hello, World!".as_bytes_slice())
        print(str(writer.forward))
    ```
    .
    """

    var forward: buffer.Buffer
    """The buffer that stores the text content."""
    var ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""
    var ansi_seq: buffer.Buffer
    """The buffer that stores the ANSI escape sequence."""
    var last_seq: buffer.Buffer
    """The buffer that stores the last ANSI escape sequence."""
    var seq_changed: Bool
    """Whether the ANSI escape sequence has changed."""

    fn __init__(inout self, owned forward: buffer.Buffer = buffer.new_buffer()):
        """Initializes a new ANSI-writer instance.

        Args:
            forward: The buffer that stores the text content.
        """
        self.forward = forward^
        self.ansi = False
        self.ansi_seq = buffer.new_buffer(128)
        self.last_seq = buffer.new_buffer(128)
        self.seq_changed = False

    fn __moveinit__(inout self, owned other: Writer):
        self.forward = other.forward^
        self.ansi = other.ansi
        self.ansi_seq = other.ansi_seq^
        self.last_seq = other.last_seq^
        self.seq_changed = other.seq_changed

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Write content to the ANSI buffer.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        for rune in UnicodeString(src):
            var char = String(rune)
            if char == Marker:
                # ANSI escape sequence
                self.ansi = True
                self.seq_changed = True
                _ = self.ansi_seq._write(char.as_bytes_slice())
            elif self.ansi:
                _ = self.ansi_seq._write(char.as_bytes_slice())
                if is_terminator(ord(char)):
                    self.ansi = False

                    if has_suffix(self.ansi_seq.bytes(), ANSI_ESCAPE):
                        # reset sequence
                        self.last_seq.reset()
                        self.seq_changed = False
                    elif char == "m":
                        # color code
                        _ = self.last_seq._write(self.ansi_seq.as_bytes_slice())

                    _ = self.ansi_seq.write_to(self.forward)
            else:
                _ = self.forward._write(char.as_bytes_slice())

        return len(src), Error()

    fn write_byte(inout self, byte: UInt8) -> Int:
        """Write a byte to the ANSI buffer.

        Args:
            byte: The byte to write.

        Returns:
            The number of bytes written.
        """
        _ = self.forward.write_byte(byte)
        return 1

    fn last_sequence(self) -> String:
        """Returns the last ANSI escape sequence."""
        return str(self.last_seq)

    fn reset_ansi(inout self):
        """Resets the ANSI escape sequence."""
        if not self.seq_changed:
            return
        var b = List[UInt8](capacity=512)
        for i in range(len(ANSI_RESET)):
            b[i] = ANSI_RESET[i]
        _ = self.forward.write(b)

    fn restore_ansi(inout self):
        """Restores the last ANSI escape sequence."""
        _ = self.forward._write(self.last_seq.as_bytes_slice())
