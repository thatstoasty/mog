from .position import Position


struct PropKey:
    """Property keys for the style."""

    alias BOLD = 1
    """Bold text."""
    alias ITALIC = 2
    """Italicize text."""
    alias UNDERLINE = 3
    """Underline text."""
    alias CROSSOUT = 4
    """Crossout text."""
    alias REVERSE = 5
    """Reverse text foreground/background coloring."""
    alias BLINK = 6
    """Blink text."""
    alias FAINT = 7
    """Faint text."""
    alias FOREGROUND = 8
    """Foreground color."""
    alias BACKGROUND = 9
    """Background color."""
    alias WIDTH = 10
    """Text width."""
    alias HEIGHT = 11
    """Text height."""
    alias HORIZONTAL_ALIGNMENT = 12
    """Horizontal alignment."""
    alias VERTICAL_ALIGNMENT = 13
    """Vertical alignment."""

    # Padding.
    alias PADDING_TOP = 14
    """Padding level at the top of the text."""
    alias PADDING_RIGHT = 15
    """Padding level to the right of the text."""
    alias PADDING_BOTTOM = 16
    """Padding level at the bottom of the text."""
    alias PADDING_LEFT = 17
    """Padding level to the left of the text."""

    alias COLOR_WHITESPACE = 18
    """Color of whitespace background."""

    # Margins.
    alias MARGIN_TOP = 19
    """Margin level at the top of the text."""
    alias MARGIN_RIGHT = 20
    """Margin level to the right of the text."""
    alias MARGIN_BOTTOM = 21
    """Margin level at the bottom of the text."""
    alias MARGIN_LEFT = 22
    """Margin level to the left of the text."""
    alias MARGIN_BACKGROUND = 23
    """Margin background color."""

    # Border style.
    alias BORDER_STYLE = 24
    """Border style."""

    # Border edges.
    alias BORDER_TOP = 25
    """Border top."""
    alias BORDER_RIGHT = 26
    """Border right."""
    alias BORDER_BOTTOM = 27
    """Border bottom."""
    alias BORDER_LEFT = 28
    """Border left."""

    # Border foreground colors.
    alias BORDER_TOP_FOREGROUND = 29
    """Border top foreground color."""
    alias BORDER_RIGHT_FOREGROUND = 30
    """Border right foreground color."""
    alias BORDER_BOTTOM_FOREGROUND = 31
    """Border bottom foreground color."""
    alias BORDER_LEFT_FOREGROUND = 32
    """Border left foreground color."""

    # Border background colors.
    alias BORDER_TOP_BACKGROUND = 33
    """Border top background color."""
    alias BORDER_RIGHT_BACKGROUND = 34
    """Border right background color."""
    alias BORDER_BOTTOM_BACKGROUND = 35
    """Border bottom background color."""
    alias BORDER_LEFT_BACKGROUND = 36
    """Border left background color."""

    alias INLINE = 37
    """Inline rendering."""
    alias MAX_WIDTH = 38
    """Maximum width of the text."""
    alias MAX_HEIGHT = 39
    """Maximum height of the text."""
    alias TAB_WIDTH = 40
    """Tab width."""
    alias UNDERLINE_SPACES = 41
    """Underline spaces between words."""
    alias CROSSOUT_SPACES = 42
    """Crossout spaces between words."""


@register_passable("trivial")
struct Properties:
    """Properties for a style."""

    var value: SIMD[DType.bool, 64]
    """Array of attributes with 1 or 0 values to determine if a property is set."""

    fn __init__(out self, value: SIMD[DType.bool, 64] = SIMD[DType.bool, 64]()):
        """Initialize a new Properties object.

        Args:
            value: The value to set the properties to.
        """
        self.value = value

    fn set(mut self, key: Int, value: Bool) -> None:
        """Set a property.

        Args:
            key: The key to set.
            value: The value to set the property to.
        """
        self.value[key] = value

    fn has(self, key: Int) -> Bool:
        """Check if a property is set.

        Args:
            key: The key to check.

        Returns:
            True if the property is set, False otherwise.
        """
        return self.value[key]


@value
@register_passable("trivial")
struct Padding:
    var top: Int
    """The padding level at the top of the text."""
    var right: Int
    """The padding level to the right of the text."""
    var bottom: Int
    """The padding level at the bottom of the text."""
    var left: Int
    """The padding level to the left of the text."""

    fn __init__(out self, top: Int = 0, right: Int = 0, bottom: Int = 0, left: Int = 0):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left


@value
struct Margin:
    var top: Int
    """The margin level at the top of the text."""
    var right: Int
    """The margin level to the right of the text."""
    var bottom: Int
    """The margin level at the bottom of the text."""
    var left: Int
    """The margin level to the left of the text."""
    var background: AnyTerminalColor
    """The background color of the margin."""

    fn __init__(
        out self,
        top: Int = 0,
        right: Int = 0,
        bottom: Int = 0,
        left: Int = 0,
        background: AnyTerminalColor = NoColor(),
    ):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
        self.background = background


@value
@register_passable("trivial")
struct Dimensions:
    var height: Int
    """The height of the text."""
    var width: Int
    """The width of the text."""

    fn __init__(out self, height: Int = 0, width: Int = 0):
        self.height = height
        self.width = width


@value
@register_passable("trivial")
struct Alignment:
    var horizontal: Position
    """The horizontal alignment of the text."""
    var vertical: Position
    """The vertical alignment of the text."""

    fn __init__(out self, horizontal: Position = 0, vertical: Position = 0):
        self.horizontal = horizontal
        self.vertical = vertical


@value
struct Coloring:
    var foreground: AnyTerminalColor
    """The foreground color."""
    var background: AnyTerminalColor
    """The background color."""

    fn __init__(out self, foreground: AnyTerminalColor = NoColor(), background: AnyTerminalColor = NoColor()):
        self.foreground = foreground
        self.background = background


@value
struct BorderColor:
    var foreground_top: AnyTerminalColor
    """The foreground color of the top border."""
    var foreground_right: AnyTerminalColor
    """The foreground color of the right border."""
    var foreground_bottom: AnyTerminalColor
    """The foreground color of the bottom border."""
    var foreground_left: AnyTerminalColor
    """The foreground color of the left border."""
    var background_top: AnyTerminalColor
    """The background color of the top border."""
    var background_right: AnyTerminalColor
    """The background color of the right border."""
    var background_bottom: AnyTerminalColor
    """The background color of the bottom border."""
    var background_left: AnyTerminalColor
    """The background color of the left border."""

    fn __init__(
        out self,
        foreground_top: AnyTerminalColor = NoColor(),
        foreground_right: AnyTerminalColor = NoColor(),
        foreground_bottom: AnyTerminalColor = NoColor(),
        foreground_left: AnyTerminalColor = NoColor(),
        background_top: AnyTerminalColor = NoColor(),
        background_right: AnyTerminalColor = NoColor(),
        background_bottom: AnyTerminalColor = NoColor(),
        background_left: AnyTerminalColor = NoColor(),
    ):
        self.foreground_top = foreground_top
        self.foreground_right = foreground_right
        self.foreground_bottom = foreground_bottom
        self.foreground_left = foreground_left
        self.background_top = background_top
        self.background_right = background_right
        self.background_bottom = background_bottom
        self.background_left = background_left