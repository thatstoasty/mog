from .weave.ansi import printable_rune_width


@value
struct Border:
    var top: String
    var bottom: String
    var left: String
    var right: String
    var top_left: String
    var top_right: String
    var bottom_left: String
    var bottom_right: String
    var middle_left: String
    var middle_right: String
    var middle: String
    var middle_top: String
    var middle_bottom: String

    fn __init__(
        inout self,
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

    fn __eq__(self, other: Border) -> Bool:
        return (
            self.top == other.top
            and self.bottom == other.bottom
            and self.left == other.left
            and self.right == other.right
            and self.top_left == other.top_left
            and self.top_right == other.top_right
            and self.bottom_left == other.bottom_left
            and self.bottom_right == other.bottom_right
            and self.middle_left == other.middle_left
            and self.middle_right == other.middle_right
            and self.middle == other.middle
            and self.middle_top == other.middle_top
            and self.middle_bottom == other.middle_bottom
        )

    fn __ne__(self, other: Border) -> Bool:
        return (
            self.top != other.top
            or self.bottom != other.bottom
            or self.left != other.left
            or self.right != other.right
            or self.top_left != other.top_left
            or self.top_right != other.top_right
            or self.bottom_left != other.bottom_left
            or self.bottom_right != other.bottom_right
            or self.middle_left != other.middle_left
            or self.middle_right != other.middle_right
            or self.middle != other.middle
            or self.middle_top != other.middle_top
            or self.middle_bottom != other.middle_bottom
        )


alias ASCII_BORDER = Border(
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


alias STAR_BORDER = Border(
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


alias PLUS_BORDER = Border(
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


alias NORMAL_BORDER = Border(
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


alias ROUNDED_BORDER = Border(
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


alias BLOCK_BORDER = Border(
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


alias OUTER_HALF_BLOCK_BORDER = Border(
    top="▀",
    bottom="▄",
    left="▌",
    right="▐",
    top_left="▛",
    top_right="▜",
    bottom_left="▙",
    bottom_right="▟",
)


alias INNER_HALF_BLOCK_BORDER = Border(
    top="▄",
    bottom="▀",
    left="▐",
    right="▌",
    top_left="▗",
    top_right="▖",
    bottom_left="▝",
    bottom_right="▘",
)


alias THICK_BORDER = Border(
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


alias DOUBLE_BORDER = Border(
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


alias HIDDEN_BORDER = Border(
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


alias NO_BORDER = Border()


fn render_horizontal_edge(left: String, middle: String, right: String, width: Int) -> String:
    """Render the horizontal (top or bottom) portion of a border.

    Args:
        left: The left edge of the border.
        middle: The middle of the border.
        right: The right edge of the border.
        width: The width of the border.

    Returns:
        The rendered horizontal edge.
    """
    var middle_copy = middle

    if width < 1:
        return ""

    if middle == "":
        middle_copy = " "

    var left_width = printable_rune_width(left)
    var right_width = printable_rune_width(right)

    var runes = List[String](middle_copy)
    var output: String = left

    var i = left_width + right_width
    var j = 0
    while i < width + right_width:
        output += runes[j]
        j += 1

        if j >= len(runes):
            j = 0

        i += printable_rune_width(runes[j])

    output += right

    return output
