"""A module for styling text in the terminal."""
import mist
from mist.transform import truncate, word_wrap, wrap
from mist.transform.ansi import printable_rune_width
from mog._extensions import get_lines, get_widest_line, pad_left, pad_right, WHITESPACE, NEWLINE, DEFAULT_BUFFER_SIZE
from mog._properties import (
    BorderColor,
    Coloring,
    Dimensions,
    Margin,
    Padding,
    Properties,
    PropKey,
    Side,
    Emphasis,
    Axis,
)
from mog.align import align_text_horizontal, align_text_vertical, Alignment
from mog.border import (
    ASCII_BORDER,
    BLOCK_BORDER,
    DOUBLE_BORDER,
    HIDDEN_BORDER,
    INNER_HALF_BLOCK_BORDER,
    NO_BORDER,
    NORMAL_BORDER,
    OUTER_HALF_BLOCK_BORDER,
    PLUS_BORDER,
    ROUNDED_BORDER,
    STAR_BORDER,
    THICK_BORDER,
    Border,
    render_horizontal_edge,
)
from mog.color import (
    AdaptiveColor,
    ANSIColor,
    AnyTerminalColor,
    Color,
    CompleteAdaptiveColor,
    CompleteColor,
    NoColor,
    TerminalColor,
)
from mog.position import Position
from mog.renderer import Renderer


comptime TAB_WIDTH = 4
"""The default tab width to use when rendering text with tabs."""

comptime NO_TAB_CONVERSION = -1
"""Used to disable the replacement of tabs with spaces at render time."""


@fieldwise_init
struct Stylers(Movable, Writable):
    """A collection of stylers to use when rendering text with a style.

    We need to use different stylers for spaces and non-space characters when
    certain properties are set on the style, such as COLOR_WHITESPACE, UNDERLINE_SPACES, STRIKETHROUGH_SPACES, etc.
    """

    var common: mist.Style
    """The styler to use for non-space characters."""
    var space: mist.Style
    """The styler to use for space characters. Only used if the style has COLOR_WHITESPACE enabled or if UNDERLINE_SPACES or STRIKETHROUGH_SPACES is enabled and UNDERLINE_SPACES or STRIKETHROUGH_SPACES is set to apply to spaces."""
    var whitespace: mist.Style
    """The styler to use for whitespace characters. Only used if the style has COLOR_WHITESPACE enabled."""


def _starts_with_space(grapheme: StringSpan) -> Bool:
    """Whether a grapheme cluster's base character is whitespace.

    A cluster is drawn as one character and so is styled as one unit, which
    means it is classified by the character it begins with. A space carrying a
    combining mark is still a space, even though the mark itself is not.

    Args:
        grapheme: The cluster to classify.

    Returns:
        True if the cluster starts with whitespace.
    """
    for codepoint in grapheme.codepoint_slices():
        return codepoint.isspace()
    return False


def _apply_styles[origin: ImmOrigin, //](text: StringSpan[origin], use_space_styler: Bool, styles: Stylers) -> String:
    """Apply styles to text.

    Args:
        text: The text to apply styles to.
        use_space_styler: Whether to use the space styler.
        styles: The styles to apply.

    Returns:
        The styled text.
    """
    var result = String(capacity=Int(Float64(text.byte_length()) * 1.5))

    var lines = text.split(NEWLINE)
    for i in range(len(lines)):
        # Readd the newlines
        if i != 0:
            result.write(NEWLINE)

        # If we're using a space styler, we need to check each character.
        # Look for spaces and apply a different styler.
        if use_space_styler:
            # Styled a run at a time rather than a character at a time. Every
            # character in a run gets the same escape sequences, so wrapping
            # each one separately paints the same thing several times over --
            # "Project" under `underline` went out as seven copies of
            # `\x1b[4;36mX\x1b[0m`, 84 bytes for 7 columns.
            #
            # Walked by grapheme rather than by codepoint so that a cluster is
            # never split across two runs, which would put escape sequences
            # inside a single drawn character. Lipgloss classifies clusters the
            # same way, by the character they start with.
            ref line = lines[i]
            var run_start = 0
            var offset = 0
            var run_is_space = False
            for grapheme in line.graphemes():
                var is_space = _starts_with_space(grapheme)
                if offset == 0:
                    run_is_space = is_space
                elif is_space != run_is_space:
                    if run_is_space:
                        result.write(styles.space.render(line[byte=run_start:offset]))
                    else:
                        result.write(styles.common.render(line[byte=run_start:offset]))
                    run_start = offset
                    run_is_space = is_space
                offset += grapheme.byte_length()

            if offset > run_start:
                if run_is_space:
                    result.write(styles.space.render(line[byte=run_start:offset]))
                else:
                    result.write(styles.common.render(line[byte=run_start:offset]))
        else:
            result.write(styles.common.render(lines[i]))

    return result^


def _wrap_words[origin: ImmOrigin, //](text: StringSpan[origin], width: UInt16, left_padding: UInt16, right_padding: UInt16) -> String:
    var wrap_at = width - left_padding - right_padding

    # A string's display width never exceeds its byte length: ASCII is one byte per cell,
    # and everything wider than a byte (multi-byte glyphs, combining marks, escape
    # sequences) costs more bytes than cells. So fitting in bytes proves it fits in
    # cells, and the two wrapping passes below can be skipped. Measuring the real width
    # to catch the remaining cases would cost more than it saves.
    if text.byte_length() <= Int(wrap_at) and NEWLINE not in text:
        return String(text)

    return wrap(word_wrap(text, UInt(wrap_at)), UInt(wrap_at))


def _maybe_convert_tabs(style: Style, var text: String) -> String:
    """Convert tabs to spaces if the tab width is set.

    Args:
        style: The style to use for the conversion.
        text: The text to convert tabs in.

    Returns:
        The text with tabs converted to spaces.
    """
    var DEFAULT_TAB_WIDTH: UInt16 = TAB_WIDTH
    if style.is_set[PropKey.TAB_WIDTH]():
        DEFAULT_TAB_WIDTH = style._tab_width

    if DEFAULT_TAB_WIDTH == -1:
        return text^

    if DEFAULT_TAB_WIDTH == 0:
        return text.replace("\t", "")
    else:
        return text.replace("\t", (WHITESPACE * Int(DEFAULT_TAB_WIDTH)))


def _style_border[origin: ImmOrigin, //](style: Style, border: StringSpan[origin], fg: AnyTerminalColor, bg: AnyTerminalColor) -> String:
    """Style a border with foreground and background colors.

    Args:
        style: The style to use for the border.
        border: The border to style.
        fg: The foreground color.
        bg: The background color.

    Returns:
        The styled border.
    """
    if fg.isa[NoColor]() and bg.isa[NoColor]():
        return String(border)

    return (
        style._renderer.as_mist_style()
        .foreground(color=fg.color(style._renderer))
        .background(color=bg.color(style._renderer))
        .render(border)
    )


def _apply_border[origin: ImmOrigin, //](style: Style, text: StringSpan[origin]) -> String:
    """Apply a border to the text.

    Args:
        style: The style to use for the border.
        text: The text to apply the border to.

    Returns:
        The text with the border applied.
    """
    # Checked before copying the border: the struct holds a string per edge and corner,
    # and the common case is having no border to apply at all.
    if style._border == NO_BORDER:
        return String(text)

    var top_set = style.is_set[PropKey.BORDER_TOP]()
    var right_set = style.is_set[PropKey.BORDER_RIGHT]()
    var bottom_set = style.is_set[PropKey.BORDER_BOTTOM]()
    var left_set = style.is_set[PropKey.BORDER_LEFT]()

    var border = style._border.copy()
    var has_top = style.check_if_border_side_will_render(Side.TOP)
    var has_right = style.check_if_border_side_will_render(Side.RIGHT)
    var has_bottom = style.check_if_border_side_will_render(Side.BOTTOM)
    var has_left = style.check_if_border_side_will_render(Side.LEFT)

    var is_no_border = border == NO_BORDER

    # If a border is set and no sides have been specifically turned on or off
    # render borders on all sides.
    if not is_no_border and not (top_set or right_set or bottom_set or left_set):
        has_top = True
        has_right = True
        has_bottom = True
        has_left = True

    # If no border is set or all borders are been disabled, abort.
    if is_no_border or (not has_top and not has_right and not has_bottom and not has_left):
        return String(text)

    var lines = text.split(NEWLINE)
    var width = get_widest_line(lines)
    if has_left:
        if border.left == "":
            border.left = " "
        width += printable_rune_width(border.left)

    if has_right and border.right == "":
        border.right = " "

    # If corners should be rendered but are set with the empty string, fill them
    # with a single space.
    if has_top and has_left and border.top_left == "":
        border.top_left = " "
    if has_top and has_right and border.top_right == "":
        border.top_right = " "
    if has_bottom and has_left and border.bottom_left == "":
        border.bottom_left = " "
    if has_bottom and has_right and border.bottom_right == "":
        border.bottom_right = " "

    # Figure out which corners we should actually be using based on which
    # sides are set to show.
    if has_top:
        if not has_left and not has_right:
            border.top_left = ""
            border.top_right = ""
        elif not has_left:
            border.top_left = ""
        elif not has_right:
            border.top_right = ""

    if has_bottom:
        if not has_left and not has_right:
            border.bottom_left = ""
            border.bottom_right = ""
        elif not has_left:
            border.bottom_left = ""
        elif not has_right:
            border.bottom_right = ""

    var result = String(capacity=Int(Float64(text.byte_length()) * 1.5))
    # Render top
    if has_top:
        result.write(
            _style_border(
                style,
                render_horizontal_edge(border.top_left, border.top, border.top_right, UInt(width)),
                style._border_color.foreground_top,
                style._border_color.background_top,
            ),
            NEWLINE,
        )

    # Render sides once, and reuse for each line.
    var left_border: String
    if has_left:
        left_border = _style_border(
            style, border.left, style._border_color.foreground_left, style._border_color.background_left
        )
    else:
        left_border = ""

    var right_border: String
    if has_right:
        right_border = _style_border(
            style, border.right, style._border_color.foreground_right, style._border_color.background_right
        )
    else:
        right_border = ""

    for i in range(len(lines)):
        if has_left:
            result.write(left_border)

        result.write(lines[i])

        if has_right:
            result.write(right_border)

        if i < len(lines) - 1:
            result.write(NEWLINE)

    # Render bottom
    if has_bottom:
        result.write(
            NEWLINE,
            _style_border(
                style,
                render_horizontal_edge(border.bottom_left, border.bottom, border.bottom_right, UInt(width)),
                style._border_color.foreground_bottom,
                style._border_color.background_bottom,
            ),
        )

    return result^


def _apply_margins[origin: ImmOrigin, //](style: Style, text: StringSpan[origin], inline: Bool) -> String:
    """Apply margins to the text.

    Args:
        style: The style to use for the margins.
        text: The text to apply the margins to.
        inline: Whether the text is inline or not.

    Returns:
        The text with the margins applied.
    """
    # With no margins on any side there is nothing to add, and the work below is not
    # free: it resolves the margin background into a mist style, then rebuilds the whole
    # string twice via `pad_left`/`pad_right`, then measures it.
    if (
        style._margin.left == 0
        and style._margin.right == 0
        and style._margin.top == 0
        and style._margin.bottom == 0
    ):
        return String(text)

    var styler = style._renderer.as_mist_style().background(
        color=style._margin.background.color(style._renderer)
    )

    # Add left and right margin
    var padded = pad_right(pad_left(text, Int(style._margin.left), styler), Int(style._margin.right), styler)

    # Top/bottom margin
    var top_margin = Int(style._margin.top)
    var bottom_margin = Int(style._margin.bottom)
    if not inline:
        var width = Int(get_widest_line(padded))
        if top_margin > 0:
            padded = String((WHITESPACE * width + NEWLINE) * top_margin, padded)
        if bottom_margin > 0:
            padded.write((NEWLINE + WHITESPACE * width) * bottom_margin)

    return padded^


def _get_styles(style: Style) -> Stylers:
    var base = style._renderer.as_mist_style()
    var stylers = Stylers(base.copy(), base.copy(), base.copy())

    if style.check_emphasis(Emphasis.BOLD):
        stylers.common = stylers.common.bold()
    if style.check_emphasis(Emphasis.ITALIC):
        stylers.common = stylers.common.italic()
    if style.check_emphasis(Emphasis.UNDERLINE):
        stylers.common = stylers.common.underline()
    if style.check_emphasis(Emphasis.REVERSE):
        stylers.common = stylers.common.reverse()
        stylers.whitespace = stylers.whitespace.reverse()
    if style.check_emphasis(Emphasis.BLINK):
        stylers.common = stylers.common.blink()
    if style.check_emphasis(Emphasis.FAINT):
        stylers.common = stylers.common.faint()
    if style.check_emphasis(Emphasis.STRIKETHROUGH):
        stylers.common = stylers.common.strikethrough()

    var fg_color = style._foreground.color(style._renderer)
    var bg_color = style._background.color(style._renderer)
    stylers.common = stylers.common.foreground(color=fg_color).background(color=bg_color)

    # Do we need to style spaces separately?
    var color_whitespace = style._check_attr[PropKey.COLOR_WHITESPACE](default=True)
    var underline = style.check_emphasis(Emphasis.UNDERLINE)
    var underline_spaces = style.check_emphasis(Emphasis.UNDERLINE_SPACES) or (
        underline and style._check_attr[PropKey.UNDERLINE_SPACES](default=True)
    )

    var strikethrough = style.check_emphasis(Emphasis.STRIKETHROUGH)
    var strikethrough_spaces = style.check_emphasis(Emphasis.STRIKETHROUGH_SPACES) or (
        strikethrough and style._check_attr[PropKey.STRIKETHROUGH_SPACES](default=True)
    )

    if underline_spaces or strikethrough_spaces:
        stylers.space = stylers.space.foreground(color=fg_color).background(color=bg_color)
    if color_whitespace:
        stylers.whitespace = stylers.whitespace.foreground(color=fg_color).background(color=bg_color)

    if underline_spaces:
        stylers.space = stylers.space.underline()
    if strikethrough_spaces:
        stylers.space = stylers.space.strikethrough()

    return stylers^


# TODO: When we have properties, use it for most of these attributes which are currently
# using leading underscore to not collide with the setter function.
struct Style(Writable, ImplicitlyCopyable):
    """Terminal styler.

    #### Usage:
    ```mojo
    import mog
    from mog import Emphasis, Padding

    def main():
        var style = (
            mog.Style(
                width=22,
                foreground=mog.Color(0xFAFAFA),
                background=mog.Color(0x7D56F4),
                emphasis=Emphasis.BOLD,
                padding=Padding(top=2, left=4),
            )
        )
        print(style.render("Hello, world"))
    ```
    More documentation to come.
    """

    var _renderer: Renderer
    """The renderer to use for the style, determines the color profile."""
    var _properties: Properties
    """List of attributes with 1 or 0 values to determine if a property is set.
    properties = is it set? _attrs = is it set to true or false? (for bool properties).
    """
    var _value: String
    """The string value to apply the style to. All rendered text will start with this value."""

    var _attrs: Properties
    """Stores the value of set bool properties here.
    Eg. Setting bool to to true on a style makes _attrs.has(BOOL_KEY) return true.
    """

    # props that have values
    var _foreground: AnyTerminalColor
    """The foreground color of the text area. IE: The color of the text itself."""
    var _background: AnyTerminalColor
    """The background color of the text area. IE: The color of the background behind the text."""
    var _height: UInt16
    """The height of the text area."""
    var _width: UInt16
    """The width of the text area."""
    var _max_height: UInt16
    """The height of the text area."""
    var _max_width: UInt16
    """The width of the text area."""
    var _tail: String
    """The tail to append to lines truncated by the max width rule."""
    var _alignment: Alignment
    """The alignment of the text."""
    var _padding: Padding
    """The padding levels."""
    var _margin: Margin
    """The margin levels."""

    var _border: Border
    """The border style."""
    var _border_color: BorderColor
    """The border colors."""

    var _tab_width: UInt16
    """The number of spaces that a tab (/t) should be rendered as."""

    def __init__(
        out self,
        renderer: Renderer,
        properties: Properties,
        var value: String,
        attrs: Properties,
        var foreground: AnyTerminalColor,
        var background: AnyTerminalColor,
        width: UInt16,
        height: UInt16,
        max_width: UInt16,
        max_height: UInt16,
        var tail: String,
        alignment: Alignment,
        padding: Padding,
        var margin: Margin,
        border: Border,
        var border_color: BorderColor,
        tab_width: UInt16,
    ):
        """Initialize A new Style.

        Args:
            renderer: The renderer to use for the style, determines the color profile.
            properties: List of attributes with 1 or 0 values to determine if a property is set.
            value: The string value to apply the style to. All rendered text will start with this value.
            attrs: Stores the value of set bool properties here.
            foreground: The coloring of the text.
            background: The coloring of the background of the text.
            width: TBD.
            height: TBD.
            max_width: TBD.
            max_height: TBD.
            tail: The tail to append to lines truncated by the max width rule.
            alignment: The alignment of the text.
            padding: The padding levels.
            margin: The margin levels.
            border: The border style.
            border_color: The border colors.
            tab_width: The number of spaces that a tab (/t) should be rendered as.
        """
        self._renderer = renderer
        self._properties = properties
        self._value = value
        self._attrs = attrs
        self._foreground = foreground^
        self._background = background^
        self._width = width
        self._height = height
        self._max_width = max_width
        self._max_height = max_height
        self._tail = tail^
        self._alignment = alignment
        self._padding = padding
        self._margin = margin
        self._border = border.copy()
        self._border_color = border_color
        self._tab_width = tab_width

    def __init__(
        out self,
        color_profile: Optional[mist.Profile] = None,
        *,
        width: Optional[Int] = None,
        height: Optional[Int] = None,
        max_width: Optional[Int] = None,
        max_height: Optional[Int] = None,
        var tail: String = "",
        foreground: AnyTerminalColor = NoColor(),
        background: AnyTerminalColor = NoColor(),
        border: Optional[Border] = None,
        var value: String = "",
        emphasis: Optional[Emphasis] = None,
        padding: Optional[Padding] = None,
        margin: Optional[Margin] = None,
        alignment: Optional[Alignment] = None,
    ):
        """Initialize A new Style.

        Args:
            color_profile: The renderer to use for the style, determines the color profile.
            width: TBD.
            height: TBD.
            max_width: TBD.
            max_height: TBD.
            tail: The tail to append to lines truncated by the max width rule.
            foreground: Color of the text in the text area the style renders.
            background: Color of the background in the text area the style renders.
            border: TBD.
            value: TBD.
            emphasis: TBD.
            padding: TBD.
            margin: TBD.
            alignment: TBD.
        """
        self._properties = Properties()
        self._attrs = Properties()
        self._renderer = Renderer(color_profile.value()) if color_profile else Renderer()
        self._value = value^
        self._alignment = Alignment()
        self._padding = Padding()
        self._margin = Margin()
        self._border_color = BorderColor()
        self._tab_width = 0
        self._width = 0
        self._height = 0
        self._max_width = 0
        self._max_height = 0
        self._tail = tail^
        self._foreground = NoColor()
        self._background = NoColor()
        self._border = NO_BORDER.copy()

        if width:
            self._width = UInt16(width.value())
            self._properties.set[PropKey.WIDTH](True)
        if height:
            self._height = UInt16(height.value())
            self._properties.set[PropKey.HEIGHT](True)

        if max_width:
            self._max_width = UInt16(max_width.value())
            self._properties.set[PropKey.MAX_WIDTH](True)
        if max_height:
            self._max_height = UInt16(max_height.value())
            self._properties.set[PropKey.MAX_HEIGHT](True)

        if not foreground.is_same_type(NoColor()):
            self._foreground = foreground
            self._properties.set[PropKey.FOREGROUND](True)
        if not background.is_same_type(NoColor()):
            self._background = background
            self._properties.set[PropKey.BACKGROUND](True)

        if border:
            self._border = border.value().copy()
            self._properties.set[PropKey.BORDER_STYLE](True)

            comptime for key in [PropKey.BORDER_TOP, PropKey.BORDER_RIGHT, PropKey.BORDER_BOTTOM, PropKey.BORDER_LEFT]:
                self._set_attribute[key](value=True)

        if emphasis:
            if emphasis == Emphasis.BOLD:
                self._set_attribute[PropKey.BOLD](True)
            elif emphasis == Emphasis.ITALIC:
                self._set_attribute[PropKey.ITALIC](True)
            elif emphasis == Emphasis.UNDERLINE:
                self._set_attribute[PropKey.UNDERLINE](True)
            elif emphasis == Emphasis.STRIKETHROUGH:
                self._set_attribute[PropKey.STRIKETHROUGH](True)
            elif emphasis == Emphasis.REVERSE:
                self._set_attribute[PropKey.REVERSE](True)
            elif emphasis == Emphasis.BLINK:
                self._set_attribute[PropKey.BLINK](True)
            elif emphasis == Emphasis.FAINT:
                self._set_attribute[PropKey.FAINT](True)
            elif emphasis == Emphasis.UNDERLINE_SPACES:
                self._set_attribute[PropKey.UNDERLINE_SPACES](True)
            elif emphasis == Emphasis.STRIKETHROUGH_SPACES:
                self._set_attribute[PropKey.STRIKETHROUGH_SPACES](True)
            elif emphasis == Emphasis.COLOR_WHITESPACE:
                self._set_attribute[PropKey.COLOR_WHITESPACE](True)

        if padding:
            self._padding = padding.value()
            self._properties.set[PropKey.PADDING_TOP](True)
            self._properties.set[PropKey.PADDING_RIGHT](True)
            self._properties.set[PropKey.PADDING_BOTTOM](True)
            self._properties.set[PropKey.PADDING_LEFT](True)

        if margin:
            self._margin = margin.value()
            self._properties.set[PropKey.MARGIN_TOP](True)
            self._properties.set[PropKey.MARGIN_RIGHT](True)
            self._properties.set[PropKey.MARGIN_BOTTOM](True)
            self._properties.set[PropKey.MARGIN_LEFT](True)

        if alignment:
            self._alignment = alignment.value()
            self._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)
            self._properties.set[PropKey.VERTICAL_ALIGNMENT](True)

    def _check_attr[key: PropKey](self, *, default: Bool = False) -> Bool:
        """Get a rule as a boolean value.

        Parameters:
            key: The key to get.

        Args:
            default: The default value to return if the rule is not set.

        Returns:
            The boolean value.
        """
        if not self.is_set[key]():
            return default

        return self._attrs.has[key]()

    def is_set[key: PropKey](self) -> Bool:
        """Check if a rule is set on the style.

        Parameters:
            key: The key to check.

        Returns:
            True if the rule is set, False otherwise.
        """
        return self._properties.has[key]()

    def _set_attribute[key: PropKey](mut self, value: Bool):
        """Set a boolean attribute on the style.

        Parameters:
            key: The key to set.

        Args:
            value: The value to set.
        """
        # Mark the attribute as active
        self._attrs.set[key](value)

        # Set the value
        self._properties.set[key](value)

    def _unset_attribute[key: PropKey](mut self):
        """Unset a boolean attribute on the style.

        Parameters:
            key: The key to set.
        """
        self._properties.set[key](False)

    def renderer(self, renderer: Renderer) -> Self:
        """Set the renderer for the style.

        Args:
            renderer: The renderer to set.

        Returns:
            A new Style with the renderer set.
        """
        var new = self.copy()
        new._renderer = renderer
        return new^

    def value(self, value: String) -> Self:
        """Set the string value for the style.

        Args:
            value: The string value to set.

        Returns:
            A new Style with the string value set.
        """
        var new = self.copy()
        new._value = value
        return new^

    def tab_width(self, width: UInt16) -> Self:
        """Sets the number of spaces that a tab (/t) should be rendered as.
        When set to 0, tabs will be removed. To disable the replacement of tabs with
        spaces entirely, set this to [NO_TAB_CONVERSION].

        By default, tabs will be replaced with 4 spaces.

        Args:
            width: The tab width to apply.

        Returns:
            A new Style with the tab width rule set.
        """
        var new = self.copy()
        new._tab_width = width
        new._properties.set[PropKey.TAB_WIDTH](True)
        return new^

    def unset_tab_width(self) -> Self:
        """Unset the tab width of the text.

        Returns:
            A new Style with the tab width rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.TAB_WIDTH]()
        return new^

    def inline(self, value: Bool = True) -> Self:
        """Makes rendering output one line and disables the rendering of
        margins, padding and borders. This is useful when you need a style to apply
        only to font rendering and don't want it to change any physical dimensions.
        It works well with `Style.max_width()`.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the bold rule set.

        #### Examples:
        ```mojo
        import mog

        def main():
            var input = "..."
            var style = mog.Style().inline()
            print(style.render(input))
        ```
        """
        var new = self.copy()
        new._set_attribute[PropKey.INLINE](value)
        return new^

    @always_inline
    def check_if_inline(self) -> Bool:
        """Returns whether or not the inline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._check_attr[PropKey.INLINE](default=False)

    def unset_inline(self) -> Self:
        """Unset the inline rule.

        Returns:
            A new Style with the inline rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.INLINE]()
        return new^

    def bold(self, value: Bool = True) -> Self:
        """Set the text to be bold.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the bold rule set.
        """
        return self.set_emphasis(Emphasis.BOLD, value=value)

    def unset_bold(self) -> Self:
        """Unset the bold text style.

        Returns:
            A new Style with the bold rule unset.
        """
        return self.unset_emphasis(Emphasis.BOLD)

    def italic(self, value: Bool = True) -> Self:
        """Set the text to be italicized.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the italic rule set.
        """
        return self.set_emphasis(Emphasis.ITALIC, value=value)

    def unset_italic(self) -> Self:
        """Unset the italic text style.

        Returns:
            A new Style with the italic rule unset.
        """
        return self.unset_emphasis(Emphasis.ITALIC)

    def underline(self, value: Bool = True) -> Self:
        """Set the text to be underlined.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the underline rule set.
        """
        return self.set_emphasis(Emphasis.UNDERLINE, value=value)

    def unset_underline(self) -> Self:
        """Unset the underline text style.

        Returns:
            A new Style with the underline rule unset.
        """
        return self.unset_emphasis(Emphasis.UNDERLINE)

    def strikethrough(self, value: Bool = True) -> Self:
        """Set the text to be strikethrough.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the strikethrough rule set.
        """
        return self.set_emphasis(Emphasis.STRIKETHROUGH, value=value)

    def unset_strikethrough(self) -> Self:
        """Unset the strikethrough text style.

        Returns:
            A new Style with the strikethrough rule unset.
        """
        return self.unset_emphasis(Emphasis.STRIKETHROUGH)

    def reverse(self, value: Bool = True) -> Self:
        """Set the text foreground and background colors to be reversed.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the reverse rule set.
        """
        return self.set_emphasis(Emphasis.REVERSE, value=value)

    def unset_reverse(self) -> Self:
        """Unset the reverse text style.

        Returns:
            A new Style with the reverse rule unset.
        """
        return self.unset_emphasis(Emphasis.REVERSE)

    def blink(self, value: Bool = True) -> Self:
        """Set the text to blink.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the blink rule set.
        """
        return self.set_emphasis(Emphasis.BLINK, value=value)

    def unset_blink(self) -> Self:
        """Unset the blink text style.

        Returns:
            A new Style with the blink rule unset.
        """
        return self.unset_emphasis(Emphasis.BLINK)

    def faint(self, value: Bool = True) -> Self:
        """Set the text to be faint.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the faint rule set.
        """
        return self.set_emphasis(Emphasis.FAINT, value=value)

    def unset_faint(self) -> Self:
        """Unset the faint text style.

        Returns:
            A new Style with the faint rule unset.
        """
        return self.unset_emphasis(Emphasis.FAINT)

    def underline_spaces(self, value: Bool = True) -> Self:
        """Set the text to have spaces underlined.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the underline spaces rule set.
        """
        return self.set_emphasis(Emphasis.UNDERLINE_SPACES, value=value)

    def unset_underline_spaces(self) -> Self:
        """Unset the underline spaces text style.

        Returns:
            A new Style with the underline spaces rule unset.
        """
        return self.unset_emphasis(Emphasis.UNDERLINE_SPACES)

    def strikethrough_spaces(self, value: Bool = True) -> Self:
        """Set the text to have spaces strikethrough.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the strikethrough spaces rule set.
        """
        return self.set_emphasis(Emphasis.STRIKETHROUGH_SPACES, value=value)

    def unset_strikethrough_spaces(self) -> Self:
        """Unset the strikethrough spaces text style.

        Returns:
            A new Style with the strikethrough spaces rule unset.
        """
        return self.unset_emphasis(Emphasis.STRIKETHROUGH_SPACES)

    def color_whitespace(self, value: Bool = True) -> Self:
        """Set the text to have colored whitespace.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the color whitespace rule set.
        """
        return self.set_emphasis(Emphasis.COLOR_WHITESPACE, value=value)

    def unset_color_whitespace(self) -> Self:
        """Unset the color whitespace text style.

        Returns:
            A new Style with the color whitespace rule unset.
        """
        return self.unset_emphasis(Emphasis.COLOR_WHITESPACE)

    def set_emphasis(self, style: Emphasis, *, value: Bool = True) -> Self:
        """Set the text style.

        Args:
            style: The style to set.
            value: Value to set the rule to.

        Returns:
            A new Style with the text style set.
        """
        var new = self.copy()

        # TODO: Exhaustive match when supported
        if style == Emphasis.BOLD:
            new._set_attribute[PropKey.BOLD](value)
        elif style == Emphasis.ITALIC:
            new._set_attribute[PropKey.ITALIC](value)
        elif style == Emphasis.UNDERLINE:
            new._set_attribute[PropKey.UNDERLINE](value)
        elif style == Emphasis.STRIKETHROUGH:
            new._set_attribute[PropKey.STRIKETHROUGH](value)
        elif style == Emphasis.REVERSE:
            new._set_attribute[PropKey.REVERSE](value)
        elif style == Emphasis.BLINK:
            new._set_attribute[PropKey.BLINK](value)
        elif style == Emphasis.FAINT:
            new._set_attribute[PropKey.FAINT](value)
        elif style == Emphasis.UNDERLINE_SPACES:
            new._set_attribute[PropKey.UNDERLINE_SPACES](value)
        elif style == Emphasis.STRIKETHROUGH_SPACES:
            new._set_attribute[PropKey.STRIKETHROUGH_SPACES](value)
        elif style == Emphasis.COLOR_WHITESPACE:
            new._set_attribute[PropKey.COLOR_WHITESPACE](value)

        return new^

    def unset_emphasis(self, style: Emphasis) -> Self:
        """Unset the text style.

        Args:
            style: The style to set.

        Returns:
            A new Style with the text style set.
        """
        var new = self.copy()

        # TODO: Exhaustive match when supported
        if style == Emphasis.BOLD:
            new._unset_attribute[PropKey.BOLD]()
        elif style == Emphasis.ITALIC:
            new._unset_attribute[PropKey.ITALIC]()
        elif style == Emphasis.UNDERLINE:
            new._unset_attribute[PropKey.UNDERLINE]()
        elif style == Emphasis.STRIKETHROUGH:
            new._unset_attribute[PropKey.STRIKETHROUGH]()
        elif style == Emphasis.REVERSE:
            new._unset_attribute[PropKey.REVERSE]()
        elif style == Emphasis.BLINK:
            new._unset_attribute[PropKey.BLINK]()
        elif style == Emphasis.FAINT:
            new._unset_attribute[PropKey.FAINT]()
        elif style == Emphasis.UNDERLINE_SPACES:
            new._unset_attribute[PropKey.UNDERLINE_SPACES]()
        elif style == Emphasis.STRIKETHROUGH_SPACES:
            new._unset_attribute[PropKey.STRIKETHROUGH_SPACES]()
        elif style == Emphasis.COLOR_WHITESPACE:
            new._unset_attribute[PropKey.COLOR_WHITESPACE]()

        return new^

    def check_emphasis(self, style: Emphasis) -> Bool:
        """Checks if the text style is currently set and the value is.

        Args:
            style: The style to check.

        Returns:
            Whether or not the style is set.
        """
        if style == Emphasis.BOLD:
            return self._check_attr[PropKey.BOLD](default=False)
        elif style == Emphasis.ITALIC:
            return self._check_attr[PropKey.ITALIC](default=False)
        elif style == Emphasis.UNDERLINE:
            return self._check_attr[PropKey.UNDERLINE](default=False)
        elif style == Emphasis.STRIKETHROUGH:
            return self._check_attr[PropKey.STRIKETHROUGH](default=False)
        elif style == Emphasis.REVERSE:
            return self._check_attr[PropKey.REVERSE](default=False)
        elif style == Emphasis.BLINK:
            return self._check_attr[PropKey.BLINK](default=False)
        elif style == Emphasis.FAINT:
            return self._check_attr[PropKey.FAINT](default=False)
        elif style == Emphasis.UNDERLINE_SPACES:
            return self._check_attr[PropKey.UNDERLINE_SPACES](default=False)
        elif style == Emphasis.STRIKETHROUGH_SPACES:
            return self._check_attr[PropKey.STRIKETHROUGH_SPACES](default=False)
        elif style == Emphasis.COLOR_WHITESPACE:
            return self._check_attr[PropKey.COLOR_WHITESPACE](default=False)

        # TODO: Exhaustive match when supported
        return False

    def width(self, width: UInt16) -> Self:
        """Set the width of the text.

        Args:
            width: The width to apply.

        Returns:
            A new Style with the width rule set.

        #### Notes:
        If you need width to be truncated to obey the width rule, use `Style.max_width()` instead.
        """
        var new = self.copy()
        new._width = width
        new._properties.set[PropKey.WIDTH](True)
        return new^

    def unset_width(self) -> Self:
        """Unset the width of the text.

        Returns:
            A new Style with the width rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.WIDTH]()
        return new^

    def height(self, height: UInt16) -> Self:
        """Set the height of the text.
        If the height of the text being styled is greater than height, then this is a noop.

        Args:
            height: The height to apply.

        Returns:
            A new Style with the height rule set.

        #### Notes:
        If you need height to be truncated to obey the height rule, use `Style.max_height()` instead.
        """
        var new = self.copy()
        new._height = height
        new._properties.set[PropKey.HEIGHT](True)
        return new^

    def unset_height(self) -> Self:
        """Unset the height of the text.

        Returns:
            A new Style with the height rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.HEIGHT]()
        return new^

    def max_width(self, width: UInt16, var tail: String = "") -> Self:
        """Applies a max width to a given style. This enforces a max width of a line by truncating lines that are too long,
        and will pad all lines to the width of the widest line.

        Args:
            width: The maximum height to apply.
            tail: Appended to each line that gets truncated, eg. an ellipsis. It is included in
                the max width, so the truncated line plus the tail is at most `width` cells wide.

        Returns:
            A new Style with the maximum width rule set.

        #### Notes:
        This does **NOT** pad the lines to the max width, if you want to pad all lines to the width given use `Style.width()` instead.

        #### Examples:
        ```mojo
        import mog

        def main():
            var user_input = "..."
            var user_style = mog.Style().max_width(16)
            print(user_style.render(user_input))
        ```
        """
        var new = self.copy()
        new._max_width = width
        new._tail = tail^
        new._properties.set[PropKey.MAX_WIDTH](True)
        return new^

    def unset_max_width(self) -> Self:
        """Unset the max width of the text.

        Returns:
            A new Style with the max width rule unset.
        """
        var new = self.copy()
        new._tail = String()
        new._unset_attribute[PropKey.MAX_WIDTH]()
        return new^

    def max_height(self, height: UInt16) -> Self:
        """Set the maximum height of the text.
        This enforces a max height by only rendering the first n lines.

        Args:
            height: The maximum height to apply.

        Returns:
            A new Style with the maximum height rule set.

        #### Notes:
        This does **NOT** pad the lines to the max height, if you want to pad all lines to the height given use `Style.height()` instead.
        """
        var new = self.copy()
        new._max_height = height
        new._properties.set[PropKey.MAX_HEIGHT](True)
        return new^

    def unset_max_height(self) -> Self:
        """Unset the max height of the text.

        Returns:
            A new Style with the max height rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MAX_HEIGHT]()
        return new^

    def text_alignment(self, align: Position) -> Self:
        """Set the horizontal and vertical alignment of the text in the text area.

        Args:
            align: The alignment value to apply from 0 to 1.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()
        new._alignment.horizontal = align
        new._alignment.vertical = align
        new._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)
        new._properties.set[PropKey.VERTICAL_ALIGNMENT](True)
        return new^

    def text_alignment(self, horizontal: Position, vertical: Position) -> Self:
        """Set the horizontal and vertical alignment of the text in the text area.

        Args:
            horizontal: The horizontal alignment value to apply from 0 to 1.
            vertical: The vertical alignment value to apply from 0 to 1.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()
        new._alignment.horizontal = horizontal
        new._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)

        new._alignment.vertical = vertical
        new._properties.set[PropKey.VERTICAL_ALIGNMENT](True)
        return new^

    def text_alignment(self, axis: Axis, align: Position) -> Self:
        """Set the horizontal or vertical alignment of the text in the text area.

        Args:
            axis: The axis to set the alignment for.
            align: The alignment value to apply from 0 to 1.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()

        if axis == Axis.HORIZONTAL:
            new._alignment.horizontal = align
            new._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)
        elif axis == Axis.VERTICAL:
            new._alignment.vertical = align
            new._properties.set[PropKey.VERTICAL_ALIGNMENT](True)
        return new^

    def unset_text_alignment(self, axis: Axis) -> Self:
        """Unset the text alignment for a specific axis.

        Args:
            axis: The axis to unset the alignment for.

        Returns:
            A new Style with the alignment rules unset.
        """
        var new = self.copy()
        if axis == Axis.HORIZONTAL:
            new._unset_attribute[PropKey.HORIZONTAL_ALIGNMENT]()
        elif axis == Axis.VERTICAL:
            new._unset_attribute[PropKey.VERTICAL_ALIGNMENT]()
        return new^

    def foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the foreground color rule set.
        """
        var new = self.copy()
        new._foreground = color^
        new._properties.set[PropKey.FOREGROUND](True)
        return new^

    def unset_foreground(self) -> Self:
        """Unset the foreground color of the text.

        Returns:
            A new Style with the foreground color rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.FOREGROUND]()
        return new^

    def background(self, var color: AnyTerminalColor) -> Self:
        """Set the background color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the background color rule set.
        """
        var new = self.copy()
        new._background = color^
        new._properties.set[PropKey.BACKGROUND](True)
        return new^

    def unset_background(self) -> Self:
        """Unset the background color of the text.

        Returns:
            A new Style with the background color rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.BACKGROUND]()
        return new^

    def border(self, var border: Border) -> Self:
        """Sets the border style to use.

        Args:
            border: The Border style to apply.

        Returns:
            A new Style with the border style set.
        """
        var new = self.copy()
        new._border = border^
        new._properties.set[PropKey.BORDER_STYLE](True)
        new._set_attribute[PropKey.BORDER_TOP](True)
        new._set_attribute[PropKey.BORDER_RIGHT](True)
        new._set_attribute[PropKey.BORDER_BOTTOM](True)
        new._set_attribute[PropKey.BORDER_LEFT](True)
        return new^

    def border_side_rendering(
        self,
        *,
        top: Optional[Bool] = None,
        right: Optional[Bool] = None,
        bottom: Optional[Bool] = None,
        left: Optional[Bool] = None,
    ) -> Self:
        """Sets the sides of the border to render or not.

        Args:
            top: Whether or not the top border side should render.
            right: Whether or not the right border side should render.
            bottom: Whether or not the bottom border side should render.
            left: Whether or not the left border side should render.

        Returns:
            A new Style with the border rules set.
        """
        var new = self.copy()
        if top:
            new._set_attribute[PropKey.BORDER_TOP](top.value())

        if right:
            new._set_attribute[PropKey.BORDER_RIGHT](right.value())

        if bottom:
            new._set_attribute[PropKey.BORDER_BOTTOM](bottom.value())

        if left:
            new._set_attribute[PropKey.BORDER_LEFT](left.value())
        return new^

    def unset_border_side_rendering(
        self,
        *,
        top: Bool = False,
        right: Bool = False,
        bottom: Bool = False,
        left: Bool = False,
    ) -> Self:
        """Unsets the border rule for the sides specified.

        Args:
            top: If True, the rule for rendering the top border will be unset.
            right: If True, the rule for rendering the right border will be unset.
            bottom: If True, the rule for rendering the bottom border will be unset.
            left: If True, the rule for rendering the left border will be unset.

        Returns:
            A new Style with the border rules set.
        """
        var new = self.copy()
        if top:
            new._unset_attribute[PropKey.BORDER_TOP]()

        if right:
            new._unset_attribute[PropKey.BORDER_RIGHT]()

        if bottom:
            new._unset_attribute[PropKey.BORDER_BOTTOM]()

        if left:
            new._unset_attribute[PropKey.BORDER_LEFT]()
        return new^

    def check_if_border_side_will_render(self, side: Side) -> Bool:
        """Returns whether or not the border rule is set.

        Args:
            side: The side of the border to return the color for.

        Returns:
            True if set, False otherwise.
        """
        if side == Side.TOP:
            return self._check_attr[PropKey.BORDER_TOP](default=False)
        elif side == Side.RIGHT:
            return self._check_attr[PropKey.BORDER_RIGHT](default=False)
        elif side == Side.BOTTOM:
            return self._check_attr[PropKey.BORDER_BOTTOM](default=False)
        elif side == Side.LEFT:
            return self._check_attr[PropKey.BORDER_LEFT](default=False)

        # TODO: Remove this when we have enums and exhaustive matching.
        return False

    def border_foreground(self, *colors: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            colors: The color to apply.

        Returns:
            A new Style with the border foreground color rule set.

        #### Notes:
        The colors are applied in the order of top, right, bottom, left.
        * If one color is passed, it is applied to all sides.
        * If two colors are passed, the first is applied to the top and bottom, and the second to the left and right.
        * If three colors are passed, the first is applied to the top, the second to the left and right, and the third to the bottom.
        * If four colors are passed, the first is applied to the top, the second to the right, the third to the bottom, and the fourth to the left.
        """
        var new = self.copy()
        var colors_provided = len(colors)
        if colors_provided == 1:
            new._border_color.foreground_top = colors[0].copy()
            new._border_color.foreground_bottom = colors[0].copy()
            new._border_color.foreground_left = colors[0].copy()
            new._border_color.foreground_right = colors[0].copy()
        elif colors_provided == 2:
            new._border_color.foreground_top = colors[0].copy()
            new._border_color.foreground_bottom = colors[0].copy()
            new._border_color.foreground_left = colors[1].copy()
            new._border_color.foreground_right = colors[1].copy()
        elif colors_provided == 3:
            new._border_color.foreground_top = colors[0].copy()
            new._border_color.foreground_left = colors[1].copy()
            new._border_color.foreground_right = colors[1].copy()
            new._border_color.foreground_bottom = colors[2].copy()
        elif colors_provided == 4:
            new._border_color.foreground_top = colors[0].copy()
            new._border_color.foreground_right = colors[1].copy()
            new._border_color.foreground_bottom = colors[2].copy()
            new._border_color.foreground_left = colors[3].copy()
        else:
            return new^

        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    def border_top_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the top border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new._border_color.foreground_top = color^
        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)
        return new^

    def border_right_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the right border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new._border_color.foreground_right = color^
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)
        return new^

    def border_bottom_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the bottom border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new._border_color.foreground_bottom = color^
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)
        return new^

    def border_left_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the left border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new._border_color.foreground_left = color^
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    def border_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color for all sides of the border.

        Args:
            color: The color to apply to all sides of the border.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new._border_color.foreground_top = color.copy()
        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)

        new._border_color.foreground_right = color.copy()
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)

        new._border_color.foreground_bottom = color.copy()
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)

        new._border_color.foreground_left = color.copy()
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    def border_foreground(self, top_bottom_color: AnyTerminalColor, left_right_color: AnyTerminalColor) -> Self:
        """Set the border foreground color for all sides of the border.

        Args:
            top_bottom_color: The color to apply to the top and bottom sides of the border.
            left_right_color: The color to apply to the left and right sides of the border.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new._border_color.foreground_top = top_bottom_color
        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)

        new._border_color.foreground_right = left_right_color
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)

        new._border_color.foreground_bottom = top_bottom_color
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)

        new._border_color.foreground_left = left_right_color
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    def unset_border_foreground(
        self,
        *,
        top: Bool = False,
        right: Bool = False,
        bottom: Bool = False,
        left: Bool = False,
    ) -> Self:
        """Set the border foreground color.

        Args:
            top: If True, the border top foreground rule is unset.
            right: If True, the border top foreground rule is unset.
            bottom: If True, the border top foreground rule is unset.
            left: If True, the border top foreground rule is unset.

        Returns:
            A new Style with the border foreground color rules unset.
        """
        if not top and not right and not bottom and not left:
            return self.copy()

        var new = self.copy()
        if top:
            new._unset_attribute[PropKey.BORDER_TOP_FOREGROUND]()

        if right:
            new._unset_attribute[PropKey.BORDER_RIGHT_FOREGROUND]()

        if bottom:
            new._unset_attribute[PropKey.BORDER_BOTTOM_FOREGROUND]()

        if left:
            new._unset_attribute[PropKey.BORDER_LEFT_FOREGROUND]()
        return new^

    def border_background(self, *colors: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            colors: The color to apply.

        Returns:
            A new Style with the border background color rule set.

        #### Notes:
        The colors are applied in the order of top, right, bottom, left.
        * If one color is passed, it is applied to all sides.
        * If two colors are passed, the first is applied to the top and bottom, and the second to the left and right.
        * If three colors are passed, the first is applied to the top, the second to the left and right, and the third to the bottom.
        * If four colors are passed, the first is applied to the top, the second to the right, the third to the bottom, and the fourth to the left.
        """
        var new = self.copy()
        var colors_provided = len(colors)
        if colors_provided == 1:
            new._border_color.background_top = colors[0].copy()
            new._border_color.background_bottom = colors[0].copy()
            new._border_color.background_left = colors[0].copy()
            new._border_color.background_right = colors[0].copy()
        elif colors_provided == 2:
            new._border_color.background_top = colors[0].copy()
            new._border_color.background_bottom = colors[0].copy()
            new._border_color.background_left = colors[1].copy()
            new._border_color.background_right = colors[1].copy()
        elif colors_provided == 3:
            new._border_color.background_top = colors[0].copy()
            new._border_color.background_left = colors[1].copy()
            new._border_color.background_right = colors[1].copy()
            new._border_color.background_bottom = colors[2].copy()
        elif colors_provided == 4:
            new._border_color.background_top = colors[0].copy()
            new._border_color.background_right = colors[1].copy()
            new._border_color.background_bottom = colors[2].copy()
            new._border_color.background_left = colors[3].copy()
        else:
            return new^

        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    # TODO: Can't have a catchall set_border_background def because Optional[Variant] does not work.
    def border_top_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the top border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new._border_color.background_top = color^
        new._properties.set[PropKey.BORDER_TOP_BACKGROUND](True)
        return new^

    def border_bottom_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the bottom border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new._border_color.background_bottom = color^
        new._properties.set[PropKey.BORDER_BOTTOM_BACKGROUND](True)
        return new^

    def border_left_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the left border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new._border_color.background_left = color^
        new._properties.set[PropKey.BORDER_LEFT_BACKGROUND](True)
        return new^

    def border_right_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the right border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new._border_color.background_right = color^
        new._properties.set[PropKey.BORDER_RIGHT_BACKGROUND](True)
        return new^

    def border_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color for all sides of the border.

        Args:
            color: The color to apply to all sides of the border.

        Returns:
            A new Style with the border background color rules set.
        """
        var new = self.copy()
        new._border_color.background_top = color.copy()
        new._properties.set[PropKey.BORDER_TOP_BACKGROUND](True)

        new._border_color.background_right = color.copy()
        new._properties.set[PropKey.BORDER_RIGHT_BACKGROUND](True)

        new._border_color.background_bottom = color.copy()
        new._properties.set[PropKey.BORDER_BOTTOM_BACKGROUND](True)

        new._border_color.background_left = color.copy()
        new._properties.set[PropKey.BORDER_LEFT_BACKGROUND](True)
        return new^

    def unset_border_background(
        self,
        *,
        top: Bool = False,
        right: Bool = False,
        bottom: Bool = False,
        left: Bool = False,
    ) -> Self:
        """Set the border background color.

        Args:
            top: If True, the border top background rule is unset.
            right: If True, the border right background rule is unset.
            bottom: If True, the border bottom background rule is unset.
            left: If True, the border left background rule is unset.

        Returns:
            A new Style with the border background color rules unset.
        """
        if not top and not right and not bottom and not left:
            return self.copy()

        var new = self.copy()
        if top:
            new._unset_attribute[PropKey.BORDER_TOP_BACKGROUND]()

        if right:
            new._unset_attribute[PropKey.BORDER_RIGHT_BACKGROUND]()

        if bottom:
            new._unset_attribute[PropKey.BORDER_BOTTOM_BACKGROUND]()

        if left:
            new._unset_attribute[PropKey.BORDER_LEFT_BACKGROUND]()
        return new^

    def padding(
        self,
        *,
        top: Optional[Int] = None,
        right: Optional[Int] = None,
        bottom: Optional[Int] = None,
        left: Optional[Int] = None,
    ) -> Self:
        """Shorthand method for setting padding on all sides at once.

        Args:
            top: The padding width for the top side of the block.
            right: The padding width for the right side of the block.
            bottom: The padding width for the bottom side of the block.
            left: The padding width for the left side of the block.

        Returns:
            A new Style with the padding width set.

        #### Notes:
        * Padding is applied inside the text area, inside of the border if there is one.
        * Margin is applied outside the text area, outside of the border if there is one.
        """
        if not top and not right and not bottom and not left:
            return self.copy()

        var new = self.copy()
        if top:
            new._padding.top = UInt16(top.value())
            new._properties.set[PropKey.PADDING_TOP](True)

        if right:
            new._padding.right = UInt16(right.value())
            new._properties.set[PropKey.PADDING_RIGHT](True)

        if bottom:
            new._padding.bottom = UInt16(bottom.value())
            new._properties.set[PropKey.PADDING_BOTTOM](True)

        if left:
            new._padding.left = UInt16(left.value())
            new._properties.set[PropKey.PADDING_LEFT](True)
        return new^

    def padding(self, width: UInt16) -> Self:
        """Sets padding width for all sides of the text area.

        Args:
            width: The padding width for all sides of the text area.

        Returns:
            A new Style with the padding width set.

        #### Notes:
        * Padding is applied inside the text area, inside of the border if there is one.
        * Margin is applied outside the text area, outside of the border if there is one.
        """
        var new = self.copy()
        new._padding.top = UInt16(width)
        new._properties.set[PropKey.PADDING_TOP](True)

        new._padding.right = UInt16(width)
        new._properties.set[PropKey.PADDING_RIGHT](True)

        new._padding.bottom = UInt16(width)
        new._properties.set[PropKey.PADDING_BOTTOM](True)

        new._padding.left = UInt16(width)
        new._properties.set[PropKey.PADDING_LEFT](True)
        return new^

    def padding(self, top_bottom_width: UInt16, left_right_width: UInt16) -> Self:
        """Sets padding width for all sides of the text area.

        Args:
            top_bottom_width: The padding width for the top and bottom sides of the text area.
            left_right_width: The padding width for the left and right sides of the text area.

        Returns:
            A new Style with the padding width set.

        #### Notes:
        * Padding is applied inside the text area, inside of the border if there is one.
        * Margin is applied outside the text area, outside of the border if there is one.
        """
        var new = self.copy()
        new._padding.top = UInt16(top_bottom_width)
        new._properties.set[PropKey.PADDING_TOP](True)

        new._padding.bottom = UInt16(top_bottom_width)
        new._properties.set[PropKey.PADDING_BOTTOM](True)

        new._padding.left = UInt16(left_right_width)
        new._properties.set[PropKey.PADDING_LEFT](True)

        new._padding.right = UInt16(left_right_width)
        new._properties.set[PropKey.PADDING_RIGHT](True)
        return new^

    def unset_padding(
        self,
        *,
        top: Bool = False,
        right: Bool = False,
        bottom: Bool = False,
        left: Bool = False,
    ) -> Self:
        """Unsets the padding rules for the sides provided.

        Args:
            top: If True, the top padding rule is unset.
            right: If True, the right padding rule is unset.
            bottom: If True, the bottom padding rule is unset.
            left: If True, the left padding rule is unset.

        Returns:
            A new Style with the padding rules unset.
        """
        if not top and not right and not bottom and not left:
            return self.copy()

        var new = self.copy()
        if top:
            new._unset_attribute[PropKey.PADDING_TOP]()

        if right:
            new._unset_attribute[PropKey.PADDING_RIGHT]()

        if bottom:
            new._unset_attribute[PropKey.PADDING_BOTTOM]()

        if left:
            new._unset_attribute[PropKey.PADDING_LEFT]()
        return new^

    def margin(
        self,
        *,
        top: Optional[Int] = None,
        right: Optional[Int] = None,
        bottom: Optional[Int] = None,
        left: Optional[Int] = None,
    ) -> Self:
        """Shorthand method for setting margin on all sides at once.

        Args:
            top: The margin width for the top side of the block.
            right: The margin width for the right side of the block.
            bottom: The margin width for the bottom side of the block.
            left: The margin width for the left side of the block.

        Returns:
            A new Style with the margin width set.

        #### Notes:
        * Padding is applied inside the text area, inside of the border if there is one.
        * Margin is applied outside the text area, outside of the border if there is one.
        """
        var new = self.copy()
        if top:
            new._margin.top = UInt16(top.value())
            new._properties.set[PropKey.MARGIN_TOP](True)

        if right:
            new._margin.right = UInt16(right.value())
            new._properties.set[PropKey.MARGIN_RIGHT](True)

        if bottom:
            new._margin.bottom = UInt16(bottom.value())
            new._properties.set[PropKey.MARGIN_BOTTOM](True)

        if left:
            new._margin.left = UInt16(left.value())
            new._properties.set[PropKey.MARGIN_LEFT](True)
        return new^

    def margin(self, width: UInt16) -> Self:
        """Sets margin width for all sides of the text area.

        Args:
            width: The margin width for all sides of the text area.

        Returns:
            A new Style with the margin width set.

        #### Notes:
        * Padding is applied inside the text area, inside of the border if there is one.
        * Margin is applied outside the text area, outside of the border if there is one.
        """
        var new = self.copy()
        new._margin.top = UInt16(width)
        new._properties.set[PropKey.MARGIN_TOP](True)

        new._margin.right = UInt16(width)
        new._properties.set[PropKey.MARGIN_RIGHT](True)

        new._margin.bottom = UInt16(width)
        new._properties.set[PropKey.MARGIN_BOTTOM](True)

        new._margin.left = UInt16(width)
        new._properties.set[PropKey.MARGIN_LEFT](True)
        return new^

    def margin(self, top_bottom_width: UInt16, left_right_width: UInt16) -> Self:
        """Sets margin width for all sides of the text area.

        Args:
            top_bottom_width: The margin width for the top and bottom sides of the text area.
            left_right_width: The margin width for the left and right sides of the text area.

        Returns:
            A new Style with the margin width set.

        #### Notes:
        * Padding is applied inside the text area, inside of the border if there is one.
        * Margin is applied outside the text area, outside of the border if there is one.
        """
        var new = self.copy()
        new._margin.top = UInt16(top_bottom_width)
        new._properties.set[PropKey.MARGIN_TOP](True)

        new._margin.bottom = UInt16(top_bottom_width)
        new._properties.set[PropKey.MARGIN_BOTTOM](True)

        new._margin.left = UInt16(left_right_width)
        new._properties.set[PropKey.MARGIN_LEFT](True)

        new._margin.right = UInt16(left_right_width)
        new._properties.set[PropKey.MARGIN_RIGHT](True)
        return new^

    def unset_margin(
        self,
        *,
        top: Bool = False,
        right: Bool = False,
        bottom: Bool = False,
        left: Bool = False,
    ) -> Self:
        """Unset the margin rules for the provided sides.

        Args:
            top: If True, the top margin rule is unset.
            right: If True, the right margin rule is unset.
            bottom: If True, the bottom margin rule is unset.
            left: If True, the left margin rule is unset.

        Returns:
            A new Style with the margin rules unset.
        """
        if not top and not right and not bottom and not left:
            return self.copy()

        var new = self.copy()
        if top:
            new._unset_attribute[PropKey.MARGIN_TOP]()

        if right:
            new._unset_attribute[PropKey.MARGIN_RIGHT]()

        if bottom:
            new._unset_attribute[PropKey.MARGIN_BOTTOM]()

        if left:
            new._unset_attribute[PropKey.MARGIN_LEFT]()
        return new^

    def margin_background(self, var color: AnyTerminalColor) -> Self:
        """Set the margin on the background color.

        Args:
            color: The margin width to apply.

        Returns:
            A new Style with the margin background rule set.
        """
        var new = self.copy()
        new._margin.background = color^
        new._properties.set[PropKey.MARGIN_BACKGROUND](True)
        return new^

    def unset_margin_background(self) -> Self:
        """Unset the margin background rule.

        Returns:
            A new Style with the margin background rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MARGIN_BACKGROUND]()
        return new^

    def uses_space_styler(self) -> Bool:
        """Returns whether or not the style uses the space styler.

        Returns:
            True if the style uses the space styler, False otherwise.
        """
        var underline = self.check_emphasis(Emphasis.UNDERLINE)
        var underline_spaces = self.check_emphasis(Emphasis.UNDERLINE_SPACES) or (
            underline and self._check_attr[PropKey.UNDERLINE_SPACES](default=True)
        )

        var strikethrough = self.check_emphasis(Emphasis.STRIKETHROUGH)
        var strikethrough_spaces = self.check_emphasis(Emphasis.STRIKETHROUGH_SPACES) or (
            strikethrough and self._check_attr[PropKey.STRIKETHROUGH_SPACES](default=True)
        )

        return underline_spaces or strikethrough_spaces

    def affects_layout(self) -> Bool:
        """Whether rendering with this style can change the printable size of the text.

        Colour and emphasis wrap the text in escape sequences, which measure as zero
        cells, so they leave the size alone. Everything that adds or removes cells does:
        geometry, padding, margins, borders, truncation, a prefix value, or dropping
        newlines for an inline render.

        Callers that only need the rendered dimensions can measure the text directly
        when this is False, instead of rendering it to find out.

        Returns:
            True if a render could change the text's width or height.

        #### Notes:
        Tabs are not covered here. They are expanded during a render, so a caller
        taking the shortcut must rule them out separately.
        """
        if self._value != "":
            return True

        return (
            self._width > 0
            or self._height > 0
            or self._max_width > 0
            or self._max_height > 0
            or self._padding != Padding()
            or self._margin.top > 0
            or self._margin.right > 0
            or self._margin.bottom > 0
            or self._margin.left > 0
            or self._border != NO_BORDER
            or self.check_if_inline()
        )

    def render[*Ts: Writable, W: Writer](self, *texts: *Ts, mut writer: W, separator: StringSpan = " "):
        """Creates a `Style` with the text provided.

        Parameters:
            Ts: The types of the arguments that implement the Writable Trait.
            W: The type of the writer.

        Args:
            texts: The strings to render.
            writer: The writer to write to.
            separator: The separator to use when joining `texts`
        """
        # If style has internal string, add it first. Join arbitrary list of texts into a single string.
        var input_text = self._value.copy()
        comptime for i in range(texts.__len__()):
            input_text.write(texts[i])
            if i != len(texts) - 1:
                input_text.write(separator)

        var reverse = self.check_emphasis(Emphasis.REVERSE)
        var color_whitespace = self._check_attr[PropKey.COLOR_WHITESPACE](default=True)

        # If no style properties are set, return the input text as is with tabs maybe converted.
        if not any(self._properties.value):
            writer.write(_maybe_convert_tabs(self, input_text))
            return

        var inline = self.check_if_inline()
        if inline:
            input_text = input_text.replace(NEWLINE, "")

        # Word wrap
        # force-wrap long strings
        if not inline and (self._width > 0):
            input_text = _wrap_words(input_text, self._width, self._padding.left, self._padding.right)

        var stylers = _get_styles(self)
        var result = _apply_styles(_maybe_convert_tabs(self, input_text), self.uses_space_styler(), stylers)
        # Do we need to style whitespace (padding and space outside paragraphs) separately?
        var use_whitespace_styler = reverse

        # Padding
        if not inline:
            if self._padding.left > 0:
                var style = self._renderer.as_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = stylers.whitespace.copy()
                result = pad_left(result, Int(self._padding.left), style)

            if self._padding.right > 0:
                var style = self._renderer.as_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = stylers.whitespace.copy()
                result = pad_right(result, Int(self._padding.right), style)

            if self._padding.top > 0:
                result = String(NEWLINE * Int(self._padding.top), result^)

            if self._padding.bottom > 0:
                result.write(NEWLINE * Int(self._padding.bottom))

        # Alignment
        var height = self._height
        if height > 0:
            var alignment = self._alignment.vertical if self.is_set[PropKey.VERTICAL_ALIGNMENT]() else Position(0)
            result = align_text_vertical(result, alignment, height)

        # Aligning also pads every line out to the width of the widest one, so it runs for
        # more than just an explicit alignment. The one case with nothing to do is a single
        # line with no width to fill: there is no other line to match, and no target width.
        # (`get_widest_line(result) != 0` here used to stand in for "has more than one
        # line", but it is true of any non-empty text, so this never got skipped.)
        if self._width != 0 or NEWLINE in result:
            var style: mist.Style
            if color_whitespace or use_whitespace_styler:
                style = stylers.whitespace.copy()
            else:
                style = self._renderer.as_mist_style()
            var alignment = self._alignment.horizontal if self.is_set[PropKey.HORIZONTAL_ALIGNMENT]() else Position(0)
            result = align_text_horizontal(result, alignment, self._width, style)

        # Apply border at the end
        if not inline:
            result = _apply_margins(self, _apply_border(self, result), inline)

        # Truncate according to max_width
        # The byte-length check is free and proves the whole string fits (see `_wrap_words`);
        # only fall back to measuring real display width when it cannot.
        if (
            self._max_width > 0
            and result.byte_length() > Int(self._max_width)
            and get_widest_line(result) > UInt(self._max_width)
        ):
            var text_lines = result.split(NEWLINE)
            var truncated = String(capacity=Int(Float64(result.byte_length()) * 1.5))
            for i in range(len(text_lines)):
                if i != 0:
                    truncated.write(NEWLINE)

                # Truncating rescans and rewrites any ANSI sequences on the line, so skip
                # the lines that already fit.
                if printable_rune_width(text_lines[i]) <= UInt(self._max_width):
                    truncated.write(text_lines[i])
                else:
                    truncated.write(truncate(text_lines[i], UInt(self._max_width), self._tail))

            result = truncated^

        # Truncate according to max_height. Splitting and rejoining rebuilds the whole
        # string, so only pay for it when there are lines to drop.
        if self._max_height > 0:
            var final_lines = result.splitlines()
            if len(final_lines) > Int(self._max_height):
                # `final_lines` borrows from `result`, so build the joined string before
                # assigning it back.
                var joined_lines = NEWLINE.join(final_lines[0 : Int(self._max_height)])
                result = joined_lines^

        writer.write(result)

    def render[*Ts: Writable](self, *texts: *Ts, separator: StringSpan = " ") -> String:
        var result = String(capacity=DEFAULT_BUFFER_SIZE)
        self.render(*texts, writer=result, separator=separator)
        return result^
