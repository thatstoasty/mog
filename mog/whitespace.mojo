"""A module for rendering whitespace in the terminal."""
from mist.transform import ansi
from mist import Profile
from mog._extensions import get_lines, get_widest_line, DEFAULT_BUFFER_SIZE, WHITESPACE, NEWLINE
from mog.align import Alignment
from mog.position import Position
from mog.renderer import Renderer
from mog.style import Style


@fieldwise_init
struct WhitespaceRenderer(ImplicitlyCopyable):
    """Whitespace renderer."""

    var renderer: Renderer
    """The renderer which determifnes the color profile."""
    var style: Style
    """Terminal styling for the whitespace."""
    var chars: String
    """The characters to render for whitespace. Defaults to a space."""

    def __init__(
        out self,
        style: Style,
        chars: String = " ",
    ):
        """Initializes a new whitespace renderer.

        Args:
            style: The style to use.
            chars: The characters to render.
        """
        # TODO: Assume dark background for now, until I add support to mist for querying background color.
        self.renderer = style._renderer.copy()
        self.style = style.copy()
        self.chars = chars.copy()

    def render(self, width: UInt) -> String:
        """Render whitespaces.

        Args:
            width: The width of the whitespace.

        Returns:
            The rendered whitespace.
        """
        var j: UInt = 0
        var result = String(capacity=DEFAULT_BUFFER_SIZE)

        # Cycle through runes and print them into the whitespace.
        var i: UInt = 0
        while i < width:
            for codepoint in self.chars.codepoint_slices():
                result.write(codepoint)
                var printable_width = UInt(ansi.printable_rune_width(codepoint))
                if j >= printable_width:
                    j = 0

                # If we hit the width of the block, break the loop back up to the top while, which will end.
                i += printable_width
                if i >= width:
                    break

        #  Fill any extra gaps white spaces. This might be necessary if any runes
        #  are more than one cell wide, which could leave a one-rune gap.
        var rendered_width = ansi.printable_rune_width(result)
        if rendered_width < width:
            result.write(WHITESPACE * Int(width - rendered_width))

        return self.style.render(result)

    def place[origin: ImmOrigin, //](
        self,
        text: StringSpan[origin],
        width: UInt,
        height: UInt,
        alignment: Alignment,
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            text: The string to place in the block.
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            alignment: The horizontal and vertical alignment to place the text in the block.
                For horizontal, 0 is the left side, 0.5 is center, and 1 is the right side.
                For veritcal, 0 is the top, 0.5 is center, and 1 is the bottom.

        Returns:
            The string with the text placed in the block.
        """
        return self.place_vertical(
            self.place_horizontal(text, width, alignment.horizontal),
            height,
            alignment.vertical,
        )

    def place_horizontal[origin: ImmOrigin, //](
        self,
        text: StringSpan[origin],
        width: UInt,
        alignment: Position = Position.LEFT,
    ) -> String:
        """Places a string or text block horizontally in an unstyled
        block of a given width. If the given width is shorter than the max width of
        the string (measured by its longest line) this will be a noöp.

        Args:
            text: The string to place in the block.
            width: The width of the block to place the text in.
            alignment: The position to place the text in the block. This should be
                a float between 0 and 1.
                0 is left aligned, 1 is the right aligned, and
                0.5 is center aligned. Defaults to left aligned.

        Returns:
            The string with the text placed in the block.
        """
        var lines = text.split(NEWLINE)
        var content_width = get_widest_line(lines)
        # Compare before subtracting: these are unsigned, so text wider than the block
        # would wrap to a huge gap and send `render` into an effectively endless loop.
        if content_width >= width:
            return String(text)

        var gap = width - content_width

        var result = String(capacity=Int(Float64(text.byte_length()) * 1.25))
        for i in range(len(lines)):
            if i != 0:
                result.write(NEWLINE)

            # Is this line shorter than the longest line? `content_width` is the widest
            # of these same lines, measured with the same function, so this subtraction
            # cannot underflow. Wrapping it in `max(0, ...)` would suggest otherwise
            # while doing nothing, since these are unsigned.
            var line_width = ansi.printable_rune_width(lines[i])
            debug_assert(line_width <= content_width, "line cannot be wider than the widest line")
            var short = content_width - line_width
            if alignment == Position.LEFT:
                result.write(lines[i], self.render(UInt(gap + short)))
            elif alignment == Position.RIGHT:
                result.write(self.render(UInt(gap + short)), lines[i])
            else:
                # somewhere in the middle
                var total_gap = gap + short
                var split = UInt(Int(round(Float64(total_gap) * alignment.value)))
                var right = total_gap - split
                var left = total_gap - right
                result.write(self.render(left), lines[i], self.render(right))

        return result^

    def place_vertical[origin: ImmOrigin, //](
        self,
        text: StringSpan[origin],
        height: UInt,
        alignment: Position = Position.TOP,
    ) -> String:
        """Places a string or text block vertically in an unstyled block
        of a given height. If the given height is shorter than the height of the
        string (measured by its newlines) then this will be a noöp.

        Args:
            text: The string to place in the block.
            height: The height of the block to place the text in.
            alignment: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the top, 1 is the bottom, and 0.5 is
                the center. Defaults to top aligned.

        Returns:
            The string with the text placed in the block.
        """
        var content_height = UInt(text.count(NEWLINE) + 1)
        if content_height >= height:
            return String(text)

        var gap = height - content_height

        var empty_line = self.render(get_widest_line(text))
        var result = String(capacity=Int(Float64(text.byte_length()) * 1.25))
        if alignment == Position.TOP:
            result.write(text, NEWLINE)

            var i: UInt = 0
            while i < gap:
                result.write(empty_line)
                if i < gap - 1:
                    result.write(NEWLINE)
                i += 1
        elif alignment == Position.BOTTOM:
            result.write((empty_line + NEWLINE) * Int(gap), text)
        else:
            # somewhere in the middle
            var split = UInt(Int(round(Float64(gap) * alignment.value)))
            var bottom = gap - split
            var top = gap - bottom

            result.write((empty_line + NEWLINE) * Int(top), text)
            for _ in range(bottom):
                result.write(NEWLINE, empty_line)

        return result^


comptime DEFAULT_WHITESPACE_RENDERER = WhitespaceRenderer(Style(Profile.ASCII))

def place_horizontal[origin: ImmOrigin, //](
    text: StringSpan[origin],
    width: UInt,
    alignment: Position = Position.LEFT,
) -> String:
    """Places a string or text block horizontally in an unstyled
    block of a given width. If the given width is shorter than the max width of
    the string (measured by its longest line) this will be a noöp.

    Args:
        text: The string to place in the block.
        width: The width of the block to place the text in.
        alignment: The position to place the text in the block. This should be
            a float between 0 and 1.
            0 is left aligned, 1 is the right aligned, and
            0.5 is center aligned. Defaults to left aligned.

    Returns:
        The string with the text placed in the block.
    """
    return DEFAULT_WHITESPACE_RENDERER.place_horizontal(text, width, alignment)


def place_vertical[origin: ImmOrigin, //](
    text: StringSpan[origin],
    height: UInt,
    alignment: Position = Position.TOP,
) -> String:
    """Places a string or text block vertically in an unstyled block
    of a given height. If the given height is shorter than the height of the
    string (measured by its newlines) then this will be a noöp.

    Args:
        text: The string to place in the block.
        height: The height of the block to place the text in.
        alignment: The position to place the text in the block. This should be
            a float between 0 and 1. 0 is the top, 1 is the bottom, and 0.5 is
            the center. Defaults to top aligned.

    Returns:
        The string with the text placed in the block.
    """
    return DEFAULT_WHITESPACE_RENDERER.place_vertical(text, height, alignment)


def place[origin: ImmOrigin, //](
    text: StringSpan[origin],
    width: UInt,
    height: UInt,
    alignment: Alignment,
) -> String:
    """Places a string or text block vertically in an unstyled box of a given
    width or height.

    Args:
        text: The string to place in the block.
        width: The width of the block to place the text in.
        height: The height of the block to place the text in.
        alignment: The horizontal and vertical alignment to place the text in the block.
            For horizontal, 0 is the left side, 0.5 is center, and 1 is the right side.
            For veritcal, 0 is the top, 0.5 is center, and 1 is the bottom.

    Returns:
        The string with the text placed in the block.
    """
    return DEFAULT_WHITESPACE_RENDERER.place(text, width, height, alignment)
