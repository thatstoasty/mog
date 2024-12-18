from utils import StringSlice
from weave.ansi import printable_rune_width
import mist


# TODO: I'll see if I can get `count` on `StringSlice` upstream in Mojo and add `AsStringSlice`.
trait AsStringSlice:
    fn as_string_slice(ref self) -> StringSlice[__origin_of(self)]:
        ...


fn count(text: StringSlice, substr: String) -> Int:
    """Return the number of non-overlapping occurrences of substring
    `substr` in the string.

    If sub is empty, returns the number of empty strings between characters
    which is the length of the string plus one.

    Args:
        text: The string to search.
        substr: The substring to count.

    Returns:
        The number of occurrences of `substr`.
    """
    if not substr:
        return len(text) + 1

    var res = 0
    var offset = 0

    while True:
        var pos = text.find(substr, offset)
        if pos == -1:
            break
        res += 1

        offset = pos + substr.byte_length()

    return res


fn get_lines(text: String) -> Tuple[List[String], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = text.splitlines()
    var widest_line = 0
    for line in lines:
        if printable_rune_width(line[]) > widest_line:
            widest_line = printable_rune_width(line[])
    return lines, widest_line


fn get_lines_view(text: String) -> Tuple[List[StringSlice[__origin_of(text)]], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = text.as_string_slice().splitlines()
    var widest_line = 0
    for line in lines:
        if printable_rune_width(line[]) > widest_line:
            widest_line = printable_rune_width(line[])
    return lines, widest_line


fn get_widest_line[immutable: ImmutableOrigin](text: StringSlice[immutable]) -> Int:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        The width of the widest line.
    """
    if text == "":
        return 0

    var lines = text.splitlines()
    var widest = 0
    for i in range(len(lines)):
        if printable_rune_width(lines[i]) > widest:
            widest = printable_rune_width(lines[i])

    return widest


fn pad(text: String, n: Int, style: mist.Style) -> String:
    """Pad text with spaces.

    Args:
        text: The text to pad.
        n: The number of spaces to pad with.
        style: The style to use for the spaces.

    Returns:
        The padded text.
    """
    if n == 0:
        return text

    var spaces = style.render(WHITESPACE * abs(n))
    var result = String(capacity=int(len(text) * 1.5))
    var lines = text.as_string_slice().splitlines()
    for i in range(len(lines)):
        if n > 0:
            result.write(lines[i], spaces)
        else:
            result.write(spaces, lines[i])

        if i != len(lines) - 1:
            result.write(NEWLINE)

    return result


fn pad_left(text: String, n: Int, style: mist.Style) -> String:
    """Pad text with spaces to the left.

    Args:
        text: The text to pad.
        n: The number of spaces to pad with.
        style: The style to use for the spaces.

    Returns:
        The padded text.
    """
    return pad(text, -n, style)


fn pad_right(text: String, n: Int, style: mist.Style) -> String:
    """Pad text with spaces to the right.

    Args:
        text: The text to pad.
        n: The number of spaces to pad with.
        style: The style to use for the spaces.

    Returns:
        The padded text.
    """
    return pad(text, n, style)
