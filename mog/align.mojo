import mog.position
from mog.external.weave.ansi.ansi import len_without_ansi
from mog.position import Position
from mog.external.mist import TerminalStyle
from mog.math import max, min
from mog.extensions import count
from mog.external.stdlib.builtins.string import __string__mul__


# Perform text alignment. If the string is multi-lined, we also make all lines
# the same width by padding them with spaces. If a termenv style is passed,
# use that to style the spaces added.
fn align_text_horizontal(
    text: String, pos: Position, width: Int, style: TerminalStyle
) raises -> String:
    # TODO: Replace when get_lines works.
    let lines = text.split("\n")
    var widest_line: Int = 0
    for i in range(lines.size):
        # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
        if len_without_ansi(lines[i]) > widest_line:
            widest_line = len_without_ansi(lines[i])

    # TODO: Use string builder or buffered writer for this later.
    var aligned_text: String = ""
    for i in range(lines.size):
        var line = lines[i]
        let line_width = len_without_ansi(line)  # TODO: Should be rune length

        var short_amount = widest_line - line_width  # difference from the widest line
        short_amount += max(
            0, width - (short_amount + line_width)
        )  # difference from the total width, if set
        if short_amount > 0:
            if pos == position.right:
                var spaces = __string__mul__(" ", short_amount)

                # Removed the nil check before rendering the spaces in whatever style for now.
                spaces = style.render(spaces)
                line = spaces + line
            elif pos == position.center:
                # Note: remainder goes on the right.
                let left = short_amount / 2
                let right = left + short_amount % 2

                var left_spaces = __string__mul__(" ", int(left))
                var right_spaces = __string__mul__(" ", int(right))

                left_spaces = style.render(left_spaces)
                right_spaces = style.render(right_spaces)
                line = left_spaces + line + right_spaces
            elif pos == position.left:
                var spaces = __string__mul__(" ", int(short_amount))
                spaces = style.render(spaces)
                line += spaces

        aligned_text += line
        if i < len(lines) - 1:
            aligned_text += "\n"

    return aligned_text


fn align_text_vertical(text: String, pos: Position, height: Int) raises -> String:
    let text_height = count(text, "\n") + 1
    if height < text_height:
        return text

    if pos == position.top:
        return text + __string__mul__("\n", height - text_height)

    if pos == position.center:
        var top_padding = (height - text_height) / 2
        var bottom_padding = (height - text_height) / 2
        if text_height + top_padding + bottom_padding > height:
            top_padding -= 1
        elif text_height + top_padding + bottom_padding < height:
            bottom_padding += 1

        return (
            __string__mul__("\n", int(top_padding))
            + text
            + __string__mul__("\n", int(bottom_padding))
        )

    if pos == position.bottom:
        return __string__mul__("\n", height - text_height) + text

    return text
