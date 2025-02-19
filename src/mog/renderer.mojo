from collections import Optional
import mist
import weave.ansi
from mog.extensions import get_lines, get_widest_line
from mog.whitespace import WhitespaceOption, WhitespaceRenderer
from mog.position import Position


# Working on terminal background querying, currently it defaults to dark background terminal.
# If you need to set it to light, you can do so manually via the `set_dark_background` method.
@value
@register_passable("trivial")
struct Renderer:
    """Contains context for the color profile of the terminal and it's background.
    
    ### Attributes:
    * `profile`: The color profile to use for the renderer.
    * `dark_background`: Whether or not the renderer will render to a dark background.
    """

    var profile: mist.Profile
    """The color profile to use for the renderer."""
    var dark_background: Bool
    """Whether or not the renderer will render to a dark background."""

    fn __init__(
        out self,
        profile: Int = -1,
        *,
        dark_background: Bool = True,
    ):
        """Initializes a new renderer instance.

        Args:
            profile: The color profile to use for the renderer. Defaults to None.
            dark_background: Whether or not the renderer will render to a dark background. Defaults to True.
        """
        if profile != -1:
            self.profile = mist.Profile(profile)
        else:
            self.profile = mist.Profile()
        self.dark_background = dark_background

    fn has_dark_background(self) -> Bool:
        """Returns whether or not the renderer will render to a dark
        background. A dark background can either be auto-detected, or set explicitly
        on the renderer.

        Returns:
            Whether or not the renderer will render to a dark background.
        """
        return self.dark_background
    
    fn as_mist_style(self) -> mist.Style:
        """Returns a the `mist.Style` using the same profile as the for the style.

        Returns:
            The mist style.
        """
        return mist.Style(self.profile)

    fn place(
        self,
        width: Int,
        height: Int,
        horizontal_alignment: Position,
        vertical_alignment: Position,
        text: String,
        /,
        *opts: WhitespaceOption,
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            horizontal_alignment: The position to place the text horizontally in the block. This
                should be a float between 0 and 1. 0 is the left side, 1 is the right
                side, and 0.5 is the center.
            vertical_alignment: The position to place the text vertically in the block. This
                should be a float between 0 and 1. 0 is the top, 1 is the bottom, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_vertical(
            height,
            vertical_alignment,
            self._place_horizontal(width, horizontal_alignment, text, opts),
            opts,
        )

    fn _place(
        self,
        width: Int,
        height: Int,
        horizontal_alignment: Position,
        vertical_alignment: Position,
        text: String,
        opts: VariadicList[WhitespaceOption],
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            horizontal_alignment: The position to place the text horizontally in the block. This
                should be a float between 0 and 1. 0 is the left side, 1 is the right
                side, and 0.5 is the center.
            vertical_alignment: The position to place the text vertically in the block. This
                should be a float between 0 and 1. 0 is the top, 1 is the bottom, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_vertical(
            height, vertical_alignment, self._place_horizontal(width, horizontal_alignment, text, opts), opts
        )

    fn place_horizontal(self, width: Int, alignment: Position, text: String, /, *opts: WhitespaceOption) -> String:
        """Places a string or text block horizontally in an unstyled
        block of a given width. If the given width is shorter than the max width of
        the string (measured by its longest line) this will be a noöp.

        Args:
            width: The width of the block to place the text in.
            alignment: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the left side, 1 is the right side, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_horizontal(width, alignment, text, opts)

    fn _place_horizontal(
        self,
        width: Int,
        alignment: Position,
        text: String,
        opts: VariadicList[WhitespaceOption],
    ) -> String:
        """Places a string or text block horizontally in an unstyled
        block of a given width. If the given width is shorter than the max width of
        the string (measured by its longest line) this will be a noöp.

        Args:
            width: The width of the block to place the text in.
            alignment: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the left side, 1 is the right side, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        lines, content_width = get_lines(text)
        var gap = width - content_width
        if gap <= 0:
            return text

        var white_space = WhitespaceRenderer(self, opts)
        var result = String()
        for i in range(len(lines)):
            # Is this line shorter than the longest line?
            var short = max(0, content_width - ansi.printable_rune_width(lines[i]))
            if alignment == Position.LEFT:
                result.write(lines[i], white_space.render(gap + short))
            elif alignment == Position.RIGHT:
                result.write(white_space.render(gap + short), lines[i])
            else:
                # somewhere in the middle
                var total_gap = gap + short
                var split = Int(round(total_gap * alignment.value))
                var right = total_gap - split
                var left = total_gap - right
                result.write(white_space.render(left), lines[i], white_space.render(right))

            if i < len(lines) - 1:
                result.write(NEWLINE)

        return result^

    fn place_vertical(
        self,
        height: Int,
        alignment: Position,
        text: String,
        /,
        *opts: WhitespaceOption,
    ) -> String:
        """Places a string or text block vertically in an unstyled block
        of a given height. If the given height is shorter than the height of the
        string (measured by its newlines) then this will be a noöp.

        Args:
            height: The height of the block to place the text in.
            alignment: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the top, 1 is the bottom, and 0.5 is
                the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_vertical(height, alignment, text, opts)

    fn _place_vertical(
        self,
        height: Int,
        alignment: Position,
        text: String,
        opts: VariadicList[WhitespaceOption],
    ) -> String:
        """Places a string or text block vertically in an unstyled block
        of a given height. If the given height is shorter than the height of the
        string (measured by its newlines) then this will be a noöp.

        Args:
            height: The height of the block to place the text in.
            alignment: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the top, 1 is the bottom, and 0.5 is
                the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        var content_height = text.count(NEWLINE) + 1
        var gap = height - content_height
        if gap <= 0:
            return text

        var empty_line = WhitespaceRenderer(self, opts).render(get_widest_line(text))
        var result = String()
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
