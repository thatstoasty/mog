"""A module for representing colors in the terminal."""
import mist
from mog.renderer import Renderer

@fieldwise_init
struct NoColor(Equatable, Writable, TrivialRegisterPassable):
    """Used to specify the absence of color styling. When this is active
    foreground colors will be rendered with the terminal's default text color,
    and background colors will not be drawn at all.

    ### Examples:
    ```mojo
    import mog

    def main():
        var style = mog.Style(background=mog.NoColor())
    ```
    """

    def color(self, renderer: Renderer) -> mist.Color:
        """Returns a `mist.Color.ascii`.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            A `mist.Color.ascii`.
        """
        return mist.Color.ascii


@fieldwise_init
struct Color(Equatable, Writable, TrivialRegisterPassable):
    """Specifies a color by hex or ANSI value. For example.

    ### Args:
    * value: The color value to use. This can be an ANSI color value or a hex color value.

    ### Examples:
    ```mojo
    import mog
    def main():
        var ansi_color = mog.Color(21)
        var hex_color = mog.Color(0x0000ff)
    ```
    """

    var value: UInt32
    """The color value to use. This can be an ANSI color value or a hex color value."""

    def color(self, renderer: Renderer) -> mist.Color:
        """Returns the color value based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The color value based on the terminal color profile.

        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.Color.ascii`.
        * 0 - 15: `mist.Color.ansi`
        * 16 - 255: `mist.Color.ansi256`
        * 256 - 0xffffff: `mist.Color.rgb`
        """
        return renderer.profile.color(self.value)


@fieldwise_init
struct ANSIColor(Equatable, Writable, TrivialRegisterPassable):
    """Color specified by an ANSI color value. It's merely syntactic
    sugar for the more general Color function. Invalid colors will render as
    black.

    ### Attributes:
    * value: The color value to use. This is an ANSI color value.

    ### Examples:
    ```mojo
    import mog

    def main():
        # These two statements are equivalent.
        var color_a = mog.ANSIColor(21)
        var color_b = mog.Color(21)
    ```
    """

    var value: UInt32
    """The color value to use. This is an ANSI color value."""

    def color(self, renderer: Renderer) -> mist.Color:
        """Returns the color value based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The color value based on the terminal color profile.

        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.Color.ascii`.
        * 0 - 15: `mist.Color.ansi`
        * 16 - 255: `mist.Color.ansi256`
        * 256 - 0xffffff: `mist.Color.rgb`
        """
        return Color(self.value).color(renderer)


@fieldwise_init
struct AdaptiveColor(Equatable, Writable, TrivialRegisterPassable):
    """Provides color options for light and dark backgrounds. The
    appropriate color will be returned at runtime based on the darkness of the
    terminal background color.

    ### Attributes:
    * light: The color to use when the terminal background is light.
    * dark: The color to use when the terminal background is dark.

    ### Examples:
    ```mojo
    import mog

    def main():
        var color = mog.AdaptiveColor(light=0x0000ff, dark=0x000099)
    ```
    """

    var light: UInt32
    """The color to use when the terminal background is light."""
    var dark: UInt32
    """The color to use when the terminal background is dark."""

    def color(self, renderer: Renderer) -> mist.Color:
        """Returns the appropriate color based on the terminal background color.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The appropriate color based on the terminal background color.

        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.Color.ascii`.
        * 0 - 15: `mist.Color.ansi`
        * 16 - 255: `mist.Color.ansi256`
        * 256 - 0xffffff: `mist.Color.rgb`
        """
        if renderer.has_dark_background():
            return Color(self.dark).color(renderer)

        return Color(self.light).color(renderer)


@fieldwise_init
struct CompleteColor(Equatable, Writable, TrivialRegisterPassable):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles. Automatic color degradation will not be performed.

    ### Attributes:
    * `true_color`: The color to use when the terminal supports true color.
    * `ansi256`: The color to use when the terminal supports 256 colors.
    * `ansi`: The color to use when the terminal supports 16 colors.

    ### Examples:
    ```mojo
    import mog

    def main():
        var color = mog.CompleteColor(true_color=0x0000ff, ansi256=21, ansi=4)
    ```
    """

    var true_color: UInt32
    """The color to use when the terminal supports true color."""
    var ansi256: UInt32
    """The color to use when the terminal supports 256 colors."""
    var ansi: UInt32
    """The color to use when the terminal supports 16 colors."""

    def color(self, renderer: Renderer) -> mist.Color:
        """Returns the appropriate color based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The appropriate color based on the terminal color profile.

        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.Color.ascii`.
        * 0 - 15: `mist.Color.ansi`
        * 16 - 255: `mist.Color.ansi256`
        * 256 - 0xffffff: `mist.Color.rgb`
        """
        match renderer.profile:
            case .true_color:
                return Color(self.true_color).color(renderer)
            case .ansi256:
                return Color(self.ansi256).color(renderer)
            case .ansi:
                return Color(self.ansi).color(renderer)
            case .ascii:
                return mist.Color.ascii


@fieldwise_init
struct CompleteAdaptiveColor(Equatable, Writable, TrivialRegisterPassable):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles, with separate options for light and dark backgrounds. Automatic
    color degradation will not be performed.

    ### Attributes:
    * light: The `CompleteColor` to use when the terminal background is light.
    * dark: The `CompleteColor` to use when the terminal background is dark.

    ### Examples:
    ```mojo
    import mog

    def main():
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

    def color(self, renderer: Renderer) -> mist.Color:
        """Returns the appropriate color based on the terminal background color.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The appropriate color based on the terminal background color.

        The type of color returned depends on the value of the integer. Unless it's an ASCII renderer, otherwise it's always `mist.Color.ascii`.
        * 0 - 15: `mist.Color.ansi`
        * 16 - 255: `mist.Color.ansi256`
        * 256 - 0xffffff: `mist.Color.rgb`
        """
        if renderer.has_dark_background():
            return self.dark.color(renderer)

        return self.light.color(renderer)


__enum TerminalColor(ImplicitlyCopyable, Writable):
    """A type that can hold any terminal color.

    Each `mog.TerminalColor` implementation has a case of its own, and converts
    into one implicitly, so colors can be passed to a `Style` directly.

    ### Examples:
    ```mojo
    import mog

    def main():
        var style = mog.Style(foreground=mog.Color(12), background=mog.NoColor())
    ```
    """

    case no_color(NoColor)
    """The absence of color styling, from a `NoColor`."""
    case basic(Color)
    """A `Color`, specified by an ANSI or hex value."""
    case ansi(ANSIColor)
    """An `ANSIColor`."""
    case adaptive(AdaptiveColor)
    """An `AdaptiveColor`, resolved against the terminal's background."""
    case complete(CompleteColor)
    """A `CompleteColor`, with an exact value per color profile."""
    case complete_adaptive(CompleteAdaptiveColor)
    """A `CompleteAdaptiveColor`, with an exact value per profile and background."""

    @implicit
    def __init__(out self, color: NoColor):
        """Initializes the `TerminalColor` with a `NoColor`.

        Args:
            color: The `NoColor` to initialize with.
        """
        self = Self.no_color(color)

    @implicit
    def __init__(out self, color: Color):
        """Initializes the `TerminalColor` with a `Color`.

        Args:
            color: The `Color` to initialize with.
        """
        self = Self.basic(color)

    @implicit
    def __init__(out self, color: ANSIColor):
        """Initializes the `TerminalColor` with an `ANSIColor`.

        Args:
            color: The `ANSIColor` to initialize with.
        """
        self = Self.ansi(color)

    @implicit
    def __init__(out self, color: AdaptiveColor):
        """Initializes the `TerminalColor` with an `AdaptiveColor`.

        Args:
            color: The `AdaptiveColor` to initialize with.
        """
        self = Self.adaptive(color)

    @implicit
    def __init__(out self, color: CompleteColor):
        """Initializes the `TerminalColor` with a `CompleteColor`.

        Args:
            color: The `CompleteColor` to initialize with.
        """
        self = Self.complete(color)

    @implicit
    def __init__(out self, color: CompleteAdaptiveColor):
        """Initializes the `TerminalColor` with a `CompleteAdaptiveColor`.

        Args:
            color: The `CompleteAdaptiveColor` to initialize with.
        """
        self = Self.complete_adaptive(color)

    def color(self, renderer: Renderer) -> mist.Color:
        """Converts an `TerminalColor` to a `mist.Color`.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The converted color.

        Notes:
            Useful for converting a `mog.TerminalColor` to a `mist.Color` for use in a `mist.Style`.
        """
        match self:
            case .no_color(value):
                return value.color(renderer)
            case .basic(value):
                return value.color(renderer)
            case .ansi(value):
                return value.color(renderer)
            case .adaptive(value):
                return value.color(renderer)
            case .complete(value):
                return value.color(renderer)
            case .complete_adaptive(value):
                return value.color(renderer)

    def is_no_color(self) -> Bool:
        """Checks whether no color styling is set.

        Returns:
            True if the value is `no_color`, False otherwise.
        """
        match self:
            case .no_color:
                return True
            case _:
                return False

    def write_to(self, mut writer: Some[Writer]):
        """Writes the underlying color to the given writer.

        Args:
            writer: The writer to write to.
        """
        match self:
            case .no_color(value):
                writer.write(value)
            case .basic(value):
                writer.write(value)
            case .ansi(value):
                writer.write(value)
            case .adaptive(value):
                writer.write(value)
            case .complete(value):
                writer.write(value)
            case .complete_adaptive(value):
                writer.write(value)
