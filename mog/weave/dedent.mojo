from .gojo.buffers import _buffer
from .gojo.buffers._bytes import Byte
from .gojo.stdlib_extensions.builtins import bytes


# String automatically detects the maximum indentation shared by all lines and
# trims them accordingly.
fn string(s: String) raises -> String:
    let indent = min_indent(s)
    if indent == 0:
        return s

    return dedent(s, indent)


fn min_indent(s: String) -> Int:
    var cur_indent: Int = 0
    var min_indent: Int = 0
    var should_append = True
    var i: Int = 0

    while i < len(s):
        if s[i] == "\t" or s[i] == " ":
            if should_append:
                cur_indent += 1
        elif s[i] == "\n":
            cur_indent = 0
            should_append = True
        else:
            if cur_indent > 0 and (min_indent == 0 or cur_indent < min_indent):
                min_indent = cur_indent
                cur_indent = 0
            should_append = False

        i += 1

    return min_indent


fn dedent(s: String, indent: Int) raises -> String:
    var omitted: Int = 0
    var vec: bytes = bytes()
    var buf = _buffer.new_buffer(buf=vec)
    var i: Int = 0

    while i < len(s):
        if s[i] == "\t" or s[i] == " ":
            if omitted < indent:
                omitted += 1
            else:
                _ = buf.write_byte(ord(s[i]))
        elif s[i] == "\n":
            omitted = 0
            _ = buf.write_byte(ord(s[i]))
        else:
            _ = buf.write_byte(ord(s[i]))

        i += 1

    return buf.string()
