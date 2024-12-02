import mist
import weave.ansi
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
struct WhitespaceRenderer:
    """Whitespace renderer.

    Args:
        renderer: The renderer to use.
        style: The style to use.
        chars: The characters to render.
    """

    var renderer: Renderer
    """The renderer which determines the color profile."""
    var style: mist.Style
    """Terminal styling for the whitespace."""
    var chars: String
    """The characters to render for whitespace. Defaults to a space."""

    fn __init__(
        inout self,
        renderer: Renderer,
        style: mist.Style,
        chars: String = " ",
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
        var j = 0
        var result = String()

        # Cycle through runes and print them into the whitespace.
        var i = 0

        while i < width:
            for char in self.chars:
                result.write_bytes(char.as_bytes())
                var printable_width = ansi.printable_rune_width(char)
                if j >= printable_width:
                    j = 0

                # If we hit the width of the block, break the loop back up to the top while, which will end.
                i += printable_width
                if i >= width:
                    break

        #  Fill any extra gaps white spaces. This might be necessary if any runes
        #  are more than one cell wide, which could leave a one-rune gap.
        var short = width - ansi.printable_rune_width(result)
        if short > 0:
            result.write(WHITESPACE * short)

        return self.style.render(result)


alias WhitespaceOption = fn (inout w: WhitespaceRenderer) -> None
"""Sets a styling rule for rendering whitespace."""


fn new_whitespace(renderer: Renderer, *opts: WhitespaceOption) -> WhitespaceRenderer:
    """Creates a new whitespace renderer. The order of the options matters.
    
    Args:
        renderer: The renderer to use.
        opts: The options to style the whitespace.
    
    Returns:
        A new whitespace renderer.
    """
    return _new_whitespace(renderer, opts)


fn _new_whitespace(renderer: Renderer, opts: VariadicList[WhitespaceOption]) -> WhitespaceRenderer:
    """Creates a new whitespace renderer. The order of the options matters.
    
    Args:
        renderer: The renderer to use.
        opts: The options to style the whitespace.
    
    Returns:
        A new whitespace renderer.
    """
    var w = WhitespaceRenderer(renderer=renderer, style=mist.Style(renderer.color_profile.value))
    for opt in opts:
        opt(w)

    return w


# Limited to using param for now due to Mojo crashing when using capturing functions.
fn with_whitespace_foreground[terminal_color: AnyTerminalColor]() -> WhitespaceOption:
    """Sets the color of the characters in the whitespace.
    
    Parameters:
        terminal_color: The color to use for the characters in the whitespace.
    
    Returns:
        A function that sets the color of the characters in the whitespace.
    """

    fn style_foreground(inout w: WhitespaceRenderer) -> None:
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

        w.style = w.style.foreground(color=color)

    return style_foreground


fn with_whitespace_background[terminal_color: AnyTerminalColor]() -> WhitespaceOption:
    """Sets the background color of the whitespace.
    
    Parameters:
        terminal_color: The color to use for the background of the whitespace.
    
    Returns:
        A function that sets the background color of the whitespace.
    """

    fn style_background(inout w: WhitespaceRenderer) -> None:
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

        w.style = w.style.background(color=color)

    return style_background


fn with_whitespace_chars[text: String]() -> WhitespaceOption:
    """Sets the characters to be rendered in the whitespace.
    
    Parameters:
        text: The characters to use for the whitespace rendering.
    
    Returns:
        A function that sets the characters to be rendered in the whitespace.
    """

    fn whitespace_with_chars(inout w: WhitespaceRenderer) -> None:
        w.chars = text

    return whitespace_with_chars


# Causes a compiler error at os.getenv()
# alias DEFAULT_RENDERER = Renderer()


fn place(
    width: Int,
    height: Int,
    horizontal_position: Position,
    vertical_position: Position,
    text: String,
    /,
    *opts: WhitespaceOption,
) -> String:
    """Places a string or text block vertically in an unstyled box of a given
    width or height.

    Args:
        width: The width of the box.
        height: The height of the box.
        horizontal_position: The horizontal position of the text.
        vertical_position: The vertical position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    return _place(width, height, horizontal_position, vertical_position, text, opts)


fn _place(
    width: Int,
    height: Int,
    horizontal_position: Position,
    vertical_position: Position,
    text: String,
    opts: VariadicList[WhitespaceOption],
) -> String:
    """Places a string or text block vertically in an unstyled box of a given
    width or height.

    Args:
        width: The width of the box.
        height: The height of the box.
        horizontal_position: The horizontal position of the text.
        vertical_position: The vertical position of the text.
        text: The text to place.
        opts: The options to style the whitespace.

    Returns:
        The text placed in the box.
    """
    return Renderer()._place(width, height, horizontal_position, vertical_position, text, opts)


fn place_horizontal(width: Int, pos: Position, text: String, *opts: WhitespaceOption) -> String:
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
    return _place_horizontal(width, pos, text, opts)


fn _place_horizontal(width: Int, pos: Position, text: String, opts: VariadicList[WhitespaceOption]) -> String:
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
    return Renderer()._place_horizontal(width, pos, text, opts)


fn place_vertical(height: Int, pos: Position, text: String, *opts: WhitespaceOption) -> String:
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
    return _place_vertical(height, pos, text, opts)


fn _place_vertical(height: Int, pos: Position, text: String, opts: VariadicList[WhitespaceOption]) -> String:
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
    return Renderer()._place_vertical(height, pos, text, opts)
