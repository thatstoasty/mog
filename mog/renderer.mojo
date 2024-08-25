from collections import Optional
import .mist
from .gojo.strings import StringBuilder
import .weave.ansi
from .whitespace import WhitespaceOption, new_whitespace
import .position
from .extensions import split


# TODO: Cannot handle characters with a printable width of 2 or more. Like east asian characters (Kanji, etc.).
# Working on terminal background querying, for now it defaults to dark background terminal.
# If you need to set it to light, you can do so manually via the `set_dark_background` method.
@value
struct Renderer:
    var color_profile: mist.Profile
    var dark_background: Bool
    var explicit_color_profile: Bool
    var explicit_background_color: Bool

    fn __init__(
        inout self,
        color_profile: Optional[Int] = None,
        dark_background: Bool = True,
        explicit_color_profile: Bool = False,
        explicit_background_color: Bool = False,
    ):
        if color_profile:
            self.color_profile = mist.Profile(color_profile.value())
        else:
            self.color_profile = mist.Profile()
        self.dark_background = dark_background
        self.explicit_color_profile = explicit_color_profile
        self.explicit_background_color = explicit_background_color

    fn set_color_profile(inout self, value: Int):
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
        """
        self.color_profile.value = value
        self.explicit_color_profile = True

    fn has_dark_background(self) -> Bool:
        """Returns whether or not the renderer will render to a dark
        background. A dark background can either be auto-detected, or set explicitly
        on the renderer.
        """
        return self.dark_background

    fn set_dark_background(inout self, value: Bool):
        """Sets the background color detection value for the
        default renderer. This function exists mostly for testing purposes so that
        you can assure you're testing against a specific background color setting.

        Outside of testing you likely won't want to use this function as the
        backgrounds value will be automatically detected and cached against the
        terminal's current background color setting.
        """
        self.dark_background = value
        self.explicit_background_color = True

    fn place(
        self,
        width: Int,
        height: Int,
        hPos: Float64,
        vPos: Float64,
        text: String,
        /,
        *opts: WhitespaceOption,
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            hPos: The position to place the text horizontally in the block. This
                should be a float between 0 and 1. 0 is the left side, 1 is the right
                side, and 0.5 is the center.
            vPos: The position to place the text vertically in the block. This
                should be a float between 0 and 1. 0 is the top, 1 is the bottom, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        var options = List[WhitespaceOption]()
        for opt in opts:
            options.append(opt)
        return self.place_vertical(
            height,
            vPos,
            self.place_horizontal(width, hPos, text, options),
            options,
        )

    # TODO: temp until arg unpacking
    fn place(
        self,
        width: Int,
        height: Int,
        hPos: Float64,
        vPos: Float64,
        text: String,
        opts: List[WhitespaceOption],
    ) -> String:
        """Places a string or text block vertically in an unstyled box of a given
        width or height.

        Args:
            width: The width of the block to place the text in.
            height: The height of the block to place the text in.
            hPos: The position to place the text horizontally in the block. This
                should be a float between 0 and 1. 0 is the left side, 1 is the right
                side, and 0.5 is the center.
            vPos: The position to place the text vertically in the block. This
                should be a float between 0 and 1. 0 is the top, 1 is the bottom, and
                0.5 is the center.
            text: The string to place in the block.
            opts: Options to configure the whitespace.

        Returns:
            The string with the text placed in the block.
        """
        return self.place_vertical(height, vPos, self.place_horizontal(width, hPos, text, opts), opts)

    fn place_horizontal(self, width: Int, pos: Float64, text: String, /, *opts: WhitespaceOption) raises -> String:
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
        var lines = text.split("\n")
        print(lines.__str__())
        var content_width: Int = 0
        for i in range(len(lines)):
            if ansi.printable_rune_width(lines[i]) > content_width:
                content_width = ansi.printable_rune_width(lines[i])

        var gap = width - content_width
        if gap <= 0:
            return text

        var options = List[WhitespaceOption]()
        for opt in opts:
            options.append(opt)

        var white_space = new_whitespace(self, options)
        var builder = StringBuilder()
        for i in range(len(lines)):
            # Is this line shorter than the longest line?
            var short = max(0, content_width - ansi.printable_rune_width(lines[i]))
            if pos == position.left:
                _ = builder.write_string(lines[i])
                _ = builder.write_string(white_space.render(gap + short))
            elif pos == position.right:
                _ = builder.write_string(white_space.render(gap + short))
                _ = builder.write_string(lines[i])
            else:
                # somewhere in the middle
                var total_gap = gap + short
                var split = int(round(Float64(total_gap) * pos))
                var left = total_gap - split
                var right = total_gap - left
                _ = builder.write_string(white_space.render(left))
                _ = builder.write_string(lines[i])
                _ = builder.write_string(white_space.render(right))

            if i < len(lines) - 1:
                _ = builder.write_byte(ord("\n"))

        return str(builder)

    # TODO: Temporary until arg unpacking is supported.
    fn place_horizontal(
        self,
        width: Int,
        pos: Float64,
        text: String,
        opts: List[WhitespaceOption],
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
        var lines = split(text, "\n")
        var content_width: Int = 0
        for i in range(len(lines)):
            if ansi.printable_rune_width(lines[i]) > content_width:
                content_width = ansi.printable_rune_width(lines[i])

        var gap = width - content_width
        if gap <= 0:
            return text

        var white_space = new_whitespace(self, opts)
        var builder = StringBuilder()
        for i in range(len(lines)):
            # Is this line shorter than the longest line?
            var short = max(0, content_width - ansi.printable_rune_width(lines[i]))
            if pos == position.left:
                _ = builder.write_string(lines[i])
                _ = builder.write_string(white_space.render(gap + short))
            elif pos == position.right:
                _ = builder.write_string(white_space.render(gap + short))
                _ = builder.write_string(lines[i])
            else:
                # somewhere in the middle
                var total_gap = gap + short
                var split = int(round(Float64(total_gap) * pos))
                var left = total_gap - split
                var right = total_gap - left
                _ = builder.write_string(white_space.render(left))
                _ = builder.write_string(lines[i])
                _ = builder.write_string(white_space.render(right))

            if i < len(lines) - 1:
                _ = builder.write_byte(ord("\n"))

        return str(builder)

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
        var content_height = text.count("\n") + 1
        var gap = height - content_height

        if gap <= 0:
            return text

        var options = List[WhitespaceOption]()
        for opt in opts:
            options.append(opt)
        var white_space = new_whitespace(self, options)

        var lines = split(text, "\n")
        var width: Int = 0
        for i in range(len(lines)):
            if ansi.printable_rune_width(lines[i]) > width:
                width = ansi.printable_rune_width(lines[i])

        var empty_line = white_space.render(width)
        var builder = StringBuilder()

        if pos == position.top:
            _ = builder.write_string(text)
            _ = builder.write_byte(ord("\n"))

            var i = 0
            while i < gap:
                _ = builder.write_string(empty_line)
                if i < gap - 1:
                    _ = builder.write_byte(ord("\n"))
                i += 1

        elif pos == position.bottom:
            _ = builder.write_string((empty_line + "\n") * gap)
            _ = builder.write_string(text)
        else:
            # somewhere in the middle
            var split = int(round(Float64(gap) * pos))
            var top = gap - split
            var bottom = gap - top
            _ = builder.write_string((empty_line + "\n") * top)
            _ = builder.write_string(text)

            var i = 0
            while i < bottom:
                _ = builder.write_byte(ord("\n"))
                _ = builder.write_string(empty_line)
                i += 1

        return str(builder)

    fn place_vertical(
        self,
        height: Int,
        pos: Float64,
        text: String,
        opts: List[WhitespaceOption],
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
        var content_height = text.count("\n") + 1
        var gap = height - content_height

        if gap <= 0:
            return text

        var white_space = new_whitespace(self, opts)

        var lines = split(text, "\n")
        print(lines.__str__())
        var width: Int = 0
        for i in range(len(lines)):
            print("len\n", ansi.printable_rune_width(lines[i]), lines[i], "\n")
            if ansi.printable_rune_width(lines[i]) > width:
                width = ansi.printable_rune_width(lines[i])

        var empty_line = white_space.render(width)
        var builder = StringBuilder()

        if pos == position.top:
            _ = builder.write_string(text)
            _ = builder.write_byte(ord("\n"))

            var i = 0
            while i < gap:
                _ = builder.write_string(empty_line)
                if i < gap - 1:
                    _ = builder.write_byte(ord("\n"))
                i += 1
        elif pos == position.bottom:
            _ = builder.write_string((empty_line + "\n") * gap)
            _ = builder.write_string(text)
        else:
            # somewhere in the middle
            var split = int(round(Float64(gap) * pos))
            var top = gap - split
            var bottom = gap - top

            print(top, bottom)
            _ = builder.write_string((empty_line + "\n") * top)
            _ = builder.write_string(text)
            print(str(builder))

            var i = 0
            while i < bottom:
                _ = builder.write_byte(ord("\n"))
                _ = builder.write_string(empty_line)
                i += 1

        print("done")
        return str(builder)
