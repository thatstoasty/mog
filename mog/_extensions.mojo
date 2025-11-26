from sys import stderr

import mist
from mist.transform.ansi import printable_rune_width


fn get_lines[origin: ImmutOrigin](text: StringSlice[origin]) -> Tuple[List[StringSlice[origin]], UInt]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = text.split(NEWLINE)
    var widest_line: UInt = 0
    for line in lines:
        var width = printable_rune_width(line)
        if width > widest_line:
            widest_line = width

    return lines^, widest_line


fn get_widest_line[origin: ImmutOrigin](text: StringSlice[origin]) -> UInt:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        The width of the widest line.
    """
    if len(text) == 0:
        return 0

    var widest: UInt = 0
    for line in text.splitlines():
        var width = printable_rune_width(line)
        if width > widest:
            widest = width

    return widest


fn get_widest_line[origin: ImmutOrigin](lines: List[StringSlice[origin]]) -> UInt:
    """Get the width of the widest line.

    Args:
        lines: The lines to get the width from.

    Returns:
        The width of the widest line.
    """
    if len(lines) == 0:
        return 0

    var widest: UInt = 0
    for line in lines:
        var width = printable_rune_width(line)
        if width > widest:
            widest = width

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
    var result = String(capacity=Int(len(text) * 1.5))
    var lines = text.as_string_slice().get_immutable().splitlines()
    for i in range(len(lines)):
        if n > 0:
            result.write(lines[i], spaces)
        else:
            result.write(spaces, lines[i])

        if i != len(lines) - 1:
            result.write(NEWLINE)

    return result^


@always_inline
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


@always_inline
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
