from utils.variant import Variant
from .renderer import Renderer
import external.mist


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

        var style = some_style.copy().background(NoColor())
    """

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        return mist.NoColor()


@value
struct Color(TerminalColor):
    """Specifies a color by hex or ANSI value. For example.

    ansiColor = lipgloss.Color("21")
    hexColor = lipgloss.Color("#0000ff").
    """

    var value: String

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        return renderer.color_profile.color(String(self.value))


@value
struct ANSIColor(TerminalColor):
    """ANSIColor is a color specified by an ANSI color value. It's merely syntactic
    sugar for the more general Color function. Invalid colors will render as
    black.

    Example usage:

        # These two statements are equivalent.
        colorA = lipgloss.ANSIColor(21)
        colorB = lipgloss.Color("21")"""

    var value: UInt64

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        return Color(self.value).color(renderer)


@value
struct AdaptiveColor(TerminalColor):
    """AdaptiveColor provides color options for light and dark backgrounds. The
    appropriate color will be returned at runtime based on the darkness of the
    terminal background color.

    Example usage:

        color = AdaptiveColor(Light="#0000ff", Dark="#000099")
    """

    var light: String
    var dark: String

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        if renderer.has_dark_background():
            return Color(self.dark).color(renderer)

        return Color(self.light).color(renderer)


@value
struct CompleteColor(TerminalColor):
    """Specifies exact values for truecolor, ANSI256, and ANSI color
    profiles. Automatic color degradation will not be performed."""

    var true_color: String
    var ansi256: String
    var ansi: String

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
    color degradation will not be performed."""

    var light: CompleteColor
    var dark: CompleteColor

    fn color(self, renderer: Renderer) -> mist.AnyColor:
        if renderer.has_dark_background():
            return self.dark.color(renderer)

        return self.light.color(renderer)
