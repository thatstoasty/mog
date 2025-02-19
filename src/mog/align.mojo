from collections import Optional
from weave.ansi import printable_rune_width
import mist
import mog.position
from mog.extensions import get_lines, get_lines_view


fn align_text_horizontal(
    text: String, pos: position.Position, width: Int, style: mist.Style
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
    lines, widest_line = get_lines_view(text)
    
    # If the text is empty, just return (styled) padding up to the width passed.
    if len(lines) == 0:
        return style.render(WHITESPACE * width)

    var aligned = String(capacity=Int(len(text) * 1.25))
    for i in range(len(lines)):
        if i != 0:
            aligned.write(NEWLINE)

        var line = String(lines[i])
        var line_width = printable_rune_width(line)
        var short_amount = widest_line - line_width  # difference from the widest line
        short_amount += max(0, width - (short_amount + line_width))  # difference from the total width, if set
        if short_amount > 0:
            if pos == Position.RIGHT:
                line = String(style.render(WHITESPACE * short_amount), line)
            elif pos == Position.CENTER:
                # Note: remainder goes on the right.
                var left = Int(short_amount / 2)
                var right = Int(left + short_amount % 2)
                line = String(style.render(WHITESPACE * left), line, style.render(WHITESPACE * right))
            elif pos == Position.LEFT:
                line.write(style.render(WHITESPACE * short_amount))

        aligned.write(line)
        
    return aligned^


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

    var remaining_height = height - text_height
    if pos == Position.TOP:
        return String(text, NEWLINE * remaining_height)

    elif pos == Position.CENTER:
        var top_padding = (remaining_height) / 2
        var bottom_padding = (remaining_height) / 2
        if text_height + top_padding + bottom_padding > height:
            top_padding -= 1
        elif text_height + top_padding + bottom_padding < height:
            bottom_padding += 1

        return String(NEWLINE * Int(top_padding), text, NEWLINE * Int(bottom_padding))

    elif pos == Position.BOTTOM:
        return String(NEWLINE * remaining_height, text)

    return text
