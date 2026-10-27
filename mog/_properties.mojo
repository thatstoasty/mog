from mog.position import Position
from mog.color import TerminalColor, NoColor

__enum PropKey(Equatable, ImplicitlyCopyable, Writable):
    """Property keys for the style."""

    case bold
    """Bold text."""
    case italic
    """Italicize text."""
    case underline
    """Underline text."""
    case strikethrough
    """Crossout text."""
    case reverse
    """Reverse text foreground/background coloring."""
    case blink
    """Blink text."""
    case faint
    """Faint text."""
    case foreground
    """Foreground color."""
    case background
    """Background color."""
    case width
    """Text width."""
    case height
    """Text height."""
    case horizontal_alignment
    """Horizontal alignment."""
    case vertical_alignment
    """Vertical alignment."""

    # Padding.
    case padding_top
    """Padding level at the top of the text."""
    case padding_right
    """Padding level to the right of the text."""
    case padding_bottom
    """Padding level at the bottom of the text."""
    case padding_left
    """Padding level to the left of the text."""

    case color_whitespace
    """Color of whitespace background."""

    # Margins.
    case margin_top
    """Margin level at the top of the text."""
    case margin_right
    """Margin level to the right of the text."""
    case margin_bottom
    """Margin level at the bottom of the text."""
    case margin_left
    """Margin level to the left of the text."""
    case margin_background
    """Margin background color."""

    # Border style.
    case border_style
    """Border style."""

    # Border edges.
    case border_top
    """Border top."""
    case border_right
    """Border right."""
    case border_bottom
    """Border bottom."""
    case border_left
    """Border left."""

    # Border foreground colors.
    case border_top_foreground
    """Border top foreground color."""
    case border_right_foreground
    """Border right foreground color."""
    case border_bottom_foreground
    """Border bottom foreground color."""
    case border_left_foreground
    """Border left foreground color."""

    # Border background colors.
    case border_top_background
    """Border top background color."""
    case border_right_background
    """Border right background color."""
    case border_bottom_background
    """Border bottom background color."""
    case border_left_background
    """Border left background color."""
    case inline
    """Inline rendering."""
    case max_width
    """Maximum width of the text."""
    case max_height
    """Maximum height of the text."""
    case tab_width
    """Tab width."""
    case underline_spaces
    """Underline spaces between words."""
    case strikethrough_spaces
    """Crossout spaces between words."""

    def _index(self) -> Int:
        """Returns the bit this key occupies in a `Properties` set.

        Returns:
            The index of the key.
        """
        match self:
            case .bold:
                return 1
            case .italic:
                return 2
            case .underline:
                return 3
            case .strikethrough:
                return 4
            case .reverse:
                return 5
            case .blink:
                return 6
            case .faint:
                return 7
            case .foreground:
                return 8
            case .background:
                return 9
            case .width:
                return 10
            case .height:
                return 11
            case .horizontal_alignment:
                return 12
            case .vertical_alignment:
                return 13
            case .padding_top:
                return 14
            case .padding_right:
                return 15
            case .padding_bottom:
                return 16
            case .padding_left:
                return 17
            case .color_whitespace:
                return 18
            case .margin_top:
                return 19
            case .margin_right:
                return 20
            case .margin_bottom:
                return 21
            case .margin_left:
                return 22
            case .margin_background:
                return 23
            case .border_style:
                return 24
            case .border_top:
                return 25
            case .border_right:
                return 26
            case .border_bottom:
                return 27
            case .border_left:
                return 28
            case .border_top_foreground:
                return 29
            case .border_right_foreground:
                return 30
            case .border_bottom_foreground:
                return 31
            case .border_left_foreground:
                return 32
            case .border_top_background:
                return 33
            case .border_right_background:
                return 34
            case .border_bottom_background:
                return 35
            case .border_left_background:
                return 36
            case .inline:
                return 37
            case .max_width:
                return 38
            case .max_height:
                return 39
            case .tab_width:
                return 40
            case .underline_spaces:
                return 41
            case .strikethrough_spaces:
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

    var top: UInt
    """The padding level at the top of the text."""
    var right: UInt
    """The padding level to the right of the text."""
    var bottom: UInt
    """The padding level at the bottom of the text."""
    var left: UInt
    """The padding level to the left of the text."""

    def __init__(out self, *, top: UInt = 0, right: UInt = 0, bottom: UInt = 0, left: UInt = 0):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left

    def __init__(out self, width: UInt):
        self.top = width
        self.right = width
        self.bottom = width
        self.left = width

    def __init__(out self, x: UInt, y: UInt):
        self.top = y
        self.right = x
        self.bottom = y
        self.left = x


struct Margin(Equatable, Writable, ImplicitlyCopyable):
    """Margin of the text area."""

    var top: UInt
    """The margin level at the top of the text."""
    var right: UInt
    """The margin level to the right of the text."""
    var bottom: UInt
    """The margin level at the bottom of the text."""
    var left: UInt
    """The margin level to the left of the text."""
    var background: TerminalColor
    """The background color of the margin."""

    def __init__(
        out self,
        top: UInt = 0,
        right: UInt = 0,
        bottom: UInt = 0,
        left: UInt = 0,
        var background: TerminalColor = NoColor(),
    ):
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
        self.background = background^

    def __init__(out self, width: UInt, var background: TerminalColor = NoColor()):
        self.top = width
        self.right = width
        self.bottom = width
        self.left = width
        self.background = background^

    def __init__(out self, x: UInt, y: UInt, var background: TerminalColor = NoColor()):
        self.top = y
        self.right = x
        self.bottom = y
        self.left = x
        self.background = background^


struct Dimensions(Equatable, Writable, TrivialRegisterPassable):
    """Dimensions of the text area."""

    var height: UInt
    """The height of the text."""
    var width: UInt
    """The width of the text."""

    def __init__(out self, height: UInt = 0, width: UInt = 0):
        self.height = height
        self.width = width


struct Coloring(Equatable, Writable, ImplicitlyCopyable):
    """Coloring properties for the text."""

    var foreground: TerminalColor
    """The foreground color."""
    var background: TerminalColor
    """The background color."""

    def __init__(out self, foreground: TerminalColor = NoColor(), background: TerminalColor = NoColor()):
        self.foreground = foreground
        self.background = background


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


__enum Side(ImplicitlyCopyable, Writable):
    """A side of the text area."""

    case top
    """Indicates the top side of the text area."""
    case right
    """Indicates the right side of the text area."""
    case bottom
    """Indicates the bottom side of the text area."""
    case left
    """Indicates the left side of the text area."""


__enum Emphasis(ImplicitlyCopyable, Writable):
    """Emphasis properties for the text."""

    case bold
    """Whether the text is bold."""
    case italic
    """Whether the text is italic."""
    case underline
    """Whether the text is underlined."""
    case strikethrough
    """Whether the text is strikethrough."""
    case reverse
    """Whether the text is reversed."""
    case blink
    """Whether the text is blinking."""
    case faint
    """Whether the text is faint."""
    case underline_spaces
    """Whether spaces between words are underlined."""
    case strikethrough_spaces
    """Whether spaces between words are strikethrough."""
    case color_whitespace
    """Whether whitespace background is colored."""


__enum Axis(ImplicitlyCopyable, Writable):
    """Axis for alignment and placement."""

    case horizontal
    """Whether the axis is horizontal."""
    case vertical
    """Whether the axis is vertical."""
