from mist.transform.ansi import printable_rune_width


struct Border(Copyable, ImplicitlyCopyable, Movable):
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

    fn __init__(
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

    fn copy(self) -> Border:
        """Create a copy of the border.

        Returns:
            A new instance of the border with the same properties.
        """
        return Border(
            top=self.top,
            bottom=self.bottom,
            left=self.left,
            right=self.right,
            top_left=self.top_left,
            top_right=self.top_right,
            bottom_left=self.bottom_left,
            bottom_right=self.bottom_right,
            middle_left=self.middle_left,
            middle_right=self.middle_right,
            middle=self.middle,
            middle_top=self.middle_top,
            middle_bottom=self.middle_bottom,
        )

    fn __eq__(self, other: Border) -> Bool:
        """Check if two borders are equal.

        Args:
            other: The other border to compare.

        Returns:
            Whether the two borders are equal.
        """
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
        """Check if two borders are not equal.

        Args:
            other: The other border to compare.

        Returns:
            Whether the two borders are not equal.
        """
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


fn render_horizontal_edge(left: StringSlice, var middle: String, right: StringSlice, width: Int) -> String:
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

    var output = String(left)
    var middle_slice = middle.as_string_slice()
    var i = left_width + right_width
    var j = 0
    while i < width + right_width:
        output.write(middle_slice[j])
        j += 1

        if j >= len(middle_slice):
            j = 0

        i += printable_rune_width(middle_slice[j])

    output.write(right)
    return output^
