import math
from collections.string import StringSlice
from mist.transform.ansi import printable_rune_width
from mog._extensions import get_lines
from mog.position import Position


fn join_horizontal(pos: Position, *strs: String) -> String:
    """Utility function for horizontally joining two
    potentially multi-lined strings along a vertical axis. The first argument is
    the position, with 0 being all the way at the top and 1 being all the way
    at the bottom.

    If you just want to align to the left, right or center you may as well just
    use the helper constants Top, Center, and Bottom.

    #### Examples:
    ```mojo
    import mog

    fn main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_horizontal(0.2, block_a, block_b)

        # Join on the top edge
        text = mog.join_horizontal(mog.top, block_a, block_b)
    ```

    Args:
        pos: The position to join the strings.
        strs: The strings to join.

    Returns:
        The joined string.
    """
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return String(strs[0])

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_widths = List[Int](capacity=len(strs))
    var max_height = 0

    # Break text blocks into lines and get max widths for each text block
    for s in strs:
        lines, widest = get_lines(s[])
        blocks.append(lines)
        max_widths.append(widest)
        if len(lines) > max_height:
            max_height = len(lines)

    # Add extra lines to make each side the same height
    for i in range(len(blocks)):
        if len(blocks[i]) >= max_height:
            continue
        var extra_lines = List[String](capacity=max_height - len(blocks[i]))
        extra_lines.resize(max_height - len(blocks[i]), "")

        if pos == Position.TOP:
            blocks[i].extend(extra_lines)
        elif pos == Position.BOTTOM:
            extra_lines.extend(blocks[i])
            blocks[i] = extra_lines
        else:
            var end = len(extra_lines)
            var top_point = end - Int(end * pos.value)
            var bottom_point = end - top_point

            var top_lines = extra_lines[top_point : end]
            var bottom_lines = extra_lines[bottom_point : end]
            top_lines.extend(blocks[i])
            blocks[i] = top_lines
            blocks[i].extend(bottom_lines)

    # Merge lines
    var result = String()
    # remember, all blocks have the same number of members now
    for i in range(len(blocks[0])):
        for j in range(len(blocks)):
            result.write(blocks[j][i])

            # Also make lines the same length by padding with whitespace
            result.write(WHITESPACE * (max_widths[j] - printable_rune_width(blocks[j][i])))

        if i < len(blocks[0]) - 1:
            result.write(NEWLINE)

    return result^


fn join_horizontal(pos: Position, strs: List[String]) -> String:
    """Utility function for horizontally joining two
    potentially multi-lined strings along a vertical axis. The first argument is
    the position, with 0 being all the way at the top and 1 being all the way
    at the bottom.

    If you just want to align to the left, right or center you may as well just
    use the helper constants Top, Center, and Bottom.

    #### Examples:
    ```mojo
    import mog

    fn main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_horizontal(0.2, block_a, block_b)

        # Join on the top edge
        text = mog.join_horizontal(mog.top, block_a, block_b)
    ```

    Args:
        pos: The position to join the strings.
        strs: The strings to join.

    Returns:
        The joined string.
    """
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_widths = List[Int](capacity=len(strs))
    var max_height = 0

    # Break text blocks into lines and get max widths for each text block
    for s in strs:
        lines, widest = get_lines(s[])
        blocks.append(lines)
        max_widths.append(widest)
        if len(lines) > max_height:
            max_height = len(lines)

    # Add extra lines to make each side the same height
    for i in range(len(blocks)):
        if len(blocks[i]) >= max_height:
            continue
        var extra_lines = List[String](capacity=max_height - len(blocks[i]))
        extra_lines.resize(max_height - len(blocks[i]), "")

        if pos == Position.TOP:
            blocks[i].extend(extra_lines)
        elif pos == Position.BOTTOM:
            extra_lines.extend(blocks[i])
            blocks[i] = extra_lines
        else:
            var end = len(extra_lines)
            var top_point = end - Int(end * pos.value)
            var bottom_point = end - top_point

            var top_lines = extra_lines[top_point : end]
            var bottom_lines = extra_lines[bottom_point : end]
            top_lines.extend(blocks[i])
            blocks[i] = top_lines
            blocks[i].extend(bottom_lines)
    
    # Merge lines
    var result = String()
    # remember, all blocks have the same number of members now
    for i in range(len(blocks[0])):
        for j in range(len(blocks)):
            result.write(blocks[j][i])

            # Also make lines the same length by padding with whitespace
            result.write(WHITESPACE * (max_widths[j] - printable_rune_width(blocks[j][i])))

        if i < len(blocks[0]) - 1:
            result.write(NEWLINE)

    return result^


fn join_vertical(pos: Position, *strs: String) -> String:
    """Utility function for vertically joining two potentially
    multi-lined strings along a horizontal axis. The first argument is the
    position, with 0 being all the way to the left and 1 being all the way to
    the right.

    If you just want to align to the left, right or center you may as well just
    use the helper constants Left, Center, and Right.

    #### Examples:
    ```mojo
    import mog

    fn main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_vertical(0.2, block_a, block_b)

        # Join on the right edge
        text = mog.join_vertical(mog.right, block_a, block_b)
    ```

    Args:
        pos: The position to join the strings.
        strs: The strings to join.

    Returns:
        The joined string.
    """
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return String(strs[0])

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_width = 0
    for s in strs:
        lines, widest = get_lines(s[])
        blocks.append(lines)
        if widest > max_width:
            max_width = widest

    var result = String()
    var w = 0
    for i in range(len(blocks)):
        for j in range(len(blocks[i])):
            var line = blocks[i][j]
            w = max_width - printable_rune_width(line)

            if pos == Position.LEFT:
                result.write(line, WHITESPACE * w)
            elif pos == Position.RIGHT:
                result.write(WHITESPACE * w, line)
            else:
                if w < 1:
                    result.write(line)
                else:
                    var split = Int(w * pos.value)
                    var right = w - split
                    var left = w - right

                    result.write(WHITESPACE * left, line, WHITESPACE * right)

            if not (i == len(blocks) - 1 and j == len(blocks[i]) - 1):
                result.write("\n")

    return result^


fn join_vertical(pos: Position, strs: List[String]) -> String:
    """Utility function for vertically joining two potentially
    multi-lined strings along a horizontal axis. The first argument is the
    position, with 0 being all the way to the left and 1 being all the way to
    the right.

    If you just want to align to the left, right or center you may as well just
    use the helper constants Left, Center, and Right.

    #### Examples:
    ```mojo
    import mog

    fn main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_vertical(0.2, block_a, block_b)

        # Join on the right edge
        text = mog.join_vertical(mog.right, block_a, block_b)
    ```

    Args:
        pos: The position to join the strings.
        strs: The strings to join.

    Returns:
        The joined string.
    """
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_width = 0
    for s in strs:
        lines, widest = get_lines(s[])
        blocks.append(lines)
        if widest > max_width:
            max_width = widest

    var result = String()
    for i in range(len(blocks)):
        for j in range(len(blocks[i])):
            # blocks[i][j] is equivalent to a line
            var w = max_width - printable_rune_width(blocks[i][j])

            if pos == Position.LEFT:
                result.write(blocks[i][j], WHITESPACE * w)
            elif pos == Position.RIGHT:
                result.write(WHITESPACE * w, blocks[i][j])
            else:
                if w < 1:
                    result.write(blocks[i][j])
                else:
                    var split = Int(w * pos.value)
                    var right = w - split
                    var left = w - right

                    result.write(WHITESPACE * left, blocks[i][j], WHITESPACE * right)

            if not (i == len(blocks) - 1 and j == len(blocks[i]) - 1):
                result.write("\n")

    return result^
