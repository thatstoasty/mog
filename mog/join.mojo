from mog.position import Position, top, bottom, left, right, center
from mog.extensions import get_slice
from mog.external.stdlib.builtins.vector import extend
from mog.external.stdlib.builtins.string import __string__mul__
from mog.external.weave.ansi.ansi import printable_rune_width
from mog.external.weave.gojo.bytes import buffer
from mog.external.weave.gojo.bytes.bytes import Byte


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
    var blocks = DynamicVector[DynamicVector[String]](len(strs))

    # Max line widths for the above text blocks
    var max_widths = DynamicVector[Int](len(strs))
    var max_height: Int = 0

    # Break text blocks into lines and get max widths for each text block
    for i in range(len(strs)):
        let s = strs[i]
        let lines = s.split("\n")
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
    for i in range(blocks.size):
        if len(blocks[i]) >= max_height:
            continue

        var extra_lines = DynamicVector[String](max_height - len(blocks[i]))

        if pos == top:
            extend(blocks[i], extra_lines)
        elif pos == bottom:
            extend(blocks[i], extra_lines)
        else:
            let n = len(extra_lines)
            let split = UInt8(n) * pos
            let top_point = n - split
            let bottom_point = n - top

            var top_lines = get_slice(extra_lines, int(top), int(len(extra_lines)))
            var bottom_lines = get_slice(
                extra_lines, int(bottom), int(len(extra_lines))
            )
            extend(top_lines, blocks[i])
            extend(blocks[i], bottom_lines)

    # Merge lines
    var buf = DynamicVector[Byte]()
    var b = buffer.Buffer(buf)
    for i in range(len(blocks)):
        let block = blocks[i]
        for j in range(len(block)):
            # print("block", j, "line", i, blocks[j][i])
            _ = b.write_string(blocks[j][i])

            # Also make lines the same length
            let spaces = __string__mul__(
                " ", max_widths[j] - printable_rune_width(blocks[j][i])
            )
            # print("spaces: ", spaces)
            _ = b.write_string(spaces)
        if i < len(blocks[0]) - 1:
            _ = b.write_string("\n")

    return b.string()


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
fn join_horizontal(pos: Position, strs: DynamicVector[String]) raises -> String:
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = DynamicVector[DynamicVector[String]](len(strs))

    # Max line widths for the above text blocks
    var max_widths = DynamicVector[Int](len(strs))
    var max_height: Int = 0

    # Break text blocks into lines and get max widths for each text block
    for i in range(len(strs)):
        let s = strs[i]
        let lines = s.split("\n")
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
    for i in range(blocks.size):
        if len(blocks[i]) >= max_height:
            continue

        var extra_lines = DynamicVector[String](max_height - len(blocks[i]))

        if pos == top:
            extend(blocks[i], extra_lines)
        elif pos == bottom:
            extend(blocks[i], extra_lines)
        else:
            let n = len(extra_lines)
            let split = UInt8(n) * pos
            let top_point = n - split
            let bottom_point = n - top

            var top_lines = get_slice(extra_lines, int(top), int(len(extra_lines)))
            var bottom_lines = get_slice(
                extra_lines, int(bottom), int(len(extra_lines))
            )
            extend(top_lines, blocks[i])
            extend(blocks[i], bottom_lines)

    # Merge lines
    var buf = DynamicVector[Byte]()
    var b = buffer.Buffer(buf)
    for i in range(len(blocks)):
        let block = blocks[i]
        for j in range(len(block)):
            # print("block", j, "line", i, blocks[j][i])
            _ = b.write_string(blocks[j][i])

            # Also make lines the same length
            let spaces = __string__mul__(
                " ", max_widths[j] - printable_rune_width(blocks[j][i])
            )
            # print("spaces: ", spaces)
            _ = b.write_string(spaces)
        if i < len(blocks[0]) - 1:
            _ = b.write_string("\n")

    return b.string()


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
    var blocks = DynamicVector[DynamicVector[String]](len(strs))

    # Max line widths for the above text blocks
    var max_width: Int = 0

    for i in range(len(strs)):
        let s = strs[i]
        let lines = s.split("\n")
        var widest: Int = 0
        for i in range(lines.size):
            # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
            if len(lines[i]) > widest:
                widest = len(lines[i])

        blocks.append(lines)

        if widest > max_width:
            max_width = widest

    var buf = DynamicVector[Byte]()
    var b = buffer.Buffer(buf)
    var w: Int = 0
    for i in range(len(blocks)):
        var block = blocks[i]
        for j in range(len(block)):
            let line = block[j]
            w = max_width - printable_rune_width(line)

            if pos == left:
                _ = b.write_string(line)
                _ = b.write_string(__string__mul__(" ", w))
            elif pos == right:
                _ = b.write_string(__string__mul__(" ", w))
                _ = b.write_string(line)
            else:
                if w < 1:
                    _ = b.write_string(line)
                else:
                    let split = int(w * pos / 2)
                    let right = w - split
                    let left = w - right

                    _ = b.write_string(__string__mul__(" ", left))
                    _ = b.write_string(line)
                    _ = b.write_string(__string__mul__(" ", right))

            if not (i == len(blocks) - 1 and j == len(block) - 1):
                _ = b.write_string("\n")

    return b.string()


fn join_vertical(pos: Position, strs: DynamicVector[String]) raises -> String:
    if len(strs) == 0:
        return ""

    if len(strs) == 1:
        return strs[0]

    # Groups of strings broken into multiple lines
    var blocks = DynamicVector[DynamicVector[String]](len(strs))

    # Max line widths for the above text blocks
    var max_width: Int = 0

    for i in range(len(strs)):
        let s = strs[i]
        let lines = s.split("\n")
        var widest: Int = 0
        for i in range(lines.size):
            # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
            if len(lines[i]) > widest:
                widest = len(lines[i])

        blocks.append(lines)

        if widest > max_width:
            max_width = widest

    var buf = DynamicVector[Byte]()
    var b = buffer.Buffer(buf)
    var w: Int = 0
    for i in range(len(blocks)):
        var block = blocks[i]
        for j in range(len(block)):
            let line = block[j]
            w = max_width - printable_rune_width(line)

            if pos == left:
                _ = b.write_string(line)
                _ = b.write_string(__string__mul__(" ", w))
            elif pos == right:
                _ = b.write_string(__string__mul__(" ", w))
                _ = b.write_string(line)
            else:
                if w < 1:
                    _ = b.write_string(line)
                else:
                    let split = int(w * pos / 2)
                    let right = w - split
                    let left = w - right

                    _ = b.write_string(__string__mul__(" ", left))
                    _ = b.write_string(line)
                    _ = b.write_string(__string__mul__(" ", right))

            if not (i == len(blocks) - 1 and j == len(block) - 1):
                _ = b.write_string("\n")

    return b.string()
