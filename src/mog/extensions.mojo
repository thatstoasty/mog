from weave.ansi import printable_rune_width
from utils import StringSlice


fn get_lines(text: String) -> Tuple[List[String], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = split_lines(text)
    var widest_line: Int = 0
    for i in range(len(lines)):
        if printable_rune_width(lines[i]) > widest_line:
            widest_line = printable_rune_width(lines[i])

    return lines, widest_line


fn split_lines(text: String) -> List[String]:
    return text.as_string_slice().splitlines()
