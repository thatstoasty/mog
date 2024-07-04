import os
import external.hue
from .color import (
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_ansi256,
    ansi256_to_ansi,
    hex_to_rgb,
    ansi_to_rgb,
    int_to_str,
)

alias TRUE_COLOR: Int = 0
alias ANSI256: Int = 1
alias ANSI: Int = 2
alias ASCII: Int = 3

alias TRUE_COLOR_PROFILE = Profile(TRUE_COLOR)
alias ANSI256_PROFILE = Profile(ANSI256)
alias ANSI_PROFILE = Profile(ANSI)
alias ASCII_PROFILE = Profile(ASCII)


# TODO: UNIX systems only for now. Need to add Windows, POSIX, and SOLARIS support.
fn get_color_profile() -> Int:
    """Queries the terminal to determine the color profile it supports.
    ASCII, ANSI, ANSI256, or TRUE_COLOR.
    """
    # if not o.isTTY():
    # 	return Ascii
    if os.getenv("GOOGLE_CLOUD_SHELL", "false") == "true":
        return TRUE_COLOR

    var term = os.getenv("TERM").lower()
    var color_term = os.getenv("COLORTERM").lower()

    # COLORTERM is used by some terminals to indicate TRUE_COLOR support.
    if color_term == "24bit":
        pass
    elif color_term == "truecolor":
        if term.startswith("screen"):
            # tmux supports TRUE_COLOR, screen only ANSI256
            if os.getenv("TERM_PROGRAM") != "tmux":
                return ANSI256
        return TRUE_COLOR
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return ANSI256

    # TERM is used by most terminals to indicate color support.
    if term == "xterm-kitty" or term == "wezterm" or term == "xterm-ghostty":
        return TRUE_COLOR
    elif term == "linux":
        return ANSI

    if "256color" in term:
        return ANSI256

    if "color" in term:
        return ANSI

    if "ansi" in term:
        return ANSI

    return ASCII


@register_passable
struct Profile:
    alias valid = InlineArray[Int, 4](TRUE_COLOR, ANSI256, ANSI, ASCII)
    var value: Int

    fn __init__(inout self, value: Int):
        """
        Initialize a new profile with the given profile type.

        Args:
            value: The setting to use for this profile. Valid values: [TRUE_COLOR, ANSI256, ANSI, ASCII].
        """
        if value not in Self.valid:
            self.value = TRUE_COLOR
            return

        self.value = value

    fn __init__(inout self):
        """
        Initialize a new profile with the given profile type.
        """
        self.value = get_color_profile()

    fn __copyinit__(inout self, other: Profile):
        self.value = other.value

    fn convert(self, color: AnyColor) -> AnyColor:
        """Degrades a color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.
        """
        if self.value == ASCII:
            return NoColor()

        if color.isa[NoColor]():
            return color[NoColor]
        elif color.isa[ANSIColor]():
            return color[ANSIColor]
        elif color.isa[ANSI256Color]():
            if self.value == ANSI:
                return ansi256_to_ansi(color[ANSI256Color].value)

            return color[ANSI256Color]
        elif color.isa[RGBColor]():
            var h = hex_to_rgb(color[RGBColor].value)

            if self.value != TRUE_COLOR:
                var ansi256 = hex_to_ansi256(
                    hue.Color(h[0].cast[DType.float64](), h[1].cast[DType.float64](), h[2].cast[DType.float64]())
                )
                if self.value == ANSI:
                    return ansi256_to_ansi(ansi256.value)

                return ansi256

            return color[RGBColor]

        # If it somehow gets here, just return No Color until I can figure out how to just return whatever color was passed in.
        return color[NoColor]

    fn color(self, value: UInt32) -> AnyColor:
        """Color creates a Color from a string. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255). If an invalid input is passed in, NoColor() is returned which will not apply any coloring.

        Args:
            value: The string to convert to a color.
        """
        if self.value == ASCII:
            return NoColor()

        if value < 16:
            return self.convert(ANSIColor(value))
        elif value < 256:
            return self.convert(ANSI256Color(value))

        return self.convert(RGBColor(value))
