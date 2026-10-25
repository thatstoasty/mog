from mog.position import Position
from mog.color import TerminalColor, NoColor

__enum PropKey(Equatable, ImplicitlyCopyable, Writable):
    """Property keys for the style."""

    case BOLD
    """Bold text."""
    case ITALIC
    """Italicize text."""
    case UNDERLINE
    """Underline text."""
    case STRIKETHROUGH
    """Crossout text."""
    case REVERSE
    """Reverse text foreground/background coloring."""
    case BLINK
    """Blink text."""
    case FAINT
    """Faint text."""
    case FOREGROUND
    """Foreground color."""
    case BACKGROUND
    """Background color."""
    case WIDTH
    """Text width."""
    case HEIGHT
    """Text height."""
    case HORIZONTAL_ALIGNMENT
    """Horizontal alignment."""
    case VERTICAL_ALIGNMENT
    """Vertical alignment."""

    # Padding.
    case PADDING_TOP
    """Padding level at the top of the text."""
    case PADDING_RIGHT
    """Padding level to the right of the text."""
    case PADDING_BOTTOM
    """Padding level at the bottom of the text."""
    case PADDING_LEFT
    """Padding level to the left of the text."""

    case COLOR_WHITESPACE
    """Color of whitespace background."""

    # Margins.
    case MARGIN_TOP
    """Margin level at the top of the text."""
    case MARGIN_RIGHT
    """Margin level to the right of the text."""
    case MARGIN_BOTTOM
    """Margin level at the bottom of the text."""
    case MARGIN_LEFT
    """Margin level to the left of the text."""
    case MARGIN_BACKGROUND
    """Margin background color."""

    # Border style.
    case BORDER_STYLE
    """Border style."""

    # Border edges.
    case BORDER_TOP
    """Border top."""
    case BORDER_RIGHT
    """Border right."""
    case BORDER_BOTTOM
    """Border bottom."""
    case BORDER_LEFT
    """Border left."""

    # Border foreground colors.
    case BORDER_TOP_FOREGROUND
    """Border top foreground color."""
    case BORDER_RIGHT_FOREGROUND
    """Border right foreground color."""
    case BORDER_BOTTOM_FOREGROUND
    """Border bottom foreground color."""
    case BORDER_LEFT_FOREGROUND
    """Border left foreground color."""

    # Border background colors.
    case BORDER_TOP_BACKGROUND
    """Border top background color."""
    case BORDER_RIGHT_BACKGROUND
    """Border right background color."""
    case BORDER_BOTTOM_BACKGROUND
    """Border bottom background color."""
    case BORDER_LEFT_BACKGROUND
    """Border left background color."""
    case INLINE
    """Inline rendering."""
    case MAX_WIDTH
    """Maximum width of the text."""
    case MAX_HEIGHT
    """Maximum height of the text."""
    case TAB_WIDTH
    """Tab width."""
    case UNDERLINE_SPACES
    """Underline spaces between words."""
    case STRIKETHROUGH_SPACES
    """Crossout spaces between words."""

    def _index(self) -> Int:
        """Returns the bit this key occupies in a `Properties` set.

        Returns:
            The index of the key.
        """
        match self:
            case .BOLD:
                return 1
            case .ITALIC:
                return 2
            case .UNDERLINE:
                return 3
            case .STRIKETHROUGH:
                return 4
            case .REVERSE:
                return 5
            case .BLINK:
                return 6
            case .FAINT:
                return 7
            case .FOREGROUND:
                return 8
            case .BACKGROUND:
                return 9
            case .WIDTH:
                return 10
            case .HEIGHT:
                return 11
            case .HORIZONTAL_ALIGNMENT:
                return 12
            case .VERTICAL_ALIGNMENT:
                return 13
            case .PADDING_TOP:
                return 14
            case .PADDING_RIGHT:
                return 15
            case .PADDING_BOTTOM:
                return 16
            case .PADDING_LEFT:
                return 17
            case .COLOR_WHITESPACE:
                return 18
            case .MARGIN_TOP:
                return 19
            case .MARGIN_RIGHT:
                return 20
            case .MARGIN_BOTTOM:
                return 21
            case .MARGIN_LEFT:
                return 22
            case .MARGIN_BACKGROUND:
                return 23
            case .BORDER_STYLE:
                return 24
            case .BORDER_TOP:
                return 25
            case .BORDER_RIGHT:
                return 26
            case .BORDER_BOTTOM:
                return 27
            case .BORDER_LEFT:
                return 28
            case .BORDER_TOP_FOREGROUND:
                return 29
            case .BORDER_RIGHT_FOREGROUND:
                return 30
            case .BORDER_BOTTOM_FOREGROUND:
                return 31
            case .BORDER_LEFT_FOREGROUND:
                return 32
            case .BORDER_TOP_BACKGROUND:
                return 33
            case .BORDER_RIGHT_BACKGROUND:
                return 34
            case .BORDER_BOTTOM_BACKGROUND:
                return 35
            case .BORDER_LEFT_BACKGROUND:
                return 36
            case .INLINE:
                return 37
            case .MAX_WIDTH:
                return 38
            case .MAX_HEIGHT:
                return 39
            case .TAB_WIDTH:
                return 40
            case .UNDERLINE_SPACES:
                return 41
            case .STRIKETHROUGH_SPACES:
                return 42

    def __eq__(self, other: Self) -> Bool:
        """Checks whether two keys are the same.

        Args:
            other: The key to compare against.

        Returns:
            True if both are the same key, False otherwise.
        """
        return self._index() == other._index()


struct Properties(Equatable, Writable, TrivialRegisterPassable):
    """Properties for a style."""

    var value: SIMD[DType.bool, 64]
    """Array of attributes with 1 or 0 values to determine if a property is set."""

    def __init__(out self, value: SIMD[DType.bool, 64] = SIMD[DType.bool, 64]()):
        """Initialize a new Properties object.

        Args:
            value: The value to set the properties to.
        """
        self.value = value

    def set[key: PropKey](mut self, value: Bool) -> None:
        """Set a property.

        Parameters:
            key: The key to check.

        Args:
            value: The value to set the property to.
        """
        self.value[key._index()] = value

    def has[key: PropKey](self) -> Bool:
        """Check if a property is set.

        Parameters:
            key: The key to check.

        Returns:
            True if the property is set, False otherwise.
        """
        return self.value[key._index()]


struct Padding(Equatable, Writable, TrivialRegisterPassable):
    """Padding of the text area."""

    var top: UInt16
    """The padding level at the top of the text."""
    var right: UInt16
    """The padding level to the right of the text."""
    var bottom: UInt16
    """The padding level at the bottom of the text."""
    var left: UInt16
    """The padding level to the left of the text."""

    def __init__(out self, *, top: UInt16 = 0, right: UInt16 = 0, bottom: UInt16 = 0, left: UInt16 = 0):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left

    def __init__(out self, width: UInt16):
        self.top = width
        self.right = width
        self.bottom = width
        self.left = width

    def __init__(out self, x_width: UInt16, y_width: UInt16):
        self.top = y_width
        self.right = x_width
        self.bottom = y_width
        self.left = x_width


struct Margin(Equatable, Writable, ImplicitlyCopyable):
    """Margin of the text area."""

    var top: UInt16
    """The margin level at the top of the text."""
    var right: UInt16
    """The margin level to the right of the text."""
    var bottom: UInt16
    """The margin level at the bottom of the text."""
    var left: UInt16
    """The margin level to the left of the text."""
    var background: TerminalColor
    """The background color of the margin."""

    def __init__(
        out self,
        top: UInt16 = 0,
        right: UInt16 = 0,
        bottom: UInt16 = 0,
        left: UInt16 = 0,
        var background: TerminalColor = NoColor(),
    ):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
        self.background = background^

    def __init__(out self, width: UInt16, var background: TerminalColor = NoColor()):
        self.top = width
        self.right = width
        self.bottom = width
        self.left = width
        self.background = background^

    def __init__(out self, x_width: UInt16, y_width: UInt16, var background: TerminalColor = NoColor()):
        self.top = y_width
        self.right = x_width
        self.bottom = y_width
        self.left = x_width
        self.background = background^


struct Dimensions(Equatable, Writable, TrivialRegisterPassable):
    """Dimensions of the text area."""

    var height: UInt16
    """The height of the text."""
    var width: UInt16
    """The width of the text."""

    def __init__(out self, height: UInt16 = 0, width: UInt16 = 0):
        self.height = height
        self.width = width


struct Coloring(Equatable, Writable, ImplicitlyCopyable):
    """Coloring properties for the text."""

    var foreground: TerminalColor
    """The foreground color."""
    var background: TerminalColor
    """The background color."""

    def __init__(out self, var foreground: TerminalColor = NoColor(), var background: TerminalColor = NoColor()):
        self.foreground = foreground^
        self.background = background^


struct BorderColor(Equatable, Writable, ImplicitlyCopyable):
    """Border coloring properties for the text."""

    var foreground_top: TerminalColor
    """The foreground color of the top border."""
    var foreground_right: TerminalColor
    """The foreground color of the right border."""
    var foreground_bottom: TerminalColor
    """The foreground color of the bottom border."""
    var foreground_left: TerminalColor
    """The foreground color of the left border."""
    var background_top: TerminalColor
    """The background color of the top border."""
    var background_right: TerminalColor
    """The background color of the right border."""
    var background_bottom: TerminalColor
    """The background color of the bottom border."""
    var background_left: TerminalColor
    """The background color of the left border."""

    def __init__(
        out self,
        var foreground_top: TerminalColor = NoColor(),
        var foreground_right: TerminalColor = NoColor(),
        var foreground_bottom: TerminalColor = NoColor(),
        var foreground_left: TerminalColor = NoColor(),
        var background_top: TerminalColor = NoColor(),
        var background_right: TerminalColor = NoColor(),
        var background_bottom: TerminalColor = NoColor(),
        var background_left: TerminalColor = NoColor(),
    ):
        self.foreground_top = foreground_top^
        self.foreground_right = foreground_right^
        self.foreground_bottom = foreground_bottom^
        self.foreground_left = foreground_left^
        self.background_top = background_top^
        self.background_right = background_right^
        self.background_bottom = background_bottom^
        self.background_left = background_left^


__enum Side(Equatable, ImplicitlyCopyable, Writable):
    """A side of the text area."""

    case TOP
    """Indicates the top side of the text area."""
    case RIGHT
    """Indicates the right side of the text area."""
    case BOTTOM
    """Indicates the bottom side of the text area."""
    case LEFT
    """Indicates the left side of the text area."""

    def _index(self) -> Int:
        """Returns a distinct number for this case.

        Returns:
            The index of the case.
        """
        match self:
            case .TOP:
                return 0
            case .RIGHT:
                return 1
            case .BOTTOM:
                return 2
            case .LEFT:
                return 3

    def __eq__(self, other: Self) -> Bool:
        """Checks whether two values are the same case.

        Args:
            other: The value to compare against.

        Returns:
            True if both are the same case, False otherwise.
        """
        return self._index() == other._index()


__enum Emphasis(Equatable, ImplicitlyCopyable, Writable):
    """Emphasis properties for the text."""

    case BOLD
    """Whether the text is bold."""
    case ITALIC
    """Whether the text is italic."""
    case UNDERLINE
    """Whether the text is underlined."""
    case STRIKETHROUGH
    """Whether the text is strikethrough."""
    case REVERSE
    """Whether the text is reversed."""
    case BLINK
    """Whether the text is blinking."""
    case FAINT
    """Whether the text is faint."""
    case UNDERLINE_SPACES
    """Whether spaces between words are underlined."""
    case STRIKETHROUGH_SPACES
    """Whether spaces between words are strikethrough."""
    case COLOR_WHITESPACE
    """Whether whitespace background is colored."""

    def _index(self) -> Int:
        """Returns a distinct number for this case.

        Returns:
            The index of the case.
        """
        match self:
            case .BOLD:
                return 0
            case .ITALIC:
                return 1
            case .UNDERLINE:
                return 2
            case .STRIKETHROUGH:
                return 3
            case .REVERSE:
                return 4
            case .BLINK:
                return 5
            case .FAINT:
                return 6
            case .UNDERLINE_SPACES:
                return 7
            case .STRIKETHROUGH_SPACES:
                return 8
            case .COLOR_WHITESPACE:
                return 9

    def __eq__(self, other: Self) -> Bool:
        """Checks whether two values are the same case.

        Args:
            other: The value to compare against.

        Returns:
            True if both are the same case, False otherwise.
        """
        return self._index() == other._index()


__enum Axis(Equatable, ImplicitlyCopyable, Writable):
    """Axis for alignment and placement."""

    case HORIZONTAL
    """Whether the axis is horizontal."""
    case VERTICAL
    """Whether the axis is vertical."""

    def _index(self) -> Int:
        """Returns a distinct number for this case.

        Returns:
            The index of the case.
        """
        match self:
            case .HORIZONTAL:
                return 0
            case .VERTICAL:
                return 1

    def __eq__(self, other: Self) -> Bool:
        """Checks whether two values are the same case.

        Args:
            other: The value to compare against.

        Returns:
            True if both are the same case, False otherwise.
        """
        return self._index() == other._index()
