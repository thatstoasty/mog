import mist.transform.ansi
from mog._extensions import get_lines, get_widest_line
from mog._properties import Alignment
from mog.position import Position
from mog.renderer import Renderer


@fieldwise_init
struct WhitespaceRenderer(Copyable, Movable):
    """Whitespace renderer."""

    var renderer: Renderer
    """The renderer which determines the color profile."""
    var style: mog.Style
    """Terminal styling for the whitespace."""
    var chars: String
    """The characters to render for whitespace. Defaults to a space."""

    fn __init__(
        out self,
        style: mog.Style,
        chars: String = " ",
    ):
        """Initializes a new whitespace renderer.

        Args:
            style: The style to use.
            chars: The characters to render.
        """
        # TODO: Assume dark background for now, until I add support to mist for querying background color.
        self.renderer = style._renderer
        self.style = style.copy()
        self.chars = chars.copy()

    fn copy(self) -> Self:
        """Copies the whitespace renderer.

        Returns:
            A copy of the whitespace renderer.
        """
        return Self(
            style=self.style.copy(),
            chars=self.chars,
        )

    fn render(self, width: Int) -> String:
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
            for codepoint in self.chars.codepoint_slices():
                result.write(codepoint)
                var printable_width = ansi.printable_rune_width(codepoint)
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

    fn place(
        self,
        width: UInt,
        height: UInt,
        alignment: Alignment,
        text: String,
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            alignment: The horizontal and vertical alignment to place the text in the block.
                For horizontal, 0 is the left side, 0.5 is center, and 1 is the right side.
                For veritcal, 0 is the top, 0.5 is center, and 1 is the bottom.
            text: The string to place in the block.

        Returns:
            The string with the text placed in the block.
        """
        return self.place_vertical(
            self.place_horizontal(text, width, alignment.horizontal),
            height,
            alignment.vertical,
        )

    fn place_horizontal(
        self,
        text: String,
        width: UInt,
        alignment: Position = Position(0),
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
        var gap = width - content_width
        if gap <= 0:
            return text

        var result = String(capacity=Int(len(text) * 1.25))
        for i in range(len(lines)):
            if i != 0:
                result.write(NEWLINE)

            # Is this line shorter than the longest line?
            var short = max(0, content_width - ansi.printable_rune_width(lines[i]))
            if alignment == Position.LEFT:
                result.write(lines[i], self.render(gap + short))
            elif alignment == Position.RIGHT:
                result.write(self.render(gap + short), lines[i])
            else:
                # somewhere in the middle
                var total_gap = gap + short
                var split = Int(round(total_gap * alignment.value))
                var right = total_gap - split
                var left = total_gap - right
                result.write(self.render(left), lines[i], self.render(right))

        return result^

    fn place_vertical(
        self,
        text: String,
        height: UInt,
        alignment: Position = Position(0),
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
        var content_height = text.count(NEWLINE) + 1
        var gap = height - content_height
        if gap <= 0:
            return text

        var empty_line = self.render(get_widest_line(text))
        var result = String(capacity=Int(len(text) * 1.25))
        if alignment == Position.TOP:
            result.write(text, NEWLINE)

            var i = 0
            while i < gap:
                result.write(empty_line)
                if i < gap - 1:
                    result.write(NEWLINE)
                i += 1
        elif alignment == Position.BOTTOM:
            result.write((empty_line + NEWLINE) * gap, text)
        else:
            # somewhere in the middle
            var split = Int(round(Float64(gap) * alignment.value))
            var bottom = gap - split
            var top = gap - bottom

            result.write((empty_line + NEWLINE) * top, text)
            for _ in range(bottom):
                result.write(NEWLINE, empty_line)

        return result^
