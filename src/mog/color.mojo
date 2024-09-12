from utils.variant import Variant
from .renderer import Renderer
import mist


trait TerminalColor(CollectionElement):
    """TerminalColor is a color intended to be rendered in the terminal."""

    fn color(self, renderer: Renderer) -> mist.AnyColor:
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

    Example usage:
    ```mojo
    var style = mog.Style().background(mog.NoColor())
    ```
    .
    """

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        return mist.NoColor()


@value
struct Color(TerminalColor):
    """Specifies a color by hex or ANSI value. For example.

    Args:
        value: The color value to use. This can be an ANSI color value or a hex color value.

    Example usage:
    ```mojo
    var ansi_color = mog.Color(21)
    var hex_color = mog.Color(0x0000ff)
    ```
    """

    var value: UInt32

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        return renderer.color_profile.color(self.value)


@value
struct ANSIColor(TerminalColor):
    """ANSIColor is a color specified by an ANSI color value. It's merely syntactic
    sugar for the more general Color function. Invalid colors will render as
    black.

    Args:
        value: The color value to use. This is an ANSI color value.

    Example usage:

    ```mojo
    # These two statements are equivalent.
    var color_a = mog.ANSIColor(21)
    var color_b = mog.Color(21)
    ```
    """

    var value: UInt32

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        return Color(self.value).color(renderer)


@value
struct AdaptiveColor(TerminalColor):
    """AdaptiveColor provides color options for light and dark backgrounds. The
    appropriate color will be returned at runtime based on the darkness of the
    terminal background color.

    Args:
        light: The color to use when the terminal background is light.
        dark: The color to use when the terminal background is dark.

    Example usage:
    ```mojo
    var color = mog.AdaptiveColor(light=0x0000ff, dark=0x000099)
    ```
    """

    var light: UInt32
    var dark: UInt32

    fn color(self, renderer: Renderer) -> mist.AnyColor:
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

    Example usage:
    ```mojo
    var color = mog.CompleteColor(true_color=0x0000ff, ansi256=21, ansi=4)
    ```
    .
    """

    var true_color: UInt32
    var ansi256: UInt32
    var ansi: UInt32

    fn color(self, renderer: Renderer) -> mist.AnyColor:
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
        light: The CompleteColor to use when the terminal background is light.
        dark: The CompleteColor to use when the terminal background is dark.

    Example usage:
    ```mojo
    var color = mog.CompleteAdaptiveColor(
        light=mog.CompleteColor(true_color=0x0000ff, ansi256=21, ansi=4),
        dark=mog.CompleteColor(true_color=0x000099, ansi256=22, ansi=5),
    )
    ```
    .
    """

    var light: CompleteColor
    var dark: CompleteColor

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        if renderer.has_dark_background():
            return self.dark.color(renderer)

        return self.light.color(renderer)
