from external.gojo.builtins._bytes import Bytes

alias Marker = "\x1B"
alias Rune = Int32


fn is_terminator(c: Int8) -> Bool:
    return (c >= 0x40 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A)


fn len_without_ansi(s: String) -> Int:
    """Returns the length of a string without ANSI escape codes."""
    var length = 0
    var in_ansi = False
    for i in range(len(s)):
        var char = s[i]
        if char == "\x1b":
            in_ansi = True
        elif in_ansi and char == "m":
            in_ansi = False
        elif not in_ansi:
            length += 1
    return length


fn len_without_ansi(s: Bytes) -> Int:
    """Returns the length of a string without ANSI escape codes."""
    var length = 0
    var in_ansi = False
    for i in range(len(s)):
        var char = s[i]
        if char == ord(Marker):
            in_ansi = True
        elif in_ansi and char == ord("m"):
            in_ansi = False
        elif not in_ansi:
            length += 1
    return length


# TODO: Not actual rune length until utf8 encoding is implemented
fn printable_rune_width(s: String) -> Int:
    """Returns the cell width of the given string."""
    var n: Int = 0
    var ansi: Bool = False

    for i in range(len(s)):
        var c = s[i]
        if c == Marker:
            # ANSI escape sequence
            ansi = True
        elif ansi:
            if is_terminator(ord(c)):
                # ANSI sequence terminated
                ansi = False
        else:
            n += len(c)

    return n
