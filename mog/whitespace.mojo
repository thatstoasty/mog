from bit import countl_zero
import external.mist
import external.weave.ansi
from external.gojo.strings import StringBuilder
from external.gojo.unicode import UnicodeString
from .renderer import Renderer
from .color import (
    TerminalColor,
    NoColor,
    Color,
    AdaptiveColor,
    ANSIColor,
    CompleteColor,
    CompleteAdaptiveColor,
)
from .position import Position


@value
struct WhiteSpace:
    """Whitespace renderer.

    Args:
        renderer: The renderer to use.
        style: The style to use.
        chars: The characters to render.
    """

    var renderer: Renderer
    var style: mist.Style
    var chars: String

    fn __init__(
        inout self,
        renderer: Renderer,
        style: mist.Style,
        chars: String = "",
    ):
        """Initializes a new whitespace renderer.

        Args:
            renderer: The renderer to use.
            style: The style to use.
            chars: The characters to render.
        """
        self.renderer = renderer
        self.style = style
        self.chars = chars

    fn render(inout self, width: Int) -> String:
        """Render whitespaces.

        Args:
            width: The width of the whitespace.

        Returns:
            The rendered whitespace.
        """
        if self.chars == "":
            self.chars = " "

        var j = 0
        var b = StringBuilder()

        # Cycle through runes and print them into the whitespace.
        var i = 0

        while i < width:
            var uni_str = UnicodeString(self.chars)

            for char in uni_str:
                _ = b.write_string(char)
                var printable_width = ansi.printable_rune_width(char)
                if j >= printable_width:
                    j = 0

                # If we hit the width of the block, break the loop back up to the top while, which will end.
                i += printable_width
                if i >= width:
                    break

        #  Fill any extra gaps white spaces. This might be necessary if any runes
        #  are more than one cell wide, which could leave a one-rune gap.
        var short = width - ansi.printable_rune_width(str(b))
        if short > 0:
            _ = b.write_string(WHITESPACE * short)

        return self.style.render(str(b))


#  WhitespaceOption sets a styling rule for rendering whitespace.
alias WhitespaceOption = fn (inout w: WhiteSpace) -> None


fn new_whitespace(renderer: Renderer, *opts: WhitespaceOption) -> WhiteSpace:
    """Creates a new whitespace renderer. The order of the options
    matters, if you're using WithWhitespaceRenderer, make sure it comes first as
    other options might depend on it."""
    var w = WhiteSpace(renderer=renderer, style=mist.new_style(renderer.color_profile))

    for opt in opts:
        opt(w)

    return w


# TODO: Temporary until until args unpacking is supported.
fn new_whitespace(renderer: Renderer, opts: List[WhitespaceOption]) -> WhiteSpace:
    """Creates a new whitespace renderer. The order of the options
    matters, if you're using WithWhitespaceRenderer, make sure it comes first as
    other options might depend on it."""
    var w = WhiteSpace(renderer=renderer, style=mist.new_style(renderer.color_profile))

    for opt in opts:
        opt[](w)

    return w


# Limited to using param for now due to Mojo crashing when using capturing functions.
fn with_whitespace_foreground[terminal_color: AnyTerminalColor]() -> WhitespaceOption:
    """Sets the color of the characters in the whitespace."""

    fn style_foreground(inout w: WhiteSpace) -> None:
        var color: mist.AnyColor = mist.NoColor()
        if terminal_color.isa[NoColor]():
            return None

        if terminal_color.isa[Color]():
            color = terminal_color[Color].color(w.renderer)
        elif terminal_color.isa[ANSIColor]():
            color = terminal_color[ANSIColor].color(w.renderer)
        elif terminal_color.isa[AdaptiveColor]():
            color = terminal_color[AdaptiveColor].color(w.renderer)
        elif terminal_color.isa[CompleteColor]():
            color = terminal_color[CompleteColor].color(w.renderer)
        elif terminal_color.isa[CompleteAdaptiveColor]():
            color = terminal_color[CompleteAdaptiveColor].color(w.renderer)

        w.style = w.style.foreground(color)

    return style_foreground


fn with_whitespace_background[terminal_color: AnyTerminalColor]() -> WhitespaceOption:
    """Sets the background color of the whitespace."""

    fn style_background(inout w: WhiteSpace) -> None:
        var color: mist.AnyColor = mist.NoColor()
        if terminal_color.isa[NoColor]():
            return None

        if terminal_color.isa[Color]():
            color = terminal_color[Color].color(w.renderer)
        elif terminal_color.isa[ANSIColor]():
            color = terminal_color[ANSIColor].color(w.renderer)
        elif terminal_color.isa[AdaptiveColor]():
            color = terminal_color[AdaptiveColor].color(w.renderer)
        elif terminal_color.isa[CompleteColor]():
            color = terminal_color[CompleteColor].color(w.renderer)
        elif terminal_color.isa[CompleteAdaptiveColor]():
            color = terminal_color[CompleteAdaptiveColor].color(w.renderer)

        w.style = w.style.background(color)

    return style_background


fn with_whitespace_chars[s: String]() -> WhitespaceOption:
    """Sets the characters to be rendered in the whitespace."""

    fn whitespace_with_chars(inout w: WhiteSpace) -> None:
        w.chars = s

    return whitespace_with_chars


# Causes a compiler error at os.getenv()
# alias DEFAULT_RENDERER = Renderer()


fn place(
    width: Int,
    height: Int,
    hPos: Position,
    vPos: Position,
    text: String,
    /,
    *opts: WhitespaceOption,
) -> String:
    """Places a string or text block vertically in an unstyled box of a given
    width or height.

    Args:
        width: The width of the box.
        height: The height of the box.
        hPos: The horizontal position of the text.
        vPos: The vertical position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    var options = List[WhitespaceOption]()
    for opt in opts:
        options.append(opt)
    return Renderer().place(width, height, hPos, vPos, text, options)


# TODO: Temp until arg unpacking
fn place(
    width: Int,
    height: Int,
    hPos: Position,
    vPos: Position,
    text: String,
    opts: List[WhitespaceOption],
) raises -> String:
    """Places a string or text block vertically in an unstyled box of a given
    width or height.

    Args:
        width: The width of the box.
        height: The height of the box.
        hPos: The horizontal position of the text.
        vPos: The vertical position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    return Renderer().place(width, height, hPos, vPos, text, opts)


fn place_horizontal(width: Int, pos: Position, text: String, *opts: WhitespaceOption) raises -> String:
    """Places a string or text block horizontally in an unstyled
    block of a given width. If the given width is shorter than the max width of
    the string (measured by its longest line) this will be a noop.

    Args:
        width: The width of the box.
        pos: The position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    var options = List[WhitespaceOption]()
    for opt in opts:
        options.append(opt)
    return Renderer().place_horizontal(width, pos, text, options)


# TODO: Temp until arg unpacking
fn place_horizontal(width: Int, pos: Position, text: String, opts: List[WhitespaceOption]) raises -> String:
    """Places a string or text block horizontally in an unstyled
    block of a given width. If the given width is shorter than the max width of
    the string (measured by its longest line) this will be a noop.

    Args:
        width: The width of the box.
        pos: The position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    return Renderer().place_horizontal(width, pos, text, opts)


fn place_vertical(height: Int, pos: Position, text: String, *opts: WhitespaceOption) raises -> String:
    """Places a string or text block vertically in an unstyled block
    of a given height. If the given height is shorter than the height of the
    string (measured by its newlines) then this will be a noop.

    Args:
        height: The height of the box.
        pos: The position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    var options = List[WhitespaceOption]()
    for opt in opts:
        options.append(opt)
    return Renderer().place_vertical(height, pos, text, options)


# TODO: Temp until arg unpacking
fn place_vertical(height: Int, pos: Position, text: String, opts: List[WhitespaceOption]) raises -> String:
    """Places a string or text block vertically in an unstyled block
    of a given height. If the given height is shorter than the height of the
    string (measured by its newlines) then this will be a noop.

    Args:
        height: The height of the box.
        pos: The position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    return Renderer().place_vertical(height, pos, text, opts)
