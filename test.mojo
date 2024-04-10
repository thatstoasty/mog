from mog.border import rounded_border

alias Marker = "\x1B"


fn is_terminator(c: Int8) -> Bool:
    return (c >= 0x40 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A)


# TODO: Not actual rune length until utf8 encoding is implemented
fn printable_rune_width(s: String) -> Int:
    """Returns the cell width of the given string."""
    var n: Int = 0
    var ansi: Bool = False
    var bytes = s.as_bytes()

    for i in range(len(bytes)):
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

    return n  # Assume all characters have a printable length of 1 for now


from algorithm.functional import vectorize
from memory.unsafe import DTypePointer
from sys.info import simdwidthof


alias simd_width_u8 = simdwidthof[DType.uint8]()


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


# The default lowest and highest continuation byte.
alias locb = 0b10000000
alias hicb = 0b10111111
alias RUNE_SELF = 0x80  # Characters below RuneSelf are represented as themselves in a single byte


# acceptRange gives the range of valid values for the second byte in a UTF-8
# sequence.
@value
struct AcceptRange(CollectionElement):
    var lo: UInt8  # lowest value for second byte.
    var hi: UInt8  # highest value for second byte.


# ACCEPT_RANGES has size 16 to avoid bounds checks in the code that uses it.
alias ACCEPT_RANGES = List[AcceptRange](
    AcceptRange(locb, hicb),
    AcceptRange(0xA0, hicb),
    AcceptRange(locb, 0x9F),
    AcceptRange(0x90, hicb),
    AcceptRange(locb, 0x8F),
)

# These names of these constants are chosen to give nice alignment in the
# table below. The first nibble is an index into acceptRanges or F for
# special one-byte cases. The second nibble is the Rune length or the
# Status for the special one-byte case.
alias xx = 0xF1  # invalid: size 1
alias as1 = 0xF0  # ASCII: size 1
alias s1 = 0x02  # accept 0, size 2
alias s2 = 0x13  # accept 1, size 3
alias s3 = 0x03  # accept 0, size 3
alias s4 = 0x23  # accept 2, size 3
alias s5 = 0x34  # accept 3, size 4
alias s6 = 0x04  # accept 0, size 4
alias s7 = 0x44  # accept 4, size 4


# first is information about the first byte in a UTF-8 sequence.
var first = List[UInt8](
    #   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x00-0x0F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x10-0x1F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x20-0x2F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x30-0x3F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x40-0x4F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x50-0x5F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x60-0x6F
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,
    as1,  # 0x70-0x7F
    #   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,  # 0x80-0x8F
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,  # 0x90-0x9F
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,  # 0xA0-0xAF
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,  # 0xB0-0xBF
    xx,
    xx,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,  # 0xC0-0xCF
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,
    s1,  # 0xD0-0xDF
    s2,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s3,
    s4,
    s3,
    s3,  # 0xE0-0xEF
    s5,
    s6,
    s6,
    s6,
    s7,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,
    xx,  # 0xF0-0xFF
)


# RuneCountInString is like [RuneCount] but its input is a string.
fn RuneCountInString(s: String) -> Int:
    var ns = len(s)
    var i = 0
    var n = 0
    while i < ns:
        var c = new_ord(s[i])
        # print(c)
        if new_ord(c) < RUNE_SELF:
            # ASCII fast path
            i += 1
            n += 1
            continue

        var x = first[new_ord(c)]
        if x == xx:
            i += 1  # invalid.
            n += 1
            continue

        var size = int(x & 7)
        if i + size > ns:
            i += 1  # Short or invalid.
            n += 1
            continue

        var accept = ACCEPT_RANGES[int(x >> 4)]
        var c1 = new_ord(s[i + 1])
        var c2 = new_ord(s[i + 2])
        var c3 = new_ord(s[i + 3])
        if c1 < int(accept.lo) or accept.hi < c1:
            size = 1
        elif size == 2:
            pass
        elif c2 < locb or hicb < c2:
            size = 1
        elif size == 3:
            pass
        elif c3 < locb or hicb < c3:
            size = 1

        i += size
        n += 1

    print("n", n)
    return n


@always_inline
fn _ctlz(val: Int) -> Int:
    return llvm_intrinsic["llvm.ctlz", Int](val, False)


@always_inline("nodebug")
fn _ctlz(val: SIMD) -> __type_of(val):
    return llvm_intrinsic["llvm.ctlz", __type_of(val)](val, False)


fn new_ord(s: String) -> Int:
    """Returns an integer that represents the given one-character string.

    Given a string representing one character, return an integer
    representing the code point of that character. For example, `ord("a")`
    returns the integer `97`. This is the inverse of the `chr()` function.

    Args:
        s: The input string, which must contain only a single character.

    Returns:
        An integer representing the code point of the given character.
    """
    # UTF-8 to Unicode conversion:              (represented as UInt32 BE)
    # 1: 0aaaaaaa                            -> 00000000 00000000 00000000 0aaaaaaa     a
    # 2: 110aaaaa 10bbbbbb                   -> 00000000 00000000 00000aaa aabbbbbb     a << 6  | b
    # 3: 1110aaaa 10bbbbbb 10cccccc          -> 00000000 00000000 aaaabbbb bbcccccc     a << 12 | b << 6  | c
    # 4: 11110aaa 10bbbbbb 10cccccc 10dddddd -> 00000000 000aaabb bbbbcccc ccdddddd     a << 18 | b << 12 | c << 6 | d
    var p = s._as_ptr().bitcast[DType.uint8]()
    var b1 = p.load()
    if (b1 >> 7) == 0:  # This is 1 byte ASCII char
        debug_assert(len(s) == 1, "input string length must be 1")
        return b1.to_int()
    var num_bytes = _ctlz(~b1)
    debug_assert(
        len(s) == num_bytes.to_int(), "input string must be one character"
    )
    var shift = (6 * (num_bytes - 1)).to_int()
    var b1_mask = 0b11111111 >> (num_bytes + 1)
    var result = (b1 & b1_mask).to_int() << shift
    for i in range(1, num_bytes):
        p += 1
        shift -= 6
        result |= (p.load() & 0b00111111).to_int() << shift
    return result


fn new_chr(c: Int) -> String:
    """Returns a string based on the given Unicode code point.

    Returns the string representing a character whose code point is the integer `c`.
    For example, `chr(97)` returns the string `"a"`. This is the inverse of the `ord()`
    function.

    Args:
        c: An integer that represents a code point.

    Returns:
        A string containing a single character based on the given code point.
    """
    # Unicode (represented as UInt32 BE) to UTF-8 conversion :
    # 1: 00000000 00000000 00000000 0aaaaaaa -> 0aaaaaaa                                a
    # 2: 00000000 00000000 00000aaa aabbbbbb -> 110aaaaa 10bbbbbb                       a >> 6  | 0b11000000, b       | 0b10000000
    # 3: 00000000 00000000 aaaabbbb bbcccccc -> 1110aaaa 10bbbbbb 10cccccc              a >> 12 | 0b11100000, b >> 6  | 0b10000000, c      | 0b10000000
    # 4: 00000000 000aaabb bbbbcccc ccdddddd -> 11110aaa 10bbbbbb 10cccccc 10dddddd     a >> 18 | 0b11110000, b >> 12 | 0b10000000, c >> 6 | 0b10000000, d | 0b10000000

    if (c >> 7) == 0:  # This is 1 byte ASCII char
        var p = DTypePointer[DType.int8].alloc(2)
        p.store(c)
        p.store(1, 0)
        return String(p, 2)

    @always_inline
    fn _utf8_len(val: Int) -> Int:
        debug_assert(val > 0x10FFFF, "Value is not a valid Unicode code point")
        alias sizes = SIMD[DType.int32, 4](
            0, 0b1111_111, 0b1111_1111_111, 0b1111_1111_1111_1111
        )
        var values = SIMD[DType.int32, 4](val)
        var mask = values > sizes
        return mask.cast[DType.uint8]().reduce_add().to_int()

    var num_bytes = _utf8_len(c)
    var p = DTypePointer[DType.uint8].alloc(num_bytes + 1)
    var shift = 6 * (num_bytes - 1)
    var mask = UInt8(0xFF) >> (num_bytes + 1)
    var num_bytes_marker = UInt8(0xFF) << (8 - num_bytes)
    p.store(((c >> shift) & mask) | num_bytes_marker)
    for i in range(1, num_bytes):
        shift -= 6
        p.store(i, ((c >> shift) & 0b00111111) | 0b10000000)
    p.store(num_bytes, 0)
    return String(p.bitcast[DType.int8](), num_bytes + 1)


fn _utf8_len(val: Int) -> Int:
    debug_assert(val > 0x10FFFF, "Value is not a valid Unicode code point")
    alias sizes = SIMD[DType.int32, 4](
        0, 0b1111_111, 0b1111_1111_111, 0b1111_1111_1111_1111
    )
    var values = SIMD[DType.int32, 4](val)
    var mask = values > sizes
    return mask.cast[DType.uint8]().reduce_add().to_int()


fn shift(s: String) -> Int:
    var p = s._as_ptr().bitcast[DType.uint8]()
    var b1 = p.load()
    if (b1 >> 7) == 0:  # This is 1 byte ASCII char
        debug_assert(len(s) == 1, "input string length must be 1")
        return b1.to_int()

    var num_bytes = _ctlz(~b1)

    debug_assert(
        len(s) == num_bytes.to_int(), "input string must be one character"
    )
    var shift = (6 * (num_bytes - 1)).to_int()
    var b1_mask = 0b11111111 >> (num_bytes + 1)
    var result = (b1 & b1_mask).to_int() << shift
    for i in range(1, num_bytes):
        p += 1
        shift -= 6
        result |= (p.load() & 0b00111111).to_int() << shift
    return result


fn main():
    # var corner: String = "╭"
    # for i in corner.as_bytes():
    #     print(i[])

    # var border = rounded_border()
    # for i in border.middle_top.as_bytes():
    #     print(i[])
    # print(rune_count_in_string("╭╭╭"))
    # print(ord("╭"))
    # print(rune_count_in_string("こんにちは, 世界!"))
    # print(new_ord("🔥"))
    var text = String("🔥e🔥")
    print(shift(text))
    # var b = text.as_bytes()
    # var b_ptr = text._as_ptr().bitcast[DType.uint8]()
    # print("b ptr")
    # var val = b_ptr.load()
    # for i in range(len(b_ptr)):
    #     print(b_ptr[i])
    # print(String(b))
    # for i in range(len(b)):
    #     print(b[i])
    # print(new_chr(128293))
    # var text: String = "こんにちは, 世界!"
    # for i in range(rune_count_in_string(text)):
    #     print(text[i])

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
