from weave.ansi import printable_rune_width


fn get_lines(text: String) -> Tuple[List[String], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = text.splitlines()
    var widest_line = 0
    for line in lines:
        if printable_rune_width(line[]) > widest_line:
            widest_line = printable_rune_width(line[])

    return lines, widest_line
