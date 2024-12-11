from utils.variant import Variant
from .renderer import Renderer
import mist


trait TerminalColor(CollectionElement):
    """Color intended to be rendered in the terminal."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns the color value based on the terminal color profile.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            The color value based on the terminal color profile.
        """
        ...


alias AnyTerminalColor = Variant[
    NoColor,
    Color,
    ANSIColor,
    AdaptiveColor,
    CompleteColor,
    CompleteAdaptiveColor,
]


@value
struct NoColor(TerminalColor):
    """Used to specify the absence of color styling. When this is active
    foreground colors will be rendered with the terminal's default text color,
    and background colors will not be drawn at all.

    Examples:
    ```mojo
    var style = mog.Style().background(mog.NoColor())
    ```
    """

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        """Returns a `NoColor` object.

        Args:
            renderer: The renderer to use for color selection.

        Returns:
            A `NoColor` object.
        """
        return mist.NoColor()


@value
struct Color(TerminalColor):
    """Specifies a color by hex or ANSI value. For example.

    Args:
        value: The color value to use. This can be an ANSI color value or a hex color value.

    Examples:
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
        """
        return renderer.color_profile.color(self.value)


@value
struct ANSIColor(TerminalColor):
    """ANSIColor is a color specified by an ANSI color value. It's merely syntactic
    sugar for the more general Color function. Invalid colors will render as
    black.

    Args:
        value: The color value to use. This is an ANSI color value.

    Examples:
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
        """
        return Color(self.value).color(renderer)


@value
struct AdaptiveColor(TerminalColor):
    """AdaptiveColor provides color options for light and dark backgrounds. The
    appropriate color will be returned at runtime based on the darkness of the
    terminal background color.

    Args:
        light: The color to use when the terminal background is light.
        dark: The color to use when the terminal background is dark.

    Examples:
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
        """
        if renderer.has_dark_background():
            return Color(self.dark).color(renderer)

        return Color(self.light).color(renderer)


@value
struct CompleteColor(TerminalColor):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles. Automatic color degradation will not be performed.

    Args:
        true_color: The color to use when the terminal supports true color.
        ansi256: The color to use when the terminal supports 256 colors.
        ansi: The color to use when the terminal supports 16 colors.

    Examples:
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
        """
        var p = renderer.color_profile
        if p.value == mist.TRUE_COLOR:
            return Color(self.true_color).color(renderer)
        elif p.value == mist.ANSI256:
            return Color(self.ansi256).color(renderer)
        elif p.value == mist.ANSI:
            return Color(self.ansi).color(renderer)
        else:
            return mist.NoColor()


@value
struct CompleteAdaptiveColor(TerminalColor):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles, with separate options for light and dark backgrounds. Automatic
    color degradation will not be performed.

    Args:
        light: The `CompleteColor` to use when the terminal background is light.
        dark: The `CompleteColor` to use when the terminal background is dark.

    Examples:
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
        """
        if renderer.has_dark_background():
            return self.dark.color(renderer)

        return self.light.color(renderer)


fn any_terminal_color_to_any_color(terminal_color: AnyTerminalColor, renderer: Renderer) -> mist.AnyColor:
    """Converts an `AnyTerminalColor` to an `AnyColor`.

    Args:
        terminal_color: The terminal color to convert.
        renderer: The renderer to use for color selection.
    
    Returns:
        The converted color.

    Notes:
        Useful for converting a `mog.TerminalColor` to a `mist.Color` for use in a `mist.Style`.
    """
    if terminal_color.isa[Color]():
        return terminal_color[Color].color(renderer)
    elif terminal_color.isa[ANSIColor]():
        return terminal_color[ANSIColor].color(renderer)
    elif terminal_color.isa[AdaptiveColor]():
        return terminal_color[AdaptiveColor].color(renderer)
    elif terminal_color.isa[CompleteColor]():
        return terminal_color[CompleteColor].color(renderer)
    elif terminal_color.isa[CompleteAdaptiveColor]():
        return terminal_color[CompleteAdaptiveColor].color(renderer)

    return mist.NoColor()
