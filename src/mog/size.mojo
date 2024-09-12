import weave.ansi
from .extensions import split


fn get_width(text: String) -> Int:
    """Returns the cell width of characters in the string. ANSI sequences are
    ignored and characters wider than one cell (such as Chinese characters and
    emojis) are appropriately measured.

    You should use this instead of len(string) as it will give you accurate results.

    Args:
        text: The string to measure.

    Returns:
        The width of the string in cells.
    """
    var strings = split(text, NEWLINE)
    var width: Int = 0
    for i in range(len(strings)):
        var l = strings[i]
        var w = ansi.printable_rune_width(l)
        if w > width:
            width = w

    return width


fn get_height(text: String) -> Int:
    """Returns height of a string in cells. This is done simply by
    counting \\n characters. If your strings use \\r\\n for newlines you should
    convert them to \\n first, or simply write a separate fntion for measuring
    height.

    Args:
        text: The string to measure.

    Returns:
        The height of the string in cells.
    """
    var height = 1
    for i in range(len(text)):
        if text[i] == NEWLINE:
            height += 1

    return height


fn get_size(text: String) raises -> (Int, Int):
    """Returns the width and height of the string in cells. ANSI sequences are
    ignored and characters wider than one cell (such as Chinese characters and
    emojis) are appropriately measured.

    Args:
        text: The string to measure.

    Returns:
        A tuple containing the width and height of the string in cells.
    """
    return get_width(text), get_height(text)
