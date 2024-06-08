from bit import countl_zero
from external.gojo.unicode import rune_count_in_string, UnicodeString

alias Marker = "\x1B"


fn is_terminator(c: UInt8) -> Bool:
    return (c >= 0x40 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A)


fn printable_rune_width(s: String) -> Int:
    """Returns the cell width of the given string.

    Args:
        s: String to calculate the width of.
    """
    var length: Int = 0
    var ansi: Bool = False

    var uni_str = UnicodeString(s)
    for char in uni_str:
        if char == Marker:
            # ANSI escape sequence
            ansi = True
        elif ansi:
            if is_terminator(ord(char)):
                # ANSI sequence terminated
                ansi = False
        else:
            length += rune_count_in_string(char)

    return length


fn printable_rune_width(s: List[UInt8]) -> Int:
    """Returns the cell width of the given string.

    Args:
        s: List of bytes to calculate the width of.
    """
    var length: Int = 0
    var ansi: Bool = False

    var uni_str = UnicodeString(s)
    for char in uni_str:
        if char == Marker:
            # ANSI escape sequence
            ansi = True
        elif ansi:
            if is_terminator(ord(char)):
                # ANSI sequence terminated
                ansi = False
        else:
            length += rune_count_in_string(char)

    return length
