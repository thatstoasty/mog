from external.gojo.bytes import buffer
from external.gojo.builtins import Byte
from .ansi import printable_rune_width


fn apply_dedent(owned s: String) -> String:
    """Automatically detects the maximum indentation shared by all lines and
    trims them accordingly.

    Args:
        s: The string to dedent.

    Returns:
        The dedented string.
    """
    var indent = min_indent(s)
    if indent == 0:
        return s

    return dedent(s, indent)


fn min_indent(s: String) -> Int:
    var cur_indent: Int = 0
    var min_indent: Int = 0
    var should_append = True
    var i: Int = 0

    var s_bytes = s.as_bytes()
    while i < len(s_bytes):
        if s_bytes[i] == ord("\t") or s_bytes[i] == ord(" "):
            if should_append:
                cur_indent += 1
        elif s_bytes[i] == ord("\n"):
            cur_indent = 0
            should_append = True
        else:
            if cur_indent > 0 and (min_indent == 0 or cur_indent < min_indent):
                min_indent = cur_indent
                cur_indent = 0
            should_append = False

        i += 1

    return min_indent


fn dedent(s: String, indent: Int) -> String:
    var omitted: Int = 0
    var buf = buffer.new_buffer()
    var i: Int = 0

    var s_bytes = s.as_bytes()
    while i < len(s_bytes):
        if s_bytes[i] == ord("\t") or s_bytes[i] == ord(" "):
            if omitted < indent:
                omitted += 1
            else:
                _ = buf.write_byte(s_bytes[i])
        elif s_bytes[i] == ord("\n"):
            omitted = 0
            _ = buf.write_byte(s_bytes[i])
        else:
            _ = buf.write_byte(s_bytes[i])

        i += 1

    return str(buf)
