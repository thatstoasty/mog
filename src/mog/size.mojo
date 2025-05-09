import mist.transform.ansi
from mog._properties import Dimensions


fn get_width(text: StringSlice) -> Int:
    """Returns the cell width of characters in the string. ANSI sequences are
    ignored and characters wider than one cell (such as Chinese characters and
    emojis) are appropriately measured.

    You should use this instead of len(string) as it will give you accurate results.

    Args:
        text: The string to measure.

    Returns:
        The width of the string in cells.
    """
    var width = 0
    for line in text.splitlines():
        var w = ansi.printable_rune_width(line[])
        if w > width:
            width = w

    return width


fn get_height(text: StringSlice) -> Int:
    """Returns height of a string in cells. This is done simply by
    counting \\n characters. If your strings use \\r\\n for newlines you should
    convert them to \\n first, or simply write a separate function for measuring
    height.

    Args:
        text: The string to measure.

    Returns:
        The height of the string in cells.
    """
    return text.count(NEWLINE) + 1


fn get_dimensions(text: StringSlice) -> Dimensions:
    """Returns the width and height of the string in cells. ANSI sequences are
    ignored and characters wider than one cell (such as Chinese characters and
    emojis) are appropriately measured.

    Args:
        text: The string to measure.

    Returns:
        The width and height of the string in cells.
    """
    return Dimensions(width=get_width(text), height=get_height(text))
