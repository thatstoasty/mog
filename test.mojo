from mog.border import rounded_border

alias Marker = "\x1B"


fn is_terminator(c: Int8) -> Bool:
    return (c >= 0x40 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A)


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

    return 1  # Assume all characters have a printable length of 1 for now


from algorithm.functional import vectorize
from memory.unsafe import DTypePointer
from sys.info import simdwidthof


alias simd_width_u8 = simdwidthof[DType.uint8]()


fn chars_count(s: String) -> Int:
    var p = s._as_ptr().bitcast[DType.uint8]()
    var string_byte_length = len(s)
    var result = 0

    @parameter
    fn count[simd_width: Int](offset: Int):
        result += (
            ((p.simd_load[simd_width](offset) >> 6) != 0b10)
            .cast[DType.uint8]()
            .reduce_add()
            .to_int()
        )

    vectorize[count, simd_width_u8](string_byte_length)
    return result


fn main():
    # var corner: String = "╭"
    # for i in corner.as_bytes():
    #     print(i[])

    var border = rounded_border()
    # for i in border.middle_top.as_bytes():
    #     print(i[])
    print(chars_count("╭"))
    # print(String(corner._buffer))
    # var vector = DynamicVector[Int8]()
    # vector.append(32)
    # vector.append(32)
    # vector.append(32)
    # vector.append(-30)
    # vector.append(-108)
    # vector.append(-84)
    # vector.append(0)
    # print(String(vector))
