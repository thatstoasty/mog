from external.weave.ansi.ansi import printable_rune_width
from external.mist import TerminalStyle
from external.gojo.strings import StringBuilder
import .position
from .extensions import count, repeat, split


# Perform text alignment. If the string is multi-lined, we also make all lines
# the same width by padding them with spaces. If a termenv style is passed,
# use that to style the spaces added.
fn align_text_horizontal(text: String, pos: position.Position, width: Int, style: TerminalStyle) -> String:
    # TODO: Replace when get_lines works.
    var lines = split(text, "\n")

    var widest_line: Int = 0
    for i in range(len(lines)):
        if printable_rune_width(lines[i]) > widest_line:
            widest_line = printable_rune_width(lines[i])

    var aligned_text = StringBuilder()
    for i in range(len(lines)):
        var line = lines[i]
        var line_width = printable_rune_width(line)

        var short_amount = widest_line - line_width  # difference from the widest line
        short_amount += max(0, width - (short_amount + line_width))  # difference from the total width, if set
        if short_amount > 0:
            if pos == position.right:
                var spaces = repeat(" ", short_amount)

                # Removed the nil check before rendering the spaces in whatever style for now.
                spaces = style.render(spaces)
                line = spaces + line
            elif pos == position.center:
                # Note: remainder goes on the right.
                var left = short_amount / 2
                var right = left + short_amount % 2

                var left_spaces = repeat(" ", int(left))
                var right_spaces = repeat(" ", int(right))

                left_spaces = style.render(left_spaces)
                right_spaces = style.render(right_spaces)
                line = left_spaces + line + right_spaces
            elif pos == position.left:
                var spaces = repeat(" ", int(short_amount))
                spaces = style.render(spaces)
                line += spaces

        _ = aligned_text.write_string(line)
        if i < len(lines) - 1:
            _ = aligned_text.write_string("\n")

    return str(aligned_text)


fn align_text_vertical(text: String, pos: position.Position, height: Int) -> String:
    var text_height = count(text, "\n") + 1
    if height < text_height:
        return text

    if pos == position.top:
        return text + repeat("\n", height - text_height)

    if pos == position.center:
        var top_padding = (height - text_height) / 2
        var bottom_padding = (height - text_height) / 2
        if text_height + top_padding + bottom_padding > height:
            top_padding -= 1
        elif text_height + top_padding + bottom_padding < height:
            bottom_padding += 1

        return repeat("\n", int(top_padding)) + text + repeat("\n", int(bottom_padding))

    if pos == position.bottom:
        return repeat("\n", height - text_height) + text

    return text
