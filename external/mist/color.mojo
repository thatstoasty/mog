import external.hue
from .ansi_colors import ANSI_HEX_CODES


# Workaround for str() not working at compile time due to using an external_call to c.
fn int_to_str(owned value: Int, base: Int = 10) -> String:
    """Converts an integer to a string.

    Args:
        value: The integer to convert to a string.
        base: The base to convert the integer to.

    Returns:
        The string representation of the integer.
    """
    # Catch edge case of 0
    if value == 0:
        return "0"

    var temp = List[UInt8]()
    var i = 0
    while value > 0:
        temp.append(ord(String("0123456789abcdef")[value % base]))
        i += 1
        value /= 10

    var buffer = List[UInt8]()
    for i in range(len(temp) - 1, -1, -1):
        buffer.append(temp[i])

    buffer.append(0)
    var result = String(buffer^)
    return result


alias FOREGROUND = "38"
alias BACKGROUND = "48"
alias AnyColor = Variant[NoColor, ANSIColor, ANSI256Color, RGBColor]


trait Color(EqualityComparable, CollectionElement):
    fn sequence(self, is_background: Bool) -> String:
        """Sequence returns the ANSI Sequence for the color."""
        ...


@value
struct NoColor(Color, Stringable):
    fn __eq__(self, other: NoColor) -> Bool:
        return True

    fn __ne__(self, other: NoColor) -> Bool:
        return False

    fn sequence(self, is_background: Bool) -> String:
        return ""

    fn __str__(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ""


@value
struct ANSIColor(Color, Stringable):
    """ANSIColor is a color (0-15) as defined by the ANSI Standard."""

    var value: UInt8

    @always_inline
    fn __eq__(self, other: ANSIColor) -> Bool:
        return self.value == other.value

    @always_inline
    fn __ne__(self, other: ANSIColor) -> Bool:
        return self.value != other.value

    @always_inline
    fn sequence(self, is_background: Bool) -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var modifier: Int = 0
        if is_background:
            modifier += 10

        if self.value < 8:
            return int_to_str(modifier + int(self.value) + 30)
        return int_to_str(modifier + int(self.value) - 8 + 90)

    @always_inline
    fn __str__(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ANSI_HEX_CODES[int(self.value)]

    @always_inline
    fn convert_to_rgb(self) -> hue.Color:
        """Converts an ANSI color to hue.Color by looking up the hex value and converting it."""
        var hex: String = ANSI_HEX_CODES[int(self.value)]

        return hex_to_rgb(hex)


@value
struct ANSI256Color(Color, Stringable):
    """ANSI256Color is a color (16-255) as defined by the ANSI Standard."""

    var value: UInt8

    @always_inline
    fn __eq__(self, other: ANSI256Color) -> Bool:
        return self.value == other.value

    @always_inline
    fn __ne__(self, other: ANSI256Color) -> Bool:
        return self.value != other.value

    @always_inline
    fn sequence(self, is_background: Bool) -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var prefix: String = FOREGROUND
        if is_background:
            prefix = BACKGROUND

        return prefix + ";5;" + int_to_str(int(self.value))

    @always_inline
    fn __str__(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ANSI_HEX_CODES[int(self.value)]

    @always_inline
    fn convert_to_rgb(self) -> hue.Color:
        """Converts an ANSI color to hue.Color by looking up the hex value and converting it."""
        var hex: String = ANSI_HEX_CODES[int(self.value)]

        return hex_to_rgb(hex)


fn convert_base16_to_base10(value: String) -> Int:
    """Converts a base 16 number to base 10.
    https://www.catalyst2.com/knowledgebase/dictionary/hexadecimal-base-16-numbers/#:~:text=To%20convert%20the%20hex%20number,16%20%2B%200%20%3D%2016).

    Args:
        value: Hexadecimal number.

    Returns:
        Base 10 number.
    """
    alias mapping = List[String]("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f")

    # We assume mapping.find always returns a value considering the value passed in is a valid hex value
    # and the mapping has all the values.
    var length = len(value)
    var total: Int = 0
    for i in range(length - 1, -1, -1):
        var exponent = length - 1 - i

        @parameter
        for j in range(16):
            if mapping[j] == value[i]:
                total += j * (16**exponent)
                break

    return total


fn hex_to_rgb(value: String) -> hue.Color:
    """Converts a hex color to hue.Color.

    Args:
        value: Hex color value.

    Returns:
        Color.
    """
    var hex = value[1:]
    var results = List[Int]()

    @parameter
    for i in range(3):
        results.append(convert_base16_to_base10(hex[(i * 2) : (i * 2) + 2]))

    return hue.Color(results[0], results[1], results[2])


@value
struct RGBColor(Color):
    """RGBColor is a hex-encoded color, e.g. '#abcdef'."""

    var value: String

    @always_inline
    fn __init__(inout self, value: String):
        self.value = value.lower()

    @always_inline
    fn __eq__(self, other: RGBColor) -> Bool:
        return self.value == other.value

    @always_inline
    fn __ne__(self, other: RGBColor) -> Bool:
        return self.value != other.value

    @always_inline
    fn sequence(self, is_background: Bool) -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var rgb = hex_to_rgb(self.value)

        var prefix = FOREGROUND
        if is_background:
            prefix = BACKGROUND

        return (
            prefix
            + String(";2;")
            + int_to_str(int(rgb.R))
            + ";"
            + int_to_str(int(rgb.G))
            + ";"
            + int_to_str(int(rgb.B))
        )

    @always_inline
    fn convert_to_rgb(self) -> hue.Color:
        """Converts the Hex code value to hue.Color."""
        return hex_to_rgb(self.value)


fn ansi256_to_ansi(value: UInt8) -> ANSIColor:
    """Converts an ANSI256 color to an ANSI color.

    Args:
        value: ANSI256 color value.
    """
    var r: Int = 0
    var md = hue.math.max_float64

    var h = hex_to_rgb(ANSI_HEX_CODES[int(value)])

    var i: Int = 0
    while i <= 15:
        var hb = hex_to_rgb(ANSI_HEX_CODES[i])
        var d = h.distance_HSLuv(hb)

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


fn hex_to_ansi256(color: hue.Color) -> ANSI256Color:
    """Converts a hex code to a ANSI256 color.

    Args:
        color: Hex code color from hue.Color.
    """
    # Calculate the nearest 0-based color index at 16..231
    # Originally had * 255 in each of these
    var r: Float64 = v2ci(color.R)  # 0..5 each
    var g: Float64 = v2ci(color.G)
    var b: Float64 = v2ci(color.B)
    var ci: Int = int((36 * r) + (6 * g) + b)  # 0..215

    # Calculate the represented colors back from the index
    alias i2cv = InlineArray[Int, 6](0, 0x5F, 0x87, 0xAF, 0xD7, 0xFF)
    var cr = i2cv[int(r)]  # r/g/b, 0..255 each
    var cg = i2cv[int(g)]
    var cb = i2cv[int(b)]

    # Calculate the nearest 0-based gray index at 232..255
    var gray_index: Int
    var average = (r + g + b) / 3
    if average > 238:
        gray_index = 23
    else:
        gray_index = int((average - 3) / 10)  # 0..23
    var gv = 8 + 10 * gray_index  # same value for r/g/b, 0..255

    # Return the one which is nearer to the original input rgb value
    # Originall had / 255.0 for r, g, and b in each of these
    var c2 = hue.Color(cr, cg, cb)
    var g2 = hue.Color(gv, gv, gv)
    var color_dist = color.distance_HSLuv(c2)
    var gray_dist = color.distance_HSLuv(g2)

    if color_dist <= gray_dist:
        return ANSI256Color(16 + ci)
    return ANSI256Color(232 + gray_index)
