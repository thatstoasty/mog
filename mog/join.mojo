from .position import Position, top, bottom, left, right, center
from .extensions import get_slice, __string__mul__
from external.weave.ansi.ansi import printable_rune_width
from external.gojo.strings import StringBuilder


# join_horizontal is a utility function for horizontally joining two
# potentially multi-lined strings along a vertical axis. The first argument is
# the position, with 0 being all the way at the top and 1 being all the way
# at the bottom.
#
# If you just want to align to the left, right or center you may as well just
# use the helper constants Top, Center, and Bottom.
#
# Example:
#
# 	blockB := "...\n...\n..."
# 	blockA := "...\n...\n...\n...\n..."
#
# 	# Join 20% from the top
# 	str := lipgloss.join_horizontal(0.2, blockA, blockB)
#
# 	# Join on the top edge
# 	str := lipgloss.join_horizontal(lipgloss.Top, blockA, blockB)
fn join_horizontal(pos: Position, *strs: String) raises -> String:
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_widths = List[Int](capacity=len(strs))
    var max_height: Int = 0

    # Break text blocks into lines and get max widths for each text block
    for i in range(len(strs)):
        var s = strs[i]
        var lines = s.split("\n")
        var widest: Int = 0
        for i in range(lines.size):
            # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
            if len(lines[i]) > widest:
                widest = len(lines[i])

        blocks.append(lines)
        max_widths.append(widest)
        if len(lines) > max_height:
            max_height = len(lines)

    # Add extra lines to make each side the same height
    for i in range(len(blocks)):
        if len(blocks[i]) >= max_height:
            continue

        var extra_lines = List[String](capacity=max_height - len(blocks[i]))

        if pos == top:
            blocks[i].extend(extra_lines)
        elif pos == bottom:
            extra_lines.extend(blocks[i])
            blocks[i] = extra_lines
        else:
            var n = len(extra_lines)
            var split = UInt8(n) * pos
            var top_point = n - split
            var bottom_point = n - top

            var top_lines = get_slice(extra_lines, int(top), int(len(extra_lines)))
            var bottom_lines = get_slice(
                extra_lines, int(bottom), int(len(extra_lines))
            )
            top_lines.extend(blocks[i])
            blocks[i] = top_lines
            blocks[i].extend(bottom_lines)

    # Merge lines
    var builder = StringBuilder()
    # remember, all blocks have the same number of members now
    for i in range(len(blocks[0])):
        for j in range(len(blocks)):
            var block = blocks[j]
            _ = builder.write_string(block[i])

            # Also make lines the same length
            var spaces = __string__mul__(
                "", max_widths[j] - printable_rune_width(block[i])
            )
            _ = builder.write_string(spaces)

        if i < len(blocks[0]) - 1:
            _ = builder.write_string("\n")

    return str(builder)


# join_horizontal is a utility function for horizontally joining two
# potentially multi-lined strings along a vertical axis. The first argument is
# the position, with 0 being all the way at the top and 1 being all the way
# at the bottom.
#
# If you just want to align to the left, right or center you may as well just
# use the helper constants Top, Center, and Bottom.
#
# Example:
#
# 	blockB := "...\n...\n..."
# 	blockA := "...\n...\n...\n...\n..."
#
# 	# Join 20% from the top
# 	str := lipgloss.join_horizontal(0.2, blockA, blockB)
#
# 	# Join on the top edge
# 	str := lipgloss.join_horizontal(lipgloss.Top, blockA, blockB)
fn join_horizontal(pos: Position, strs: List[String]) raises -> String:
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_widths = List[Int](capacity=len(strs))
    var max_height: Int = 0

    # Break text blocks into lines and get max widths for each text block
    for i in range(len(strs)):
        var s = strs[i]
        var lines = s.split("\n")
        var widest: Int = 0
        for i in range(lines.size):
            # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
            if len(lines[i]) > widest:
                widest = len(lines[i])

        blocks.append(lines)
        max_widths.append(widest)
        if len(lines) > max_height:
            max_height = len(lines)

    # Add extra lines to make each side the same height
    for i in range(len(blocks)):
        if len(blocks[i]) >= max_height:
            continue

        var extra_lines = List[String](capacity=max_height - len(blocks[i]))

        if pos == top:
            blocks[i].extend(extra_lines)
        elif pos == bottom:
            extra_lines.extend(blocks[i])
            blocks[i] = extra_lines
        else:
            var n = len(extra_lines)
            var split = UInt8(n) * pos
            var top_point = n - split
            var bottom_point = n - top

            var top_lines = get_slice(extra_lines, int(top), int(len(extra_lines)))
            var bottom_lines = get_slice(
                extra_lines, int(bottom), int(len(extra_lines))
            )
            top_lines.extend(blocks[i])
            blocks[i] = top_lines
            blocks[i].extend(bottom_lines)

    # Merge lines
    var builder = StringBuilder()
    # remember, all blocks have the same number of members now
    for i in range(len(blocks[0])):
        for j in range(len(blocks)):
            var block = blocks[j]
            _ = builder.write_string(block[i])

            # Also make lines the same length
            var spaces = __string__mul__(
                "", max_widths[j] - printable_rune_width(block[i])
            )
            _ = builder.write_string(spaces)

        if i < len(blocks[0]) - 1:
            _ = builder.write_string("\n")

    return str(builder)


# join_vertical is a utility function for vertically joining two potentially
# multi-lined strings along a horizontal axis. The first argument is the
# position, with 0 being all the way to the left and 1 being all the way to
# the right.
#
# If you just want to align to the left, right or center you may as well just
# use the helper constants Left, Center, and Right.
#
# Example:
#
# 	blockB := "...\n...\n..."
# 	blockA := "...\n...\n...\n...\n..."
#
# 	# Join 20% from the top
# 	str := lipgloss.join_vertical(0.2, blockA, blockB)
#
# 	# Join on the right edge
# 	str := lipgloss.join_vertical(lipgloss.Right, blockA, blockB)
fn join_vertical(pos: Position, *strs: String) raises -> String:
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_width: Int = 0

    for i in range(len(strs)):
        var s = strs[i]
        var lines = s.split("\n")
        var widest: Int = 0
        for i in range(lines.size):
            # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
            if len(lines[i]) > widest:
                widest = len(lines[i])

        blocks.append(lines)

        if widest > max_width:
            max_width = widest

    var builder = StringBuilder()
    var w: Int = 0
    for i in range(len(blocks)):
        var block = blocks[i]
        for j in range(len(block)):
            var line = block[j]
            w = max_width - printable_rune_width(line)

            if pos == left:
                _ = builder.write_string(line)
                _ = builder.write_string(__string__mul__(" ", w))
            elif pos == right:
                _ = builder.write_string(__string__mul__(" ", w))
                _ = builder.write_string(line)
            else:
                if w < 1:
                    _ = builder.write_string(line)
                else:
                    var split = int(w * pos / 2)
                    var right = w - split
                    var left = w - right

                    _ = builder.write_string(__string__mul__(" ", left))
                    _ = builder.write_string(line)
                    _ = builder.write_string(__string__mul__(" ", right))

            if not (i == len(blocks) - 1 and j == len(block) - 1):
                _ = builder.write_string("\n")

    return str(builder)


fn join_vertical(pos: Position, strs: List[String]) raises -> String:
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = List[List[String]](capacity=len(strs))

    # Max line widths for the above text blocks
    var max_width: Int = 0

    for i in range(len(strs)):
        var s = strs[i]
        var lines = s.split("\n")
        var widest: Int = 0
        for i in range(lines.size):
            # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
            if len(lines[i]) > widest:
                widest = len(lines[i])

        blocks.append(lines)

        if widest > max_width:
            max_width = widest

    var builder = StringBuilder()
    var w: Int = 0
    for i in range(len(blocks)):
        var block = blocks[i]
        for j in range(len(block)):
            var line = block[j]
            w = max_width - printable_rune_width(line)

            if pos == left:
                _ = builder.write_string(line)
                _ = builder.write_string(__string__mul__(" ", w))
            elif pos == right:
                _ = builder.write_string(__string__mul__(" ", w))
                _ = builder.write_string(line)
            else:
                if w < 1:
                    _ = builder.write_string(line)
                else:
                    var split = int(w * pos / 2)
                    var right = w - split
                    var left = w - right

                    _ = builder.write_string(__string__mul__(" ", left))
                    _ = builder.write_string(line)
                    _ = builder.write_string(__string__mul__(" ", right))

            if not (i == len(blocks) - 1 and j == len(block) - 1):
                _ = builder.write_string("\n")

    return str(builder)
