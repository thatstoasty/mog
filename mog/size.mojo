"""A module for measuring the size of a text block in the terminal."""
from mist.transform import ansi
from mog._extensions import NEWLINE
from mog._properties import Dimensions


def get_width[origin: ImmOrigin, //](text: StringSpan[origin]) -> UInt16:
    """Returns the cell width of characters in the string. ANSI sequences are
    ignored and characters wider than one cell (such as Chinese characters and
    emojis) are appropriately measured.

    You should use this instead of len(string) as it will give you accurate results.

    Args:
        text: The string to measure.

    Returns:
        The width of the string in cells.
    """
    var width: UInt16 = 0
    for line in text.splitlines():
        var w = UInt16(ansi.printable_rune_width(line))
        if w > width:
            width = w

    return width


def get_height[origin: ImmOrigin, //](text: StringSpan[origin]) -> UInt16:
    """Returns height of a string in cells. This is done simply by
    counting \\n characters. If your strings use \\r\\n for newlines you should
    convert them to \\n first, or simply write a separate function for measuring
    height.

    Args:
        text: The string to measure.

    Returns:
        The height of the string in cells.
    """
    return UInt16(text.count(NEWLINE) + 1)


def get_dimensions[origin: ImmOrigin, //](text: StringSpan[origin]) -> Dimensions:
    """Returns the width and height of the string in cells. ANSI sequences are
    ignored and characters wider than one cell (such as Chinese characters and
    emojis) are appropriately measured.

    Args:
        text: The string to measure.

    Returns:
        The width and height of the string in cells.
    """
    return Dimensions(width=get_width(text), height=get_height(text))
