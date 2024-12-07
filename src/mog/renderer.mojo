from collections import Optional
import mist
import weave.ansi
from .extensions import get_lines
from .whitespace import WhitespaceOption, new_whitespace, _new_whitespace
import .position


# Working on terminal background querying, for now it defaults to dark background terminal.
# If you need to set it to light, you can do so manually via the `set_dark_background` method.
@value
struct Renderer:
    """Contains context for the color profile of the terminal and it's background."""

    var color_profile: mist.Profile
    """The color profile to use for the renderer."""
    var dark_background: Bool
    """Whether or not the renderer will render to a dark background."""
    var explicit_color_profile: Bool
    """Whether the color profile was explicitly set."""
    var explicit_background_color: Bool
    """Whether the background color was explicitly set."""

    fn __init__(
        out self,
        color_profile: Optional[Int] = None,
        dark_background: Bool = True,
        explicit_color_profile: Bool = False,
        explicit_background_color: Bool = False,
    ):
        """Initializes a new renderer instance.

        Args:
            color_profile: The color profile to use for the renderer. Defaults to None.
            dark_background: Whether or not the renderer will render to a dark background. Defaults to True.
            explicit_color_profile: Whether the color profile was explicitly set. Defaults to False.
            explicit_background_color: Whether the background color was explicitly set. Defaults to False.
        """

        if color_profile:
            self.color_profile = mist.Profile(color_profile.value())
        else:
            self.color_profile = mist.Profile()
        self.dark_background = dark_background
        self.explicit_color_profile = explicit_color_profile
        self.explicit_background_color = explicit_background_color

    fn set_color_profile(mut self, value: Int):
        """Sets the color profile on the renderer. This function exists
        mostly for testing purposes so that you can assure you're testing against
        a specific profile.

        Outside of testing you likely won't want to use this function as the color
        profile will detect and cache the terminal's color capabilities and choose
        the best available profile.

        Available color profiles are:

            mist.ASCII      no color, 1-bit
            mist.ANSI      16 colors, 4-bit
            mist.ANSI256    256 colors, 8-bit
            mist.TRUE_COLOR  16,777,216 colors, 24-bit

        Args:
            value: The color profile to set on the renderer.
        """
        self.color_profile.value = value
        self.explicit_color_profile = True

    fn has_dark_background(self) -> Bool:
        """Returns whether or not the renderer will render to a dark
        background. A dark background can either be auto-detected, or set explicitly
        on the renderer.

        Returns:
            Whether or not the renderer will render to a dark background.
        """
        return self.dark_background

    fn set_dark_background(mut self, value: Bool):
        """Sets the background color detection value for the
        default renderer. This function exists mostly for testing purposes so that
        you can assure you're testing against a specific background color setting.

        Outside of testing you likely won't want to use this function as the
        backgrounds value will be automatically detected and cached against the
        terminal's current background color setting.

        Args:
            value: Whether or not the renderer will render to a dark background.
        """
        self.dark_background = value
        self.explicit_background_color = True

    fn place(
        self,
        width: Int,
        height: Int,
        horizontal_position: Float64,
        vertical_position: Float64,
        text: String,
        /,
        *opts: WhitespaceOption,
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            horizontal_position: The position to place the text horizontally in the block. This
                should be a float between 0 and 1. 0 is the left side, 1 is the right
                side, and 0.5 is the center.
            vertical_position: The position to place the text vertically in the block. This
                should be a float between 0 and 1. 0 is the top, 1 is the bottom, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_vertical(
            height,
            vertical_position,
            self._place_horizontal(width, horizontal_position, text, opts),
            opts,
        )

    fn _place(
        self,
        width: Int,
        height: Int,
        horizontal_position: Float64,
        vertical_position: Float64,
        text: String,
        opts: VariadicList[WhitespaceOption],
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            horizontal_position: The position to place the text horizontally in the block. This
                should be a float between 0 and 1. 0 is the left side, 1 is the right
                side, and 0.5 is the center.
            vertical_position: The position to place the text vertically in the block. This
                should be a float between 0 and 1. 0 is the top, 1 is the bottom, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_vertical(
            height, vertical_position, self._place_horizontal(width, horizontal_position, text, opts), opts
        )

    fn place_horizontal(self, width: Int, pos: Float64, text: String, /, *opts: WhitespaceOption) -> String:
        """Places a string or text block horizontally in an unstyled
        block of a given width. If the given width is shorter than the max width of
        the string (measured by its longest line) this will be a noöp.

        Args:
            width: The width of the block to place the text in.
            pos: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the left side, 1 is the right side, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_horizontal(width, pos, text, opts)

    fn _place_horizontal(
        self,
        width: Int,
        pos: Float64,
        text: String,
        opts: VariadicList[WhitespaceOption],
    ) -> String:
        """Places a string or text block horizontally in an unstyled
        block of a given width. If the given width is shorter than the max width of
        the string (measured by its longest line) this will be a noöp.

        Args:
            width: The width of the block to place the text in.
            pos: The position to place the text in the block. This should be
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

        var white_space = _new_whitespace(self, opts)
        var result = String()
        for i in range(len(lines)):
            # Is this line shorter than the longest line?
            var short = max(0, content_width - ansi.printable_rune_width(lines[i]))
            if pos == position.left:
                result.write(lines[i], white_space.render(gap + short))
            elif pos == position.right:
                result.write(white_space.render(gap + short), lines[i])
            else:
                # somewhere in the middle
                var total_gap = gap + short
                var split = int(round(Float64(total_gap) * pos))
                var left = total_gap - split
                var right = total_gap - left
                result.write(white_space.render(left), lines[i], white_space.render(right))

            if i < len(lines) - 1:
                result.write(NEWLINE)

        return result

    fn place_vertical(
        self,
        height: Int,
        pos: Float64,
        text: String,
        /,
        *opts: WhitespaceOption,
    ) -> String:
        """Places a string or text block vertically in an unstyled block
        of a given height. If the given height is shorter than the height of the
        string (measured by its newlines) then this will be a noöp.

        Args:
            height: The height of the block to place the text in.
            pos: The position to place the text in the block. This should be
                a float between 0 and 1. 0 is the top, 1 is the bottom, and 0.5 is
                the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self._place_vertical(height, pos, text, opts)

    fn _place_vertical(
        self,
        height: Int,
        pos: Float64,
        text: String,
        opts: VariadicList[WhitespaceOption],
    ) -> String:
        """Places a string or text block vertically in an unstyled block
        of a given height. If the given height is shorter than the height of the
        string (measured by its newlines) then this will be a noöp.

        Args:
            height: The height of the block to place the text in.
            pos: The position to place the text in the block. This should be
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

        var white_space = _new_whitespace(self, opts)

        _, width = get_lines(text)
        var empty_line = white_space.render(width)
        var result = String()
        if pos == position.top:
            result.write(text, NEWLINE)

            var i = 0
            while i < gap:
                result.write(empty_line)
                if i < gap - 1:
                    result.write(NEWLINE)
                i += 1
        elif pos == position.bottom:
            result.write((empty_line + NEWLINE) * gap, text)
        else:
            # somewhere in the middle
            var split = int(round(Float64(gap) * pos))
            var top = gap - split
            var bottom = gap - top

            result.write((empty_line + NEWLINE) * top, text)
            for _ in range(bottom):
                result.write(NEWLINE, empty_line)

        return result
