from utils import Span
from .gojo.bytes import Buffer


fn dedent(text: String) -> String:
    """Automatically detects the maximum indentation shared by all lines and
    trims them accordingly.

    Args:
        text: The string to dedent.

    Returns:
        The dedented string.

    Example Usage:
    ```mojo
    from weave import dedent

    fn main() -> None:
        var text = dedent("    Hello, World!\\n    This is a test.\\n    \\n")
        print(text)
    ```
    .
    """
    var indent = min_indent(text.as_bytes_slice())
    if indent == 0:
        return text

    return apply_dedent(text.as_bytes_slice(), indent)


fn min_indent(bytes: Span[UInt8]) -> Int:
    """Detects the indentation level shared by all lines.

    Args:
        bytes: The text to dedent as as bytes slice.

    Returns:
        The minimum indentation level.
    """
    var cur_indent = 0
    var min_indent = 0
    var should_append = True
    var i = 0

    while i < len(bytes):
        if bytes[i] == TAB_BYTE or bytes[i] == SPACE_BYTE:
            if should_append:
                cur_indent += 1
        elif bytes[i] == NEWLINE_BYTE:
            cur_indent = 0
            should_append = True
        else:
            if cur_indent > 0 and (min_indent == 0 or cur_indent < min_indent):
                min_indent = cur_indent
                cur_indent = 0
            should_append = False

        i += 1

    return min_indent


fn apply_dedent(bytes: Span[UInt8], indent: Int) -> String:
    """Dedents a string by removing the shared indentation level.

    Args:
        bytes: The text to dedent as as bytes slice.
        indent: The number of spaces to remove from the beginning of each line.

    Returns:
        A new dedented string.
    """
    var omitted = 0
    var buf = Buffer()
    var i = 0

    while i < len(bytes):
        if bytes[i] == TAB_BYTE or bytes[i] == SPACE_BYTE:
            if omitted < indent:
                omitted += 1
            else:
                _ = buf.write_byte(bytes[i])
        elif bytes[i] == NEWLINE_BYTE:
            omitted = 0
            _ = buf.write_byte(bytes[i])
        else:
            _ = buf.write_byte(bytes[i])

        i += 1

    return str(buf)
