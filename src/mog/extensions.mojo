from utils import StringSlice
from weave.ansi import printable_rune_width
import mist


fn get_lines(text: String) -> Tuple[List[String], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    lines, widest_line = get_lines_view(text)
    return line_view_to_lines(lines), widest_line


fn get_lines_view(text: String) -> Tuple[List[StringSlice[__origin_of(text)]], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    
    #### Notes:
    Reminder that splitlines strips any trailing newlines. If you need to preserve them, you'll need to add them back.
    """
    var lines = text.as_string_slice().splitlines()
    var widest_line = 0
    for line in lines:
        if printable_rune_width(line[]) > widest_line:
            widest_line = printable_rune_width(line[])
    
    return lines^, widest_line


fn line_view_to_lines[origin: Origin](lines: List[StringSlice[origin]]) -> List[String]:
    """Convert a list of string slices to a list of strings.

    Args:
        lines: The list of string slices.

    Returns:
        The list of strings.
    """
    var result = List[String](capacity=len(lines))
    for line in lines:
        result.append(String(line[]))
    return result^


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
