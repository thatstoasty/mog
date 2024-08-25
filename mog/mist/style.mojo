from .gojo.strings import StringBuilder
from .color import (
    Color,
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_rgb,
    hex_to_ansi256,
    ansi256_to_ansi,
)
from .profile import get_color_profile, ASCII

# Text formatting sequences
alias reset = "0"
alias bold = "1"
alias faint = "2"
alias italic = "3"
alias underline = "4"
alias blink = "5"
alias reverse = "7"
alias crossout = "9"
alias overline = "53"

# ANSI Operations
alias escape = chr(27)  # Escape character
alias bel = "\a"  # Bell
alias csi = escape + "["  # Control Sequence Introducer
alias osc = escape + "]"  # Operating System Command
alias st = escape + chr(92)  # String Terminator

# clear terminal and return cursor to top left
alias clear = escape + "[2J" + escape + "[H"


@value
struct Style:
    """Style stores a list of styles to format text with. These styles are ANSI sequences which modify text (and control the terminal).
    In reality, these styles are turning visual terminal features on and off around the text it's styling.

    This struct should be considered immutable and each style added returns a new instance of itself rather than modifying the struct in place.
    Example:
    ```mojo
    import mist

    var style = mist.Style().foreground(0xE88388)
    print(style.render("Hello World"))
    ```
    """

    var styles: List[String]
    var profile: Profile

    fn __init__(inout self, profile: Profile, *, styles: List[String] = List[String]()):
        """Constructs a Style.

        Args:
            profile: The color profile to use for color conversion.
            styles: A list of ANSI styles to apply to the text.
        """
        self.styles = styles
        self.profile = profile

    fn __init__(inout self, *, styles: List[String] = List[String]()):
        """Constructs a Style.

        Args:
            styles: A list of ANSI styles to apply to the text.
        """
        self.styles = styles
        self.profile = Profile()

    fn __init__(inout self, other: Style):
        """Constructs a Style from another Style.

        Args:
            other: The Style to copy.
        """
        self.styles = other.styles
        self.profile = other.profile

    fn _add_style(self, style: String) -> Self:
        """Creates a deepcopy of Self, adds a style to it's list of styles, and returns that. Immutability instead of mutating the object.

        Args:
            style: The ANSI style to add to the list of styles.
        """
        var new = self
        new.styles.append(style)
        return new

    fn get_styles(self) -> List[String]:
        """Return a deepcopy of the styles list."""
        return List[String](self.styles)

    fn bold(self) -> Self:
        """Makes the text bold when rendered."""
        return self._add_style(bold)

    fn faint(self) -> Self:
        """Makes the text faint when rendered."""
        return self._add_style(faint)

    fn italic(self) -> Self:
        """Makes the text italic when rendered."""
        return self._add_style(italic)

    fn underline(self) -> Self:
        """Makes the text underlined when rendered."""
        return self._add_style(underline)

    fn blink(self) -> Self:
        """Makes the text blink when rendered."""
        return self._add_style(blink)

    fn reverse(self) -> Self:
        """Makes the text have reversed background and foreground colors when rendered."""
        return self._add_style(reverse)

    fn crossout(self) -> Self:
        """Makes the text crossed out when rendered."""
        return self._add_style(crossout)

    fn overline(self) -> Self:
        """Makes the text overlined when rendered."""
        return self._add_style(overline)

    fn background(self, *, color: AnyColor) -> Self:
        """Set the background color of the text when it's rendered.

        Args:
            color: The color value to set the background to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the background color set.
        """
        if color.isa[NoColor]():
            return Self(self.profile, styles=self.styles)

        var sequence: String = ""
        if color.isa[ANSIColor]():
            var c = color[ANSIColor]
            sequence = c.sequence(True)
        elif color.isa[ANSI256Color]():
            var c = color[ANSI256Color]
            sequence = c.sequence(True)
        elif color.isa[RGBColor]():
            var c = color[RGBColor]
            sequence = c.sequence(True)
        return self._add_style(sequence)

    fn background(self, color_value: UInt32) -> Self:
        """Shorthand for using the style profile to set the background color of the text.

        Args:
            color_value: The color value to set the background to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the background color set.
        """
        return self.background(color=self.profile.color(color_value))

    fn foreground(self, *, color: AnyColor) -> Self:
        """Set the foreground color of the text.

        Args:
            color: The color value to set the foreground to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the foreground color set.
        """
        if color.isa[NoColor]():
            return Self(self.profile, styles=self.styles)

        var sequence: String = ""
        if color.isa[ANSIColor]():
            sequence = color[ANSIColor].sequence(False)
        elif color.isa[ANSI256Color]():
            sequence = color[ANSI256Color].sequence(False)
        elif color.isa[RGBColor]():
            sequence = color[RGBColor].sequence(False)
        return self._add_style(sequence)

    fn foreground(self, color_value: UInt32) -> Self:
        """Shorthand for using the style profile to set the foreground color of the text.

        Args:
            color_value: The color value to set the foreground to. This can be a hex value, an ANSI color, or an RGB color.

        Returns:
            A new Style with the foreground color set.
        """
        return self.foreground(color=self.profile.color(color_value))

    fn render(self, text: String) -> String:
        """Renders text with the styles applied to it.

        Args:
            text: The text to render with the styles applied.

        Returns:
            The text with the styles applied.
        """
        if self.profile.value == ASCII:
            return text

        if len(self.styles) == 0:
            return text

        var builder = StringBuilder()
        _ = builder.write_string(csi)
        for i in range(len(self.styles)):
            _ = builder.write_string(";")
            _ = builder.write_string(self.styles[i])
        _ = builder.write_string("m")
        _ = builder.write_string(text)
        _ = builder.write_string(csi)
        _ = builder.write_string(reset)
        _ = builder.write_string("m")

        return str(builder)
