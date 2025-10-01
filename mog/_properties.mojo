from mog.position import Position


@fieldwise_init
@register_passable("trivial")
struct PropKey(Copyable, EqualityComparable, Movable):
    """Property keys for the style."""

    var _value: UInt8
    alias BOLD = Self(1)
    """Bold text."""
    alias ITALIC = Self(2)
    """Italicize text."""
    alias UNDERLINE = Self(3)
    """Underline text."""
    alias STRIKETHROUGH = Self(4)
    """Crossout text."""
    alias REVERSE = Self(5)
    """Reverse text foreground/background coloring."""
    alias BLINK = Self(6)
    """Blink text."""
    alias FAINT = Self(7)
    """Faint text."""
    alias FOREGROUND = Self(8)
    """Foreground color."""
    alias BACKGROUND = Self(9)
    """Background color."""
    alias WIDTH = Self(10)
    """Text width."""
    alias HEIGHT = Self(11)
    """Text height."""
    alias HORIZONTAL_ALIGNMENT = Self(12)
    """Horizontal alignment."""
    alias VERTICAL_ALIGNMENT = Self(13)
    """Vertical alignment."""

    # Padding.
    alias PADDING_TOP = Self(14)
    """Padding level at the top of the text."""
    alias PADDING_RIGHT = Self(15)
    """Padding level to the right of the text."""
    alias PADDING_BOTTOM = Self(16)
    """Padding level at the bottom of the text."""
    alias PADDING_LEFT = Self(17)
    """Padding level to the left of the text."""

    alias COLOR_WHITESPACE = Self(18)
    """Color of whitespace background."""

    # Margins.
    alias MARGIN_TOP = Self(19)
    """Margin level at the top of the text."""
    alias MARGIN_RIGHT = Self(20)
    """Margin level to the right of the text."""
    alias MARGIN_BOTTOM = Self(21)
    """Margin level at the bottom of the text."""
    alias MARGIN_LEFT = Self(22)
    """Margin level to the left of the text."""
    alias MARGIN_BACKGROUND = Self(23)
    """Margin background color."""

    # Border style.
    alias BORDER_STYLE = Self(24)
    """Border style."""

    # Border edges.
    alias BORDER_TOP = Self(25)
    """Border top."""
    alias BORDER_RIGHT = Self(26)
    """Border right."""
    alias BORDER_BOTTOM = Self(27)
    """Border bottom."""
    alias BORDER_LEFT = Self(28)
    """Border left."""

    # Border foreground colors.
    alias BORDER_TOP_FOREGROUND = Self(29)
    """Border top foreground color."""
    alias BORDER_RIGHT_FOREGROUND = Self(30)
    """Border right foreground color."""
    alias BORDER_BOTTOM_FOREGROUND = Self(31)
    """Border bottom foreground color."""
    alias BORDER_LEFT_FOREGROUND = Self(32)
    """Border left foreground color."""

    # Border background colors.
    alias BORDER_TOP_BACKGROUND = Self(33)
    """Border top background color."""
    alias BORDER_RIGHT_BACKGROUND = Self(34)
    """Border right background color."""
    alias BORDER_BOTTOM_BACKGROUND = Self(35)
    """Border bottom background color."""
    alias BORDER_LEFT_BACKGROUND = Self(36)
    """Border left background color."""

    alias INLINE = Self(37)
    """Inline rendering."""
    alias MAX_WIDTH = Self(38)
    """Maximum width of the text."""
    alias MAX_HEIGHT = Self(39)
    """Maximum height of the text."""
    alias TAB_WIDTH = Self(40)
    """Tab width."""
    alias UNDERLINE_SPACES = Self(41)
    """Underline spaces between words."""
    alias STRIKETHROUGH_SPACES = Self(42)
    """Crossout spaces between words."""

    fn __eq__(self, other: PropKey) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: PropKey) -> Bool:
        return self._value != other._value


@register_passable("trivial")
struct Properties(Copyable, Movable):
    """Properties for a style."""

    var value: SIMD[DType.bool, 64]
    """Array of attributes with 1 or 0 values to determine if a property is set."""

    fn __init__(out self, value: SIMD[DType.bool, 64] = SIMD[DType.bool, 64]()):
        """Initialize a new Properties object.

        Args:
            value: The value to set the properties to.
        """
        self.value = value

    fn set[key: PropKey](mut self, value: Bool) -> None:
        """Set a property.

        Parameters:
            key: The key to check.

        Args:
            value: The value to set the property to.
        """
        self.value[Int(key._value)] = value

    fn has[key: PropKey](self) -> Bool:
        """Check if a property is set.

        Parameters:
            key: The key to check.

        Returns:
            True if the property is set, False otherwise.
        """
        return self.value[Int(key._value)]


@register_passable("trivial")
struct Padding(Copyable, Movable):
    var top: UInt16
    """The padding level at the top of the text."""
    var right: UInt16
    """The padding level to the right of the text."""
    var bottom: UInt16
    """The padding level at the bottom of the text."""
    var left: UInt16
    """The padding level to the left of the text."""

    fn __init__(out self, *, top: UInt16 = 0, right: UInt16 = 0, bottom: UInt16 = 0, left: UInt16 = 0):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    
    fn __init__(out self, width: UInt16):
        self.top = width
        self.right = width
        self.bottom = width
        self.left = width
    
    fn __init__(out self, x_width: UInt16, y_width: UInt16):
        self.top = y_width
        self.right = x_width
        self.bottom = y_width
        self.left = x_width


struct Margin(Copyable, ImplicitlyCopyable, Movable):
    var top: UInt16
    """The margin level at the top of the text."""
    var right: UInt16
    """The margin level to the right of the text."""
    var bottom: UInt16
    """The margin level at the bottom of the text."""
    var left: UInt16
    """The margin level to the left of the text."""
    var background: AnyTerminalColor
    """The background color of the margin."""

    fn __init__(
        out self,
        top: UInt16 = 0,
        right: UInt16 = 0,
        bottom: UInt16 = 0,
        left: UInt16 = 0,
        var background: AnyTerminalColor = NoColor(),
    ):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
        self.background = background^
    
    fn __init__(out self, width: UInt16, var background: AnyTerminalColor = NoColor()):
        self.top = width
        self.right = width
        self.bottom = width
        self.left = width
        self.background = background^
    
    fn __init__(out self, x_width: UInt16, y_width: UInt16, var background: AnyTerminalColor = NoColor()):
        self.top = y_width
        self.right = x_width
        self.bottom = y_width
        self.left = x_width
        self.background = background^

    fn __moveinit__(out self, deinit other: Self):
        self.top = other.top
        self.right = other.right
        self.bottom = other.bottom
        self.left = other.left
        self.background = other.background^

    fn copy(self) -> Self:
        return Self(
            top=self.top, right=self.right, bottom=self.bottom, left=self.left, background=self.background.copy()
        )


@register_passable("trivial")
struct Dimensions(Copyable, Movable):
    var height: UInt16
    """The height of the text."""
    var width: UInt16
    """The width of the text."""

    fn __init__(out self, height: UInt16 = 0, width: UInt16 = 0):
        self.height = height
        self.width = width


struct Coloring(Copyable, ImplicitlyCopyable, Movable):
    var foreground: AnyTerminalColor
    """The foreground color."""
    var background: AnyTerminalColor
    """The background color."""

    fn __init__(out self, var foreground: AnyTerminalColor = NoColor(), var background: AnyTerminalColor = NoColor()):
        self.foreground = foreground^
        self.background = background^

    fn __moveinit__(out self, deinit other: Self):
        self.foreground = other.foreground^
        self.background = other.background^

    fn copy(self) -> Self:
        return Self(foreground=self.foreground.copy(), background=self.background.copy())


struct BorderColor(Copyable, ImplicitlyCopyable, Movable):
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
        var foreground_top: AnyTerminalColor = NoColor(),
        var foreground_right: AnyTerminalColor = NoColor(),
        var foreground_bottom: AnyTerminalColor = NoColor(),
        var foreground_left: AnyTerminalColor = NoColor(),
        var background_top: AnyTerminalColor = NoColor(),
        var background_right: AnyTerminalColor = NoColor(),
        var background_bottom: AnyTerminalColor = NoColor(),
        var background_left: AnyTerminalColor = NoColor(),
    ):
        self.foreground_top = foreground_top^
        self.foreground_right = foreground_right^
        self.foreground_bottom = foreground_bottom^
        self.foreground_left = foreground_left^
        self.background_top = background_top^
        self.background_right = background_right^
        self.background_bottom = background_bottom^
        self.background_left = background_left^

    fn __moveinit__(out self, deinit other: Self):
        self.foreground_top = other.foreground_top^
        self.foreground_right = other.foreground_right^
        self.foreground_bottom = other.foreground_bottom^
        self.foreground_left = other.foreground_left^
        self.background_top = other.background_top^
        self.background_right = other.background_right^
        self.background_bottom = other.background_bottom^
        self.background_left = other.background_left^

    fn copy(self) -> Self:
        return Self(
            foreground_top=self.foreground_top.copy(),
            foreground_right=self.foreground_right.copy(),
            foreground_bottom=self.foreground_bottom.copy(),
            foreground_left=self.foreground_left.copy(),
            background_top=self.background_top.copy(),
            background_right=self.background_right.copy(),
            background_bottom=self.background_bottom.copy(),
            background_left=self.background_left.copy(),
        )


@fieldwise_init
struct Side(ImplicitlyCopyable, Copyable, Movable, EqualityComparable):
    var value: UInt8

    alias TOP = Self(0)
    alias RIGHT = Self(1)
    alias BOTTOM = Self(2)
    alias LEFT = Self(3)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


@fieldwise_init
struct Emphasis(ImplicitlyCopyable, Copyable, Movable, EqualityComparable):
    var value: UInt8
    alias BOLD = Self(0)
    """Whether the text is bold."""
    alias ITALIC = Self(1)
    """Whether the text is italic."""
    alias UNDERLINE = Self(2)
    """Whether the text is underlined."""
    alias STRIKETHROUGH = Self(3)
    """Whether the text is strikethrough."""
    alias REVERSE = Self(4)
    """Whether the text is reversed."""
    alias BLINK = Self(5)
    """Whether the text is blinking."""
    alias FAINT = Self(6)
    """Whether the text is faint."""
    alias UNDERLINE_SPACES = Self(7)
    """Whether spaces between words are underlined."""
    alias STRIKETHROUGH_SPACES = Self(8)
    """Whether spaces between words are strikethrough."""
    alias COLOR_WHITESPACE = Self(9)
    """Whether whitespace background is colored."""

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


@fieldwise_init
struct Axis(ImplicitlyCopyable, Copyable, Movable, EqualityComparable):
    var value: UInt8
    alias HORIZONTAL = Self(0)
    """Whether the axis is horizontal."""
    alias VERTICAL = Self(1)
    """Whether the axis is vertical."""

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value