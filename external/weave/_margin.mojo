from external.gojo.bytes import buffer
import . _padding as padding
import . _indent as indent


struct Writer(Stringable, Movable):
    """A margin writer that applies a margin to the content.

    Example Usage:
    ```mojo
    from weave import _margin as margin

    fn main():
        var writer = margin.Writer(5, 2)
        _ = writer.write("Hello, World!".as_bytes_slice())
        _ = writer.close()
        print(String(writer.as_string_slice()))
    ```
    .
    """

    var buf: buffer.Buffer
    var pw: padding.Writer
    var iw: indent.Writer

    fn __init__(inout self, owned pw: padding.Writer, owned iw: indent.Writer):
        """Initializes a new margin-writer instance.

        Args:
            pw: The padding-writer instance.
            iw: The indent-writer instance.
        """
        self.buf = buffer.new_buffer()
        self.pw = pw^
        self.iw = iw^

    fn __init__(inout self, pad: Int, indentation: Int):
        """Initializes a new margin-writer instance.

        Args:
            pad: Width of the padding of the padding-writer instance.
            indentation: Width of the indentation of the padding-writer instance.
        """
        self.buf = buffer.new_buffer()
        self.pw = padding.Writer(pad)
        self.iw = indent.Writer(indentation)

    fn __moveinit__(inout self, owned other: Self):
        self.buf = other.buf^
        self.pw = other.pw^
        self.iw = other.iw^

    fn __str__(self) -> String:
        return str(self.buf)

    fn as_bytes(self) -> List[UInt8]:
        """Returns the wrapped result as a byte list."""
        return self.buf.bytes()

    fn as_bytes_slice(self: Reference[Self]) -> Span[UInt8, self.is_mutable, self.lifetime]:
        """Returns the  wrapped result as a byte slice."""
        return self[].buf.as_bytes_slice()

    fn as_string_slice(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """Returns the wrapped result as a string slice."""
        return StringSlice(unsafe_from_utf8=self[].buf.as_bytes_slice())

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Writes the given byte slice to the writer.

        Args:
            src: The byte slice to write.

        Returns:
            The number of bytes written and optional error.
        """
        var bytes_written = 0
        var err = Error()
        bytes_written, err = self.iw.write(src)
        if err:
            return bytes_written, err

        return self.pw.write(self.iw.as_bytes_slice())

    fn close(inout self):
        """Will finish the margin operation. Always call it before trying to retrieve the final result."""
        _ = self.pw.close()
        _ = self.buf.write(self.pw.as_bytes_slice())


fn apply_margin_to_bytes(span: Span[UInt8], width: UInt8, margin: UInt8) -> List[UInt8]:
    """Shorthand for declaring a new default margin-writer instance,
    used to immediately apply a margin to a byte slice.

    Args:
        span: The byte slice to apply the margin to.
        width: The width of the margin.
        margin: The margin to apply.

    Returns:
        A new margin applied list of bytes.
    """
    var writer = Writer(width, margin)
    _ = writer.write(span)
    _ = writer.close()
    return writer.as_bytes()


fn margin(text: String, width: UInt8, margin: UInt8) -> String:
    """Shorthand for declaring a new default margin-writer instance,
    used to immediately apply a margin to a String.

    Args:
        text: The byte slice to apply the margin to.
        width: The width of the margin.
        margin: The margin to apply.

    Returns:
        A new margin applied string.
    """
    var writer = Writer(width, margin)
    _ = writer.write(text.as_bytes_slice())
    _ = writer.close()
    return String(writer.as_string_slice())
