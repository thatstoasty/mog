"""A module for aligning text in the terminal."""

import mist
from mist.transform.ansi import printable_rune_width
from mog._extensions import get_widest_line, NEWLINE, WHITESPACE
from mog.position import Position


struct Alignment(Equatable, Writable, TrivialRegisterPassable):
    """Alignment represents the horizontal and vertical alignment of text.

    Defaults to top-left alignment.
    """

    var horizontal: Position
    """The horizontal alignment of the text."""
    var vertical: Position
    """The vertical alignment of the text."""

    def __init__(out self, *, horizontal: Position = Position.LEFT, vertical: Position = Position.TOP):
        """Initializes a new Alignment.

        Defaults to top-left alignment.

        Args:
            horizontal: The horizontal alignment.
            vertical: The vertical alignment.
        """
        self.horizontal = horizontal
        self.vertical = vertical

    def __init__(out self, alignment: Position):
        """Initializes a new Alignment instance with the same alignment for both horizontal and vertical axes.

        Args:
            alignment: The alignment to use.
        """
        self.horizontal = alignment
        self.vertical = alignment


def align_text_horizontal[origin: ImmOrigin, //](
    text: StringSpan[origin], pos: Position, width: UInt16, style: Optional[mist.Style] = None
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
    var lines = text.split(NEWLINE)
    var widest_line = get_widest_line(lines)

    # If the text is empty, just return (styled) padding up to the width passed.
    if len(lines) == 0:
        var spaces = WHITESPACE * Int(width)
        if style:
            return style.value().render(spaces)
        return spaces^

    var aligned = String(capacity_bytes=Int(Float64(text.byte_length()) * 1.25))
    for i in range(len(lines)):
        var line = String(lines[i])
        var line_width = Int(printable_rune_width(line))
        var short_amount = Int(widest_line) - line_width  # difference from the widest line
        short_amount += max(0, (Int(width) - (short_amount + line_width)))  # difference from the total width, if set
        if short_amount > 0:
            # Split the padding between the two sides in proportion to `pos`, the way
            # `join` and `WhitespaceRenderer.place_horizontal` do. 0 puts all of it on
            # the right (left aligned), 1 all on the left, 0.5 half on each side.
            # Truncating rather than rounding leaves an odd cell on the right.
            # Branching on the named constants instead would drop the padding entirely
            # for any other position, leaving the line short of the requested width.
            var left = Int(Float64(short_amount) * pos.value)
            var right = short_amount - left
            var padded = String(capacity_bytes=line.byte_length() + short_amount)
            # A side of zero writes nothing: handing an empty string to the styler
            # would wrap it in escape sequences that paint nothing.
            if left > 0:
                var spaces = WHITESPACE * left
                padded.write(style.value().render(spaces) if style else spaces)
            padded.write(line)
            if right > 0:
                var spaces = WHITESPACE * right
                padded.write(style.value().render(spaces) if style else spaces)
            line = padded^

        aligned.write(line)
        if i < len(lines) - 1:
            aligned.write(NEWLINE)

    return aligned^


def align_text_vertical[origin: ImmOrigin, //](text: StringSpan[origin], pos: Position, height: UInt16) -> String:
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
    if Int(height) < text_height:
        return String(text)

    var remaining_height = Int(height) - text_height

    # Split the blank lines above and below in proportion to `pos`: 0 is top aligned,
    # 1 is bottom aligned, 0.5 centers. Truncating rather than rounding leaves an odd
    # line at the bottom. Branching on the named constants instead would return the
    # text unpadded for any other position, ignoring the requested height.
    var top_padding = Int(Float64(remaining_height) * pos.value)
    var bottom_padding = remaining_height - top_padding
    return String(NEWLINE * top_padding, text, NEWLINE * bottom_padding)
