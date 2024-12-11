from collections import Optional
from weave.ansi import printable_rune_width
import mist
import .position
from .extensions import get_lines


fn align_text_horizontal(
    text: String, pos: position.Position, width: Int, style: Optional[mist.Style] = None
) -> String:
    """Aligns the text on the horizontal axis. If the string is multi-lined, we also make all lines
    the same width by padding them with spaces. If a termenv style is passed,
    use that to style the spaces added.

    Args:
        text: The text to align.
        pos: The position to align the text to.
        width: The width to align the text to.
        style: The style to use for the spaces added. Defaults to None.

    Returns:
        The aligned text.
    """
    lines, widest_line = get_lines(text)
    var aligned_text = String(capacity=int(len(text) * 1.25))
    for i in range(len(lines)):
        var line = lines[i]
        var line_width = printable_rune_width(line)
        var short_amount = widest_line - line_width  # difference from the widest line
        short_amount += max(0, width - (short_amount + line_width))  # difference from the total width, if set
        if short_amount > 0:
            if pos == position.right:
                var spaces = WHITESPACE * short_amount
                if style:
                    spaces = style.value().render(spaces)
                
                var new = String(capacity=len(line) + len(spaces) + 1)
                new.write(spaces, line)
                line = new
            elif pos == position.center:
                # Note: remainder goes on the right.
                var left = short_amount / 2
                var right = left + short_amount % 2
                var left_spaces = WHITESPACE * int(left)
                var right_spaces = WHITESPACE * int(right)
                if style:
                    left_spaces = style.value().render(left_spaces)
                    right_spaces = style.value().render(right_spaces)

                var new = String(capacity=len(line) + len(left_spaces) + len(right_spaces) + 1)
                new.write(left_spaces, line, right_spaces)
                line = new
            elif pos == position.left:
                var spaces = WHITESPACE * int(short_amount)
                if style:
                    spaces = style.value().render(spaces)
                line.write(spaces)

        aligned_text.write(line)
        if i < len(lines) - 1:
            aligned_text.write(NEWLINE)

    return aligned_text


fn align_text_vertical(text: String, pos: position.Position, height: Int) -> String:
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
        return text

    if pos == position.top:
        var new = String(capacity=len(text) + (height - text_height) + 1)
        new.write(text, NEWLINE * (height - text_height))
        return new

    elif pos == position.center:
        var top_padding = (height - text_height) / 2
        var bottom_padding = (height - text_height) / 2
        if text_height + top_padding + bottom_padding > height:
            top_padding -= 1
        elif text_height + top_padding + bottom_padding < height:
            bottom_padding += 1

        var new = String(capacity=len(text) + len(NEWLINE * int(top_padding)) + len(NEWLINE * int(bottom_padding)) + 1)
        new.write(NEWLINE * int(top_padding), text, NEWLINE * int(bottom_padding))
        return new

    elif pos == position.bottom:
        var new = String(capacity=len(text) + (height - text_height) + 1)
        new.write(NEWLINE * (height - text_height), text)
        return new

    return text
