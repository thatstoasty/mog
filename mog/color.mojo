from utils.variant import Variant
import mist
from mog.renderer import Renderer


trait TerminalColor(Movable, Copyable, ExplicitlyCopyable):
    """Color intended to be rendered in the terminal."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the color value based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The color value based on the terminal color profile.
        
        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.NoColor`.
        * 0 - 15: `mist.ANSIColor`
        * 16 - 255: `mist.ANSI256Color`
        * 256 - 0xffffff: `mist.RGBColor`
        """
        ...


@fieldwise_init
@register_passable("trivial")
struct NoColor(TerminalColor):
    """Used to specify the absence of color styling. When this is active
    foreground colors will be rendered with the terminal's default text color,
    and background colors will not be drawn at all.

    ### Examples:
    ```mojo
    var style = mog.Style().background(mog.NoColor())
    ```
    """

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns a `mist.NoColor`.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            A `mist.NoColor`.
        """
        return mist.NoColor()


@fieldwise_init
@register_passable("trivial")
struct Color(TerminalColor):
    """Specifies a color by hex or ANSI value. For example.

    ### Args:
    * value: The color value to use. This can be an ANSI color value or a hex color value.

    ### Examples:
    ```mojo
    var ansi_color = mog.Color(21)
    var hex_color = mog.Color(0x0000ff)
    ```
    """

    var value: UInt32
    """The color value to use. This can be an ANSI color value or a hex color value."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the color value based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The color value based on the terminal color profile.
        
        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.NoColor`.
        * 0 - 15: `mist.ANSIColor`
        * 16 - 255: `mist.ANSI256Color`
        * 256 - 0xffffff: `mist.RGBColor`
        """
        return renderer.profile.color(self.value)


@fieldwise_init
@register_passable("trivial")
struct ANSIColor(TerminalColor):
    """Color specified by an ANSI color value. It's merely syntactic
    sugar for the more general Color function. Invalid colors will render as
    black.

    ### Attributes:
    * value: The color value to use. This is an ANSI color value.

    ### Examples:
    ```mojo
    # These two statements are equivalent.
    var color_a = mog.ANSIColor(21)
    var color_b = mog.Color(21)
    ```
    """

    var value: UInt32
    """The color value to use. This is an ANSI color value."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the color value based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The color value based on the terminal color profile.
        
        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.NoColor`.
        * 0 - 15: `mist.ANSIColor`
        * 16 - 255: `mist.ANSI256Color`
        * 256 - 0xffffff: `mist.RGBColor`
        """
        return Color(self.value).color(renderer)


@fieldwise_init
@register_passable("trivial")
struct AdaptiveColor(TerminalColor):
    """Provides color options for light and dark backgrounds. The
    appropriate color will be returned at runtime based on the darkness of the
    terminal background color.
    
    ### Attributes:
    * light: The color to use when the terminal background is light.
    * dark: The color to use when the terminal background is dark.

    ### Examples:
    ```mojo
    var color = mog.AdaptiveColor(light=0x0000ff, dark=0x000099)
    ```
    """

    var light: UInt32
    """The color to use when the terminal background is light."""
    var dark: UInt32
    """The color to use when the terminal background is dark."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the appropriate color based on the terminal background color.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The appropriate color based on the terminal background color.
        
        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.NoColor`.
        * 0 - 15: `mist.ANSIColor`
        * 16 - 255: `mist.ANSI256Color`
        * 256 - 0xffffff: `mist.RGBColor`
        """
        if renderer.has_dark_background():
            return Color(self.dark).color(renderer)

        return Color(self.light).color(renderer)


@fieldwise_init
@register_passable("trivial")
struct CompleteColor(TerminalColor):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles. Automatic color degradation will not be performed.

    ### Attributes:
    * `true_color`: The color to use when the terminal supports true color.
    * `ansi256`: The color to use when the terminal supports 256 colors.
    * `ansi`: The color to use when the terminal supports 16 colors.

    ### Examples:
    ```mojo
    var color = mog.CompleteColor(true_color=0x0000ff, ansi256=21, ansi=4)
    ```
    """

    var true_color: UInt32
    """The color to use when the terminal supports true color."""
    var ansi256: UInt32
    """The color to use when the terminal supports 256 colors."""
    var ansi: UInt32
    """The color to use when the terminal supports 16 colors."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the appropriate color based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The appropriate color based on the terminal color profile.
        
        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.NoColor`.
        * 0 - 15: `mist.ANSIColor`
        * 16 - 255: `mist.ANSI256Color`
        * 256 - 0xffffff: `mist.RGBColor`
        """
        if renderer.profile == mist.profile.Profile.TRUE_COLOR:
            return Color(self.true_color).color(renderer)
        elif renderer.profile == mist.profile.Profile.ANSI256:
            return Color(self.ansi256).color(renderer)
        elif renderer.profile == mist.profile.Profile.ANSI:
            return Color(self.ansi).color(renderer)
        else:
            return mist.NoColor()


@fieldwise_init
struct CompleteAdaptiveColor(TerminalColor):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles, with separate options for light and dark backgrounds. Automatic
    color degradation will not be performed.

    ### Attributes:
    * light: The `CompleteColor` to use when the terminal background is light.
    * dark: The `CompleteColor` to use when the terminal background is dark.

    ### Examples:
    ```mojo
    var color = mog.CompleteAdaptiveColor(
        light=mog.CompleteColor(true_color=0x0000ff, ansi256=21, ansi=4),
        dark=mog.CompleteColor(true_color=0x000099, ansi256=22, ansi=5),
    )
    ```
    """

    var light: CompleteColor
    """The `CompleteColor` to use when the terminal background is light."""
    var dark: CompleteColor
    """The `CompleteColor` to use when the terminal background is dark."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the appropriate color based on the terminal background color.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The appropriate color based on the terminal background color.
        
        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.NoColor`.
        * 0 - 15: `mist.ANSIColor`
        * 16 - 255: `mist.ANSI256Color`
        * 256 - 0xffffff: `mist.RGBColor`
        """
        if renderer.has_dark_background():
            return self.dark.color(renderer)

        return self.light.color(renderer)


struct AnyTerminalColor(Movable):
    """A type that can hold any terminal color."""
    var value: Variant[
        NoColor,
        Color,
        ANSIColor,
        AdaptiveColor,
        CompleteColor,
        CompleteAdaptiveColor,
    ]
    """Internal `Color` value."""

    @implicit
    fn __init__(out self, color: Variant[
            NoColor,
            Color,
            ANSIColor,
            AdaptiveColor,
            CompleteColor,
            CompleteAdaptiveColor,
        ]):
        """Initializes the `AnyTerminalColor` with a `Variant` of terminal colors.
        
        Args:
            color: The `Variant` of terminal colors to initialize with.
        """
        self.value = color

    @implicit
    fn __init__(out self, color: NoColor):
        """Initializes the `AnyTerminalColor` with a `NoColor`.

        Args:
            color: The `NoColor` to initialize with.
        """
        self.value = color
    
    @implicit
    fn __init__(out self, color: Color):
        """Initializes the `AnyTerminalColor` with a `Color`.

        Args:
            color: The `Color` to initialize with.
        """
        self.value = color
    
    @implicit
    fn __init__(out self, color: ANSIColor):
        """Initializes the `AnyTerminalColor` with an `ANSIColor`.

        Args:
            color: The `ANSIColor` to initialize with.
        """
        self.value = color
    
    @implicit
    fn __init__(out self, color: AdaptiveColor):
        """Initializes the `AnyTerminalColor` with an `AdaptiveColor`.

        Args:
            color: The `AdaptiveColor` to initialize with.
        """
        self.value = color
    
    @implicit
    fn __init__(out self, color: CompleteColor):
        """Initializes the `AnyTerminalColor` with a `CompleteColor`.

        Args:
            color: The `CompleteColor` to initialize with.
        """
        self.value = color
    
    @implicit
    fn __init__(out self, color: CompleteAdaptiveColor):
        """Initializes the `AnyTerminalColor` with a `CompleteAdaptiveColor`.

        Args:
            color: The `CompleteAdaptiveColor` to initialize with.
        """
        self.value = color
    
    fn __moveinit__(out self, owned other: Self):
        """Moves the `AnyTerminalColor` from another instance.

        Args:
            other: The `AnyTerminalColor` to move from.
        """
        self.value = other.value^
    
    fn copy(self) -> Self:
        """Creates a copy of the `AnyTerminalColor`.

        Returns:
            A new `AnyTerminalColor` with the same value.
        """
        return Self(self.value)

    fn to_mist_color(self, renderer: Renderer) -> mist.AnyColor:
        """Converts an `AnyTerminalColor` to an `AnyColor`.

        Args:
            renderer: The renderer to use for color selection.
        
        Returns:
            The converted color.

        Notes:
            Useful for converting a `mog.TerminalColor` to a `mist.Color` for use in a `mist.Style`.
        """
        if self.value.isa[Color]():
            return self.value[Color].color(renderer)
        elif self.value.isa[ANSIColor]():
            return self.value[ANSIColor].color(renderer)
        elif self.value.isa[AdaptiveColor]():
            return self.value[AdaptiveColor].color(renderer)
        elif self.value.isa[CompleteColor]():
            return self.value[CompleteColor].color(renderer)
        elif self.value.isa[CompleteAdaptiveColor]():
            return self.value[CompleteAdaptiveColor].color(renderer)

        return mist.NoColor()
    
    fn isa[T: TerminalColor](self) -> Bool:
        """Checks if the value is of the given type.

        Parameters:
            T: The type to check against.

        Returns:
            True if the value is of the given type, False otherwise.
        """
        return self.value.isa[T]()

    fn __getitem__[T: TerminalColor](ref self) -> ref [self.value] T:
        """Gets the value as the given type.

        Parameters:
            T: The type to get the value as.

        Returns:
            The value as the given type.
        """
        return self.value[T]