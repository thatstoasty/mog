import mist
import mog.position
from mist.transform.ansi import printable_rune_width
from mog._extensions import get_lines


fn align_text_horizontal(
    text: StringSlice, pos: position.Position, width: UInt16, style: Optional[mist.Style] = None
) -> String:
    """Aligns the text on the horizontal axis. If the string is multi-lined, we also make all lines
    the same width by padding them with spaces. The mist style is used to style the spaces added.

    Args:
        text: The text to align.
        pos: The position to align the text to.
        width: The width to align the text to.
        style: The style to use for the spaces added. Defaults to None.

    Returns:
        The aligned text.
    """
    lines, widest_line = get_lines(text)

    # If the text is empty, just return (styled) padding up to the width passed.
    if len(lines) == 0:
        var spaces = WHITESPACE * Int(width)
        if style:
            return style.value().render(spaces)
        return spaces^

    var aligned = String(capacity=Int(len(text) * 1.25))
    for i in range(len(lines)):
        var line = String(lines[i])
        var line_width = printable_rune_width(line)
        var short_amount = widest_line - line_width  # difference from the widest line
        short_amount += max(0, Int(width) - (short_amount + line_width))  # difference from the total width, if set
        if short_amount > 0:
            if pos == Position.RIGHT:
                var spaces = WHITESPACE * short_amount
                if style:
                    line = String(style.value().render(spaces), line)
                else:
                    line = String(spaces, line)
            elif pos == Position.CENTER:
                # Note: remainder goes on the right.
                var left = Int(short_amount / 2)
                var right = Int(left + short_amount % 2)
                var left_spaces = WHITESPACE * left
                var right_spaces = WHITESPACE * right
                if style:
                    line = String(style.value().render(left_spaces), line, style.value().render(right_spaces))
                else:
                    line = String(left_spaces, line, right_spaces)
            elif pos == Position.LEFT:
                var spaces = WHITESPACE * short_amount
                if style:
                    line = String(line, style.value().render(spaces))
                else:
                    line = String(line, spaces)

        aligned.write(line)
        if i < len(lines) - 1:
            aligned.write(NEWLINE)

    return aligned^


fn align_text_vertical(text: StringSlice, pos: position.Position, height: UInt16) -> String:
    """Aligns the text on the vertical axis. If the string is shorter than the height, it's padded
    with newlines. If the string is taller than the height, return the original
    string.

    Args:
        text: The text to align.
        pos: The position to align the text to.
        height: The height to align the text to.

    Returns:
        The aligned text.
    """
    var text_height = text.count(NEWLINE) + 1
    if height < text_height:
        return String(text)

    var remaining_height = Int(height - text_height)
    if pos == Position.TOP:
        return String(text, NEWLINE * remaining_height)

    elif pos == Position.CENTER:
        var top_padding = Int(remaining_height / 2)
        var bottom_padding = Int(remaining_height / 2)
        if text_height + top_padding + bottom_padding > Int(height):
            top_padding -= 1
        elif text_height + top_padding + bottom_padding < Int(height):
            bottom_padding += 1

        return String(NEWLINE * top_padding, text, NEWLINE * bottom_padding)

    elif pos == Position.BOTTOM:
        return String(NEWLINE * remaining_height, text)

    return String(text)
