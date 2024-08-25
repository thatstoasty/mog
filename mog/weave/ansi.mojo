from .gojo.bytes import buffer
from .gojo.builtins.bytes import has_suffix
from .gojo.unicode import string_width


alias ANSI_ESCAPE = String("[0m").as_bytes()
alias ANSI_RESET = String("\x1b[0m").as_bytes()
alias Marker = "\x1B"


fn is_terminator(c: Int) -> Bool:
    return (c >= 0x40 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A)


fn printable_rune_width(text: String) -> Int:
    """Returns the cell width of the given string.

    Args:
        text: String to calculate the width of.

    Returns:
        The printable cell width of the string.
    """
    var length = 0
    var ansi = False

    for rune in text:
        if rune == Marker:
            # ANSI escape sequence
            ansi = True
        elif ansi:
            if is_terminator(ord(String(rune))):
                # ANSI sequence terminated
                ansi = False
        else:
            length += string_width(rune)

    return length


struct Writer:
    """A writer that handles ANSI escape sequences in the content.

    Example Usage:
    ```mojo
    from weave import ansi

    fn main():
        var writer = ansi.Writer()
        _ = writer.write("Hello, World!")
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

    fn __init__(inout self, owned forward: buffer.Buffer = buffer.Buffer()):
        """Initializes a new ANSI-writer instance.

        Args:
            forward: The buffer that stores the text content.
        """
        self.forward = forward^
        self.ansi = False
        self.ansi_seq = buffer.Buffer(capacity=128)
        self.last_seq = buffer.Buffer(capacity=128)
        self.seq_changed = False

    fn __moveinit__(inout self, owned other: Writer):
        self.forward = other.forward^
        self.ansi = other.ansi
        self.ansi_seq = other.ansi_seq^
        self.last_seq = other.last_seq^
        self.seq_changed = other.seq_changed

    fn write(inout self, src: String) -> (Int, Error):
        """Write content to the ANSI buffer.

        Args:
            src: The content to write.

        Returns:
            The number of bytes written and optional error.
        """
        for char in src:
            if char == Marker:
                # ANSI escape sequence
                self.ansi = True
                self.seq_changed = True
                _ = self.ansi_seq.write(char.as_bytes_slice())
            elif self.ansi:
                _ = self.ansi_seq.write(char.as_bytes_slice())
                if is_terminator(ord(char)):
                    self.ansi = False

                    if has_suffix(self.ansi_seq.bytes(), ANSI_ESCAPE):
                        # reset sequence
                        self.last_seq.reset()
                        self.seq_changed = False
                    elif char == "m":
                        # color code
                        _ = self.last_seq.write(self.ansi_seq.as_bytes_slice())

                    _ = self.ansi_seq.write_to(self.forward)
            else:
                _ = self.forward.write(char.as_bytes_slice())

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
        _ = self.forward.write(self.last_seq.as_bytes_slice())
