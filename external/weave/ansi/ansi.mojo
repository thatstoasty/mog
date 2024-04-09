from external.gojo.builtins import Byte
from algorithm.functional import vectorize
from memory.unsafe import DTypePointer
from sys.info import simdwidthof

alias simd_width_u8 = simdwidthof[DType.uint8]()


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

    # TODO: Can't iterate over runes yet, so find the length of ansi characters and subtract from rune count of string.
    var difference = len(s) - length

    return rune_count_in_string(s) - difference


fn rune_count_in_string(s: String) -> Int:
    var p = s._as_ptr().bitcast[DType.uint8]()
    var string_byte_length = len(s)
    var result = 0

    @parameter
    fn count[simd_width: Int](offset: Int):
        result += (
            ((p.load[width=simd_width](offset) >> 6) != 0b10)
            .cast[DType.uint8]()
            .reduce_add()
            .to_int()
        )

    vectorize[count, simd_width_u8](string_byte_length)
    return result


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
            n += rune_count_in_string(c)

    return n
