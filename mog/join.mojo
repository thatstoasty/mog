"""A module for joining text blocks in the terminal."""
from std import math

from mist.transform.ansi import printable_rune_width
from mog._extensions import get_widest_line, DEFAULT_BUFFER_SIZE, NEWLINE, WHITESPACE
from mog.position import Position


def _merge_lines(
    blocks: List[List[String]],
    max_widths: List[UInt],
    max_height: Int,
    pos: Position,
) -> String:
    """Merge a block (List of List of lines) of lines into a single String.

    Args:
        blocks: The blocks of lines to merge.
        max_widths: The maximum widths of each block.
        max_height: The maximum height across all blocks.
        pos: The position to align shorter blocks along the vertical axis.

    Returns:
        The merged string.
    """
    var result = String(capacity=DEFAULT_BUFFER_SIZE)
    for i in range(max_height):
        for j in range(len(blocks)):
            var block_height = len(blocks[j])
            var offset = Int(Float64(max_height - block_height) * pos.value)
            var line_idx = i - offset
            if line_idx < 0 or line_idx >= block_height:
                result.write(WHITESPACE * Int(max_widths[j]))
            else:
                var line = blocks[j][line_idx]
                result.write(line)
                result.write(WHITESPACE * Int(max_widths[j] - printable_rune_width(line)))

        if i < max_height - 1:
            result.write(NEWLINE)

    return result^


def join_horizontal(pos: Position, *strs: String) -> String:
    """Utility function for horizontally joining two
    potentially multi-lined strings along a vertical axis. The first argument is
    the position, with 0 being all the way at the top and 1 being all the way
    at the bottom.

    If you just want to align to the left, right or center you may as well just
    use the helper constants Top, Center, and Bottom.

    #### Examples:
    ```mojo
    import mog
    from mog import Position

    def main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_horizontal(0.2, block_a, block_b)

        # Join on the top edge
        text = mog.join_horizontal(Position.TOP, block_a, block_b)
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
    var max_widths = List[UInt](capacity=len(strs))
    var max_height = 0

    # Break text blocks into lines and get max widths for each text block
    for s in strs:
        var line_slices = s.split(NEWLINE)
        var widest = get_widest_line(line_slices)
        var line_length = len(line_slices)
        var lines = List[String](capacity=line_length)
        for ls in line_slices:
            lines.append(String(ls))
        blocks.append(lines^)
        max_widths.append(widest)
        if line_length > max_height:
            max_height = line_length

    return _merge_lines(blocks, max_widths, max_height, pos)


def join_horizontal(pos: Position, strs: List[String]) -> String:
    """Utility function for horizontally joining two
    potentially multi-lined strings along a vertical axis. The first argument is
    the position, with 0 being all the way at the top and 1 being all the way
    at the bottom.

    If you just want to align to the left, right or center you may as well just
    use the helper constants Top, Center, and Bottom.

    #### Examples:
    ```mojo
    import mog
    from mog import Position

    def main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_horizontal(0.2, [block_a, block_b])

        # Join on the top edge
        text = mog.join_horizontal(Position.TOP, [block_a, block_b])
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
    var max_widths = List[UInt](capacity=len(strs))
    var max_height = 0

    # Break text blocks into lines and get max widths for each text block
    for s in strs:
        var line_slices = s.split(NEWLINE)
        var widest = get_widest_line(line_slices)
        var line_length = len(line_slices)
        var lines = List[String](capacity=line_length)
        for ls in line_slices:
            lines.append(String(ls))
        blocks.append(lines^)
        max_widths.append(widest)
        if line_length > max_height:
            max_height = line_length

    return _merge_lines(blocks, max_widths, max_height, pos)


def _merge_blocks_vertically(blocks: List[List[String]], max_width: UInt, pos: Position) -> String:
    """Merge a block (List of List of lines) of lines into a single String.

    Args:
        blocks: The blocks of lines to merge.
        max_width: The maximum width of the lines.
        pos: The position to align the text.

    Returns:
        The merged string.
    """
    var result = String(capacity=DEFAULT_BUFFER_SIZE)
    for i in range(len(blocks)):
        for j in range(len(blocks[i])):
            # blocks[i][j] is equivalent to a line
            var w = max_width - printable_rune_width(blocks[i][j])

            if pos == Position.LEFT:
                result.write(blocks[i][j], WHITESPACE * Int(w))
            elif pos == Position.RIGHT:
                result.write(WHITESPACE * Int(w), blocks[i][j])
            else:
                if w < 1:
                    result.write(blocks[i][j])
                else:
                    var split = UInt(Int(Float64(w) * pos.value))
                    var right = w - split
                    var left = w - right

                    result.write(WHITESPACE * Int(left), blocks[i][j], WHITESPACE * Int(right))

            if not (i == len(blocks) - 1 and j == len(blocks[i]) - 1):
                result.write("\n")

    return result^


def join_vertical(pos: Position, *strs: String) -> String:
    """Utility function for vertically joining two potentially
    multi-lined strings along a horizontal axis. The first argument is the
    position, with 0 being all the way to the left and 1 being all the way to
    the right.

    If you just want to align to the left, right or center you may as well just
    use the helper constants `Position.LEFT`, `Position.CENTER`, and `Position.RIGHT`.

    #### Examples:
    ```mojo
    import mog
    from mog import Position

    def main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_vertical(0.2, block_a, block_b)

        # Join on the right edge
        text = mog.join_vertical(Position.RIGHT, block_a, block_b)
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
    var max_width: UInt = 0
    for s in strs:
        var line_slices = s.split(NEWLINE)
        var widest = get_widest_line(line_slices)
        var lines = List[String](capacity=len(line_slices))
        for ls in line_slices:
            lines.append(String(ls))
        blocks.append(lines^)
        if widest > max_width:
            max_width = widest

    return _merge_blocks_vertically(blocks, max_width, pos)


def join_vertical(pos: Position, strs: List[String]) -> String:
    """Utility function for vertically joining two potentially
    multi-lined strings along a horizontal axis. The first argument is the
    position, with 0 being all the way to the left and 1 being all the way to
    the right.

    If you just want to align to the left, right or center you may as well just
    use the helper constants `Position.LEFT`, `Position.CENTER`, and `Position.RIGHT`.

    #### Examples:
    ```mojo
    import mog
    from mog import Position

    def main():
        var block_b = "...\\n...\\n..."
        var block_a = "...\\n...\\n...\\n...\\n..."

        # Join 20% from the top
        var text = mog.join_vertical(0.2, [block_a, block_b])

        # Join on the right edge
        text = mog.join_vertical(Position.RIGHT, [block_a, block_b])
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
    var max_width: UInt = 0
    for s in strs:
        var line_slices = s.split(NEWLINE)
        var widest = get_widest_line(line_slices)
        var lines = List[String](capacity=len(line_slices))
        for ls in line_slices:
            lines.append(String(ls))
        blocks.append(lines^)
        if widest > max_width:
            max_width = widest

    return _merge_blocks_vertically(blocks, max_width, pos)
