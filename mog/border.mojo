"""A module for rendering borders in the terminal."""

from mist.transform.ansi import printable_rune_width
from std.iter import enumerate


struct Border(Equatable, Writable, ImplicitlyCopyable):
    """A border to use to wrap around text."""

    var top: String
    """The character to use for the top edge."""
    var bottom: String
    """The character to use for the bottom edge."""
    var left: String
    """The character to use for the left edge."""
    var right: String
    """The character to use for the right edge."""
    var top_left: String
    """The character to use for the top left corner."""
    var top_right: String
    """The character to use for the top right corner."""
    var bottom_left: String
    """The character to use for the bottom left corner."""
    var bottom_right: String
    """The character to use for the bottom right corner."""
    var middle_left: String
    """The character to use for the left edge of the middle."""
    var middle_right: String
    """The character to use for the right edge of the middle."""
    var middle: String
    """The character to use for the middle."""
    var middle_top: String
    """The character to use for the top edge of the middle."""
    var middle_bottom: String
    """The character to use for the bottom edge of the middle."""

    def __init__(
        out self,
        top: String = "",
        bottom: String = "",
        left: String = "",
        right: String = "",
        top_left: String = "",
        top_right: String = "",
        bottom_left: String = "",
        bottom_right: String = "",
        middle_left: String = "",
        middle_right: String = "",
        middle: String = "",
        middle_top: String = "",
        middle_bottom: String = "",
    ):
        """Initialize a new border.

        Args:
            top: The character to use for the top edge.
            bottom: The character to use for the bottom edge.
            left: The character to use for the left edge.
            right: The character to use for the right edge.
            top_left: The character to use for the top left corner.
            top_right: The character to use for the top right corner.
            bottom_left: The character to use for the bottom left corner.
            bottom_right: The character to use for the bottom right corner.
            middle_left: The character to use for the left edge of the middle.
            middle_right: The character to use for the right edge of the middle.
            middle: The character to use for the middle.
            middle_top: The character to use for the top edge of the middle.
            middle_bottom: The character to use for the bottom edge of the middle.
        """
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.top_left = top_left
        self.top_right = top_right
        self.bottom_left = bottom_left
        self.bottom_right = bottom_right
        self.middle_left = middle_left
        self.middle_right = middle_right
        self.middle = middle
        self.middle_top = middle_top
        self.middle_bottom = middle_bottom


comptime ASCII_BORDER = Border(
    top="-",
    bottom="_",
    left="|",
    right="|",
    top_left="*",
    top_right="*",
    bottom_left="*",
    bottom_right="*",
    middle_left="*",
    middle_right="*",
    middle="*",
    middle_top="*",
    middle_bottom="*",
)
"""A border that uses ASCII characters."""

comptime STAR_BORDER = Border(
    top="*",
    bottom="*",
    left="*",
    right="*",
    top_left="*",
    top_right="*",
    bottom_left="*",
    bottom_right="*",
    middle_left="*",
    middle_right="*",
    middle="*",
    middle_top="*",
    middle_bottom="*",
)
"""A border that uses asterisks for all edges."""

comptime PLUS_BORDER = Border(
    top="+",
    bottom="+",
    left="+",
    right="+",
    top_left="+",
    top_right="+",
    bottom_left="+",
    bottom_right="+",
    middle_left="+",
    middle_right="+",
    middle="+",
    middle_top="+",
    middle_bottom="+",
)
"""A border that uses plus signs for all edges."""

comptime NORMAL_BORDER = Border(
    top="─",
    bottom="─",
    left="│",
    right="│",
    top_left="┌",
    top_right="┐",
    bottom_left="└",
    bottom_right="┘",
    middle_left="├",
    middle_right="┤",
    middle="┼",
    middle_top="┬",
    middle_bottom="┴",
)
"""A border that uses line drawing characters for all edges."""

comptime ROUNDED_BORDER = Border(
    top="─",
    bottom="─",
    left="│",
    right="│",
    top_left="╭",
    top_right="╮",
    bottom_left="╰",
    bottom_right="╯",
    middle_left="├",
    middle_right="┤",
    middle="┼",
    middle_top="┬",
    middle_bottom="┴",
)
"""A border that uses rounded corners."""

comptime BLOCK_BORDER = Border(
    top="█",
    bottom="█",
    left="█",
    right="█",
    top_left="█",
    top_right="█",
    bottom_left="█",
    bottom_right="█",
    middle_left="█",
    middle_right="█",
    middle="█",
    middle_top="█",
)
"""A border that uses block characters for all edges."""

comptime OUTER_HALF_BLOCK_BORDER = Border(
    top="▀",
    bottom="▄",
    left="▌",
    right="▐",
    top_left="▛",
    top_right="▜",
    bottom_left="▙",
    bottom_right="▟",
)
"""Outer half thick block border."""

comptime INNER_HALF_BLOCK_BORDER = Border(
    top="▄",
    bottom="▀",
    left="▐",
    right="▌",
    top_left="▗",
    top_right="▖",
    bottom_left="▝",
    bottom_right="▘",
)
"""Inner half thick block border."""

comptime THICK_BORDER = Border(
    top="━",
    bottom="━",
    left="┃",
    right="┃",
    top_left="┏",
    top_right="┓",
    bottom_left="┗",
    bottom_right="┛",
    middle_left="┣",
    middle_right="┫",
    middle="╋",
    middle_top="┳",
    middle_bottom="┻",
)
"""Thick line border."""

comptime DOUBLE_BORDER = Border(
    top="═",
    bottom="═",
    left="║",
    right="║",
    top_left="╔",
    top_right="╗",
    bottom_left="╚",
    bottom_right="╝",
    middle_left="╠",
    middle_right="╣",
    middle="╬",
    middle_top="╦",
    middle_bottom="╩",
)
"""Double line border."""

comptime HIDDEN_BORDER = Border(
    top=" ",
    bottom=" ",
    left=" ",
    right=" ",
    top_left=" ",
    top_right=" ",
    bottom_left=" ",
    bottom_right=" ",
    middle_left=" ",
    middle_right=" ",
    middle=" ",
    middle_top=" ",
    middle_bottom=" ",
)
"""A border that is invisible, all edges are one space."""

comptime NO_BORDER = Border()
"""No border, all edges are empty strings."""


def render_horizontal_edge[lhs_origin: ImmOrigin, rhs_origin: ImmOrigin, //](left: StringSpan[lhs_origin], var middle: String, right: StringSpan[rhs_origin], width: UInt) -> String:
    """Render the horizontal (top or bottom) portion of a border.

    Args:
        left: The left edge of the border.
        middle: The middle of the border.
        right: The right edge of the border.
        width: The width of the border.

    Returns:
        The rendered horizontal edge. This allocates a new `String`.
    """
    if width < 1:
        return ""

    if middle == "":
        middle = " "

    var left_width = printable_rune_width(left)
    var right_width = printable_rune_width(right)

    # Segment `middle` once up front. Indexing it directly would be by byte rather than
    # by character, which splits multi-byte UTF-8. Re-segmenting inside the loop below
    # would repeat that work for every cell of the edge.
    var cells = List[StringSpan[origin_of(middle)]]()
    for grapheme in middle.graphemes():
        cells.append(grapheme)

    var output = String(capacity_bytes=middle.byte_length() * Int(width) + left.byte_length() + right.byte_length())
    output.write(left)
    var i = left_width + right_width
    var j = 0
    # One cell per pass, so the width is checked before each one. Emitting the whole of
    # `middle` per pass and only checking between passes would overshoot the requested
    # width whenever the cell count does not divide the span evenly.
    while i < width + right_width:
        ref cell = cells[j]
        output.write(cell)
        i += printable_rune_width(cell)
        j += 1
        if j >= len(cells):
            j = 0

    output.write(right)
    return output^
