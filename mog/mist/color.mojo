from collections.dict import Dict, KeyElement
from utils.variant import Variant
from .hue import RGB, max_float64
from .ansi_colors import AnsiHex


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s


alias foreground = "38"
alias background = "48"
alias AnyColor = Variant[NoColor, ANSIColor, ANSI256Color, RGBColor]


trait Equalable:
    fn __eq__(self: Self, other: Self) -> Bool:
        ...


trait NotEqualable:
    fn __ne__(self: Self, other: Self) -> Bool:
        ...


trait Color(Movable, Copyable, Equalable, NotEqualable, CollectionElement):
    fn sequence(self, is_background: Bool) raises -> String:
        """Sequence returns the ANSI Sequence for the color."""
        ...


@value
struct NoColor(Color):
    fn __eq__(self, other: NoColor) -> Bool:
        return True

    fn __ne__(self, other: NoColor) -> Bool:
        return False

    fn sequence(self, is_background: Bool) raises -> String:
        return ""

    fn string(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ""


@value
struct ANSIColor(Color):
    """ANSIColor is a color (0-15) as defined by the ANSI Standard."""

    var value: Int

    fn __eq__(self, other: ANSIColor) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: ANSIColor) -> Bool:
        return self.value != other.value

    fn sequence(self, is_background: Bool) raises -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var modifier: Int = 0
        if is_background:
            modifier += 10

        if self.value < 8:
            return String(modifier + self.value + 30)
        else:
            return String(modifier + self.value - 8 + 90)

    fn string(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return AnsiHex().values[self.value]

    fn convert_to_rgb(self) raises -> RGB:
        """Converts an ANSI color to RGB by looking up the hex value and converting it.
        """
        let hex: String = AnsiHex().values[self.value]

        return hex_to_rgb(hex)


@value
struct ANSI256Color(Color):
    """ANSI256Color is a color (16-255) as defined by the ANSI Standard."""

    var value: Int

    fn __eq__(self, other: ANSI256Color) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: ANSI256Color) -> Bool:
        return self.value != other.value

    fn sequence(self, is_background: Bool) raises -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var prefix: String = foreground
        if is_background:
            prefix = background

        return prefix + ";5;" + String(self.value)

    fn string(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return AnsiHex().values[self.value]

    fn convert_to_rgb(self) raises -> RGB:
        """Converts an ANSI color to RGB by looking up the hex value and converting it.
        """
        let hex: String = AnsiHex().values[self.value]

        return hex_to_rgb(hex)


# fn convert_base10_to_base16(value: Int) raises -> String:
#     """Converts a base 10 number to base 16."""
#     var sum: Int = value
#     while value > 1:
#         let remainder = sum % 16
#         sum = sum / 16
#         print(remainder, sum)

#         print(remainder * 16)


fn convert_base16_to_base10(value: String) raises -> Int:
    """Converts a base 16 number to base 10.
    https://www.catalyst2.com/knowledgebase/dictionary/hexadecimal-base-16-numbers/#:~:text=To%20convert%20the%20hex%20number,16%20%2B%200%20%3D%2016).
    """
    var mapping = Dict[StringKey, Int]()
    mapping["0"] = 0
    mapping["1"] = 1
    mapping["2"] = 2
    mapping["3"] = 3
    mapping["4"] = 4
    mapping["5"] = 5
    mapping["6"] = 6
    mapping["7"] = 7
    mapping["8"] = 8
    mapping["9"] = 9
    mapping["a"] = 10
    mapping["b"] = 11
    mapping["c"] = 12
    mapping["d"] = 13
    mapping["e"] = 14
    mapping["f"] = 15

    let length = len(value)
    var sum: Int = 0
    for i in range(length - 1, -1, -1):
        let exponent = length - 1 - i
        sum += mapping[value[i]] * (16**exponent)

    return sum


fn hex_to_rgb(value: String) raises -> RGB:
    """Converts a hex color to RGB.

    Args:
        value: Hex color value.

    Returns:
        RGB color.
    """
    let hex = value[1:]
    var indices = DynamicVector[Int]()
    indices.append(0)
    indices.append(2)
    indices.append(4)

    var results = DynamicVector[Int]()

    for i in range(len(indices)):
        let base_10 = convert_base16_to_base10(hex[indices[i] : indices[i] + 2])
        results.append(atol(base_10))

    return RGB(results[0], results[1], results[2])


@value
struct RGBColor(Color):
    """RGBColor is a hex-encoded color, e.g. '#abcdef'."""

    var value: String

    fn __init__(inout self, value: String):
        self.value = value.tolower()

    fn __eq__(self, other: RGBColor) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: RGBColor) -> Bool:
        return self.value != other.value

    fn sequence(self, is_background: Bool) raises -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        let rgb = hex_to_rgb(self.value)

        var prefix = foreground
        if is_background:
            prefix = background

        return (
            prefix
            + String(";2;")
            + String(int(rgb.R))
            + ";"
            + String(int(rgb.G))
            + ";"
            + String(int(rgb.B))
        )

    fn convert_to_rgb(self) raises -> RGB:
        """Converts the Hex code value to RGB."""
        return hex_to_rgb(self.value)


fn ansi256_to_ansi(value: Int) raises -> ANSIColor:
    """Converts an ANSI256 color to an ANSI color.

    Args:
        value: ANSI256 color value.
    """
    var r: Int = 0
    var md = max_float64()

    let h = hex_to_rgb(AnsiHex().values[value])

    var i: Int = 0
    while i <= 15:
        let hb = hex_to_rgb(AnsiHex().values[i])
        let d = h.distance_HSLuv(hb)

        if d < md:
            md = d
            r = i

        i += 1

    return ANSIColor(r)


fn v2ci(value: Float64) -> Int:
    if value < 48:
        return 0
    elif value < 115:
        return 1
    else:
        return int((value - 35) / 40)


fn hex_to_ansi256(color: RGB) -> ANSI256Color:
    """Converts a hex code to a ANSI256 color.

    Args:
        color: RGB hex code.
    """
    # Calculate the nearest 0-based color index at 16..231
    # Originally had * 255 in each of these
    let r: Float64 = v2ci(color.R)  # 0..5 each
    let g: Float64 = v2ci(color.G)
    let b: Float64 = v2ci(color.B)
    let ci: Int = int((36 * r) + (6 * g) + b)  # 0..215

    # Calculate the represented colors back from the index
    var i2cv: DynamicVector[Int] = DynamicVector[Int]()
    i2cv.append(0)
    i2cv.append(0x5F)
    i2cv.append(0x87)
    i2cv.append(0xAF)
    i2cv.append(0xD7)
    i2cv.append(0xFF)
    let cr = i2cv[int(r)]  # r/g/b, 0..255 each
    let cg = i2cv[int(g)]
    let cb = i2cv[int(b)]

    # Calculate the nearest 0-based gray index at 232..255
    let grayIdx: Int
    let average = (r + g + b) / 3
    if average > 238:
        grayIdx = 23
    else:
        grayIdx = int((average - 3) / 10)  # 0..23
    let gv = 8 + 10 * grayIdx  # same value for r/g/b, 0..255

    # Return the one which is nearer to the original input rgb value
    # Originall had / 255.0 for r, g, and b in each of these
    let c2 = RGB(cr, cg, cb)
    let g2 = RGB(gv, gv, gv)
    let color_dist = color.distance_HSLuv(c2)
    let gray_dist = color.distance_HSLuv(g2)

    if color_dist <= gray_dist:
        return ANSI256Color(16 + ci)
    return ANSI256Color(232 + grayIdx)
