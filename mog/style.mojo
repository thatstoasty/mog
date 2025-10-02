import mist
from mist.transform import truncate, word_wrap, wrap
from mist.transform.ansi import printable_rune_width
from mog._extensions import get_lines, get_widest_line, pad_left, pad_right
from mog._properties import BorderColor, Coloring, Dimensions, Margin, Padding, Properties, PropKey, Side, Emphasis, Axis
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


alias TAB_WIDTH = 4
"""The default tab width to use when rendering text with tabs."""

alias NO_TAB_CONVERSION = -1
"""Used to disable the replacement of tabs with spaces at render time."""


struct Stylers:
    var common: mist.Style
    var space: mist.Style
    var whitespace: mist.Style

    fn __init__(out self, var common: mist.Style, var space: mist.Style, var whitespace: mist.Style):
        self.common = common^
        self.space = space^
        self.whitespace = whitespace^

    fn __moveinit__(out self, deinit other: Self):
        self.common = other.common^
        self.space = other.space^
        self.whitespace = other.whitespace^


fn _apply_styles(text: String, use_space_styler: Bool, styles: Stylers) -> String:
    """Apply styles to text.

    Args:
        text: The text to apply styles to.
        use_space_styler: Whether to use the space styler.
        styles: The styles to apply.

    Returns:
        The styled text.
    """
    var result = String(capacity=Int(len(text) * 1.5))

    var lines = text.split(NEWLINE)
    for i in range(len(lines)):
        # Readd the newlines
        if i != 0:
            result.write(NEWLINE)

        # If we're using a space styler, we need to check each character.
        # Look for spaces and apply a different styler.
        if use_space_styler:
            for codepoint in lines[i].codepoint_slices():
                if codepoint.isspace():
                    # While I could use a buffer for spaces, it would result in more frequent allocations.
                    # TODO: Maybe I can figure out how to use a space buffer without allocating too often.
                    result.write(styles.space.render(codepoint))
                else:
                    result.write(styles.common.render(codepoint))
        else:
            result.write(styles.common.render(lines[i]))

    return result


fn _wrap_words(text: String, width: UInt16, left_padding: UInt16, right_padding: UInt16) -> String:
    var wrap_at = width - left_padding - right_padding
    return wrap(word_wrap(text, Int(wrap_at)), Int(wrap_at))


fn _maybe_convert_tabs(style: Style, var text: String) -> String:
    """Convert tabs to spaces if the tab width is set.

    Args:
        style: The style to use for the conversion.
        text: The text to convert tabs in.

    Returns:
        The text with tabs converted to spaces.
    """
    var DEFAULT_TAB_WIDTH: UInt16 = TAB_WIDTH
    if style.is_set[PropKey.TAB_WIDTH]():
        DEFAULT_TAB_WIDTH = style.tab_width

    if DEFAULT_TAB_WIDTH == -1:
        return text^

    if DEFAULT_TAB_WIDTH == 0:
        return text.replace("\t", "")
    else:
        return text.replace("\t", (WHITESPACE * Int(DEFAULT_TAB_WIDTH)))


fn _style_border(style: Style, border: String, fg: AnyTerminalColor, bg: AnyTerminalColor) -> String:
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
        return border

    return (
        style.renderer.as_mist_style()
        .foreground(color=fg.to_mist_color(style.renderer))
        .background(color=bg.to_mist_color(style.renderer))
        .render(border)
    )

fn _apply_border(style: Style, text: String) -> String:
    """Apply a border to the text.

    Args:
        style: The style to use for the border.
        text: The text to apply the border to.

    Returns:
        The text with the border applied.
    """
    var top_set = style.is_set[PropKey.BORDER_TOP]()
    var right_set = style.is_set[PropKey.BORDER_RIGHT]()
    var bottom_set = style.is_set[PropKey.BORDER_BOTTOM]()
    var left_set = style.is_set[PropKey.BORDER_LEFT]()

    var border = style.border.copy()
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
        return text

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

    var result = String(capacity=Int(len(text) * 1.5))
    # Render top
    if has_top:
        result.write(
            _style_border(
                style,
                render_horizontal_edge(border.top_left, border.top, border.top_right, width),
                style.border_color.foreground_top,
                style.border_color.background_top,
            ),
            NEWLINE,
        )

    # Render sides once, and reuse for each line.
    var left_border: String
    if has_left:
        left_border = _style_border(
            style, border.left, style.border_color.foreground_left, style.border_color.background_left
        )
    else:
        left_border = ""

    var right_border: String
    if has_right:
        right_border = _style_border(
            style, border.right, style.border_color.foreground_right, style.border_color.background_right
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
                render_horizontal_edge(border.bottom_left, border.bottom, border.bottom_right, width),
                style.border_color.foreground_bottom,
                style.border_color.background_bottom,
            ),
        )

    return result^

fn _apply_margins(style: Style, var text: String, inline: Bool) -> String:
    """Apply margins to the text.

    Args:
        style: The style to use for the margins.
        text: The text to apply the margins to.
        inline: Whether the text is inline or not.

    Returns:
        The text with the margins applied.
    """
    var styler = style.renderer.as_mist_style().background(
        color=style.margin.background.to_mist_color(style.renderer)
    )

    # Add left and right margin
    text = pad_right(pad_left(text^, Int(style.margin.left), styler), Int(style.margin.right), styler)

    # Top/bottom margin
    var top_margin = Int(style.margin.top)
    var bottom_margin = Int(style.margin.bottom)
    if not inline:
        var width = get_widest_line(text)
        if top_margin > 0:
            text = String((WHITESPACE * width + NEWLINE) * top_margin, text)
        if bottom_margin > 0:
            text.write((NEWLINE + WHITESPACE * width) * bottom_margin)

    return text^

fn _get_styles(style: Style) -> Stylers:
    var base = style.renderer.as_mist_style()
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

    var fg_color = style.foreground.to_mist_color(style.renderer)
    var bg_color = style.background.to_mist_color(style.renderer)
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


struct Style(Copyable, ImplicitlyCopyable, Movable):
    """Terminal styler.

    #### Usage:
    ```mojo
    import mog
    from mog import Emphasis, Padding

    fn main():
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

    var renderer: Renderer
    """The renderer to use for the style, determines the color profile."""
    var _properties: Properties
    """List of attributes with 1 or 0 values to determine if a property is set.
    properties = is it set? _attrs = is it set to true or false? (for bool properties).
    """
    var value: String
    """The string value to apply the style to. All rendered text will start with this value."""

    var _attrs: Properties
    """Stores the value of set bool properties here.
    Eg. Setting bool to to true on a style makes _attrs.has(BOOL_KEY) return true.
    """

    # props that have values
    var foreground: AnyTerminalColor
    """The foreground color of the text area. IE: The color of the text itself."""
    var background: AnyTerminalColor
    """The background color of the text area. IE: The color of the background behind the text."""
    var height: UInt16
    """The height of the text area."""
    var width: UInt16
    """The width of the text area."""
    var max_height: UInt16
    """The height of the text area."""
    var max_width: UInt16
    """The width of the text area."""
    var alignment: Alignment
    """The alignment of the text."""
    var padding: Padding
    """The padding levels."""
    var margin: Margin
    """The margin levels."""

    var border: Border
    """The border style."""
    var border_color: BorderColor
    """The border colors."""

    var tab_width: UInt16
    """The number of spaces that a tab (/t) should be rendered as."""

    fn __init__(
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
            alignment: The alignment of the text.
            padding: The padding levels.
            margin: The margin levels.
            border: The border style.
            border_color: The border colors.
            tab_width: The number of spaces that a tab (/t) should be rendered as.
        """
        self.renderer = renderer
        self._properties = properties
        self.value = value
        self._attrs = attrs
        self.foreground = foreground^
        self.background = background^
        self.width = width
        self.height = height
        self.max_width = max_width
        self.max_height = max_height
        self.alignment = alignment
        self.padding = padding
        self.margin = margin^
        self.border = border.copy()
        self.border_color = border_color^
        self.tab_width = tab_width
    
    fn __init__(
        out self,
        color_profile: Optional[mist.Profile] = None,
        *,
        width: Optional[Int] = None,
        height: Optional[Int] = None,
        max_width: Optional[Int] = None,
        max_height: Optional[Int] = None,
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
        self.renderer = Renderer(color_profile.value()) if color_profile else Renderer()
        self.value = value^
        self.alignment = Alignment()
        self.padding = Padding()
        self.margin = Margin()
        self.border_color = BorderColor()
        self.tab_width = 0
        self.width = 0
        self.height = 0
        self.max_width = 0
        self.max_height = 0
        self.foreground = NoColor()
        self.background = NoColor()
        self.border = NO_BORDER.copy()

        if width:
            self.width = width.value()
            self._properties.set[PropKey.WIDTH](True)
        if height:
            self.height = height.value()
            self._properties.set[PropKey.HEIGHT](True)

        if max_width:
            self.max_width = max_width.value()
            self._properties.set[PropKey.MAX_WIDTH](True)
        if max_height:
            self.max_height = max_height.value()
            self._properties.set[PropKey.MAX_HEIGHT](True)

        if not foreground.is_same_type(NoColor()):
            self.foreground = foreground
            self._properties.set[PropKey.FOREGROUND](True)
        if not background.is_same_type(NoColor()):
            self.background = background
            self._properties.set[PropKey.BACKGROUND](True)

        if border:
            self.border = border.value().copy()
            self._properties.set[PropKey.BORDER_STYLE](True)
            
            @parameter
            for key in [PropKey.BORDER_TOP, PropKey.BORDER_RIGHT, PropKey.BORDER_BOTTOM, PropKey.BORDER_LEFT]:
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
            self.padding = padding.value()
            self._properties.set[PropKey.PADDING_TOP](True)
            self._properties.set[PropKey.PADDING_RIGHT](True)
            self._properties.set[PropKey.PADDING_BOTTOM](True)
            self._properties.set[PropKey.PADDING_LEFT](True)

        if margin:
            self.margin = margin.value()
            self._properties.set[PropKey.MARGIN_TOP](True)
            self._properties.set[PropKey.MARGIN_RIGHT](True)
            self._properties.set[PropKey.MARGIN_BOTTOM](True)
            self._properties.set[PropKey.MARGIN_LEFT](True)
        
        if alignment:
            self.alignment = alignment.value()
            self._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)
            self._properties.set[PropKey.VERTICAL_ALIGNMENT](True)

    fn copy(self) -> Self:
        """Create a copy of the style.

        Returns:
            A new Style with the same properties as the original.
        """
        return Self(
            renderer=self.renderer,
            properties=self._properties,
            value=self.value,
            attrs=self._attrs,
            foreground=self.foreground.copy(),
            background=self.background.copy(),
            width=self.width,
            height=self.height,
            max_width=self.max_width,
            max_height=self.max_height,
            alignment=self.alignment,
            padding=self.padding,
            margin=self.margin.copy(),
            border=self.border,
            border_color=self.border_color.copy(),
            tab_width=self.tab_width,
        )

    fn _check_attr[key: PropKey](self, *, default: Bool = False) -> Bool:
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
    
    fn is_set[key: PropKey](self) -> Bool:
        """Check if a rule is set on the style.

        Parameters:
            key: The key to check.

        Returns:
            True if the rule is set, False otherwise.
        """
        return self._properties.has[key]()

    fn _set_attribute[key: PropKey](mut self, value: Bool):
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

    fn _unset_attribute[key: PropKey](mut self):
        """Unset a boolean attribute on the style.

        Parameters:
            key: The key to set.
        """
        self._properties.set[key](False)

    fn set_renderer(self, /, renderer: Renderer) -> Self:
        """Set the renderer for the style.

        Args:
            renderer: The renderer to set.

        Returns:
            A new Style with the renderer set.
        """
        var new = self.copy()
        new.renderer = renderer
        return new^

    fn set_value(self, /, value: String) -> Self:
        """Set the string value for the style.

        Args:
            value: The string value to set.

        Returns:
            A new Style with the string value set.
        """
        var new = self.copy()
        new.value = value
        return new^

    fn set_tab_width(self, /, width: UInt16) -> Self:
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
        new.tab_width = width
        new._properties.set[PropKey.TAB_WIDTH](True)
        return new^

    fn unset_tab_width(self) -> Self:
        """Unset the tab width of the text.

        Returns:
            A new Style with the tab width rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.TAB_WIDTH]()
        return new^

    fn inline(self, value: Bool = True) -> Self:
        """Makes rendering output one line and disables the rendering of
        margins, padding and borders. This is useful when you need a style to apply
        only to font rendering and don't want it to change any physical dimensions.
        It works well with `Style.set_max_width()`.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the bold rule set.

        #### Examples:
        ```mojo
        var input = "..."
        var style = mog.Style().inline()
        print(style.render(input))
        ```
        """
        var new = self.copy()
        new._set_attribute[PropKey.INLINE](value)
        return new^

    @always_inline
    fn check_if_inline(self) -> Bool:
        """Returns whether or not the inline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._check_attr[PropKey.INLINE](default=False)

    fn unset_inline(self) -> Self:
        """Unset the inline rule.

        Returns:
            A new Style with the inline rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.INLINE]()
        return new^

    fn set_emphasis(self, style: Emphasis, value: Bool = True) -> Self:
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
    
    fn unset_emphasis(self, style: Emphasis) -> Self:
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

    fn check_emphasis(self, style: Emphasis) -> Bool:
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

    fn set_width(self, width: UInt16) -> Self:
        """Set the width of the text.

        Args:
            width: The width to apply.

        Returns:
            A new Style with the width rule set.

        #### Notes:
        If you need width to be truncated to obey the width rule, use `Style.set_max_width()` instead.
        """
        var new = self.copy()
        new.width = width
        new._properties.set[PropKey.WIDTH](True)
        return new^

    fn unset_width(self) -> Self:
        """Unset the width of the text.

        Returns:
            A new Style with the width rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.WIDTH]()
        return new^

    fn set_height(self, height: UInt16) -> Self:
        """Set the height of the text.
        If the height of the text being styled is greater than height, then this is a noop.

        Args:
            height: The height to apply.

        Returns:
            A new Style with the height rule set.

        #### Notes:
        If you need height to be truncated to obey the height rule, use `Style.set_max_height()` instead.
        """
        var new = self.copy()
        new.height = height
        new._properties.set[PropKey.HEIGHT](True)
        return new^

    fn unset_height(self) -> Self:
        """Unset the height of the text.

        Returns:
            A new Style with the height rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.HEIGHT]()
        return new^

    fn set_max_width(self, width: UInt16) -> Self:
        """Applies a max width to a given style. This enforces a max width of a line by truncating lines that are too long,
        and will pad all lines to the width of the widest line.

        Args:
            width: The maximum height to apply.

        Returns:
            A new Style with the maximum width rule set.

        #### Notes:
        This does **NOT** pad the lines to the max width, if you want to pad all lines to the width given use `Style.width()` instead.

        #### Examples:
        ```mojo
        var user_input = "..."
        var user_style = mog.Style().set_max_width(16)
        print(user_style.render(user_input))
        ```
        """
        var new = self.copy()
        new.max_width = width
        new._properties.set[PropKey.MAX_WIDTH](True)
        return new^

    fn unset_max_width(self) -> Self:
        """Unset the max width of the text.

        Returns:
            A new Style with the max width rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MAX_WIDTH]()
        return new^

    fn set_max_height(self, height: UInt16) -> Self:
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
        new.max_height = height
        new._properties.set[PropKey.MAX_HEIGHT](True)
        return new^

    fn unset_max_height(self) -> Self:
        """Unset the max height of the text.

        Returns:
            A new Style with the max height rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MAX_HEIGHT]()
        return new^
    
    fn set_text_alignment(self, align: Position) -> Self:
        """Set the horizontal and vertical alignment of the text in the text area.

        Args:
            align: The alignment value to apply from 0 to 1.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()
        new.alignment.horizontal = align
        new.alignment.vertical = align
        new._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)
        new._properties.set[PropKey.VERTICAL_ALIGNMENT](True)
        return new^

    fn set_text_alignment(self, horizontal: Position, vertical: Position) -> Self:
        """Set the horizontal and vertical alignment of the text in the text area.

        Args:
            horizontal: The horizontal alignment value to apply from 0 to 1.
            vertical: The vertical alignment value to apply from 0 to 1.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()
        new.alignment.horizontal = horizontal
        new._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)

        new.alignment.vertical = vertical
        new._properties.set[PropKey.VERTICAL_ALIGNMENT](True)
        return new^
    
    fn set_text_alignment(self, axis: Axis, align: Position) -> Self:
        """Set the horizontal or vertical alignment of the text in the text area.

        Args:
            axis: The axis to set the alignment for.
            align: The alignment value to apply from 0 to 1.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()

        if axis == Axis.HORIZONTAL:
            new.alignment.horizontal = align
            new._properties.set[PropKey.HORIZONTAL_ALIGNMENT](True)
        elif axis == Axis.VERTICAL:
            new.alignment.vertical = align
            new._properties.set[PropKey.VERTICAL_ALIGNMENT](True)
        return new^

    fn unset_text_alignment(self, axis: Axis) -> Self:
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

    fn set_foreground_color(self, var color: AnyTerminalColor) -> Self:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the foreground color rule set.
        """
        var new = self.copy()
        new.foreground = color^
        new._properties.set[PropKey.FOREGROUND](True)
        return new^

    fn unset_foreground_color(self) -> Self:
        """Unset the foreground color of the text.

        Returns:
            A new Style with the foreground color rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.FOREGROUND]()
        return new^

    fn set_background_color(self, var color: AnyTerminalColor) -> Self:
        """Set the background color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the background color rule set.
        """
        var new = self.copy()
        new.background = color^
        new._properties.set[PropKey.BACKGROUND](True)
        return new^

    fn unset_background_color(self) -> Self:
        """Unset the background color of the text.

        Returns:
            A new Style with the background color rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.BACKGROUND]()
        return new^
    
    fn set_border(self, var border: Border) -> Self:
        """Sets the border style to use.

        Args:
            border: The Border style to apply.

        Returns:
            A new Style with the border style set.
        """
        var new = self.copy()
        new.border = border^
        new._properties.set[PropKey.BORDER_STYLE](True)
        new._set_attribute[PropKey.BORDER_TOP](True)
        new._set_attribute[PropKey.BORDER_RIGHT](True)
        new._set_attribute[PropKey.BORDER_BOTTOM](True)
        new._set_attribute[PropKey.BORDER_LEFT](True)
        return new^

    fn set_border_side_rendering(
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
    
    fn unset_border_side_rendering(
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
    
    fn check_if_border_side_will_render(self, side: Side) -> Bool:
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
    
    fn set_border_foreground(self, *colors: AnyTerminalColor) -> Self:
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
            new.border_color.foreground_top = colors[0].copy()
            new.border_color.foreground_bottom = colors[0].copy()
            new.border_color.foreground_left = colors[0].copy()
            new.border_color.foreground_right = colors[0].copy()
        elif colors_provided == 2:
            new.border_color.foreground_top = colors[0].copy()
            new.border_color.foreground_bottom = colors[0].copy()
            new.border_color.foreground_left = colors[1].copy()
            new.border_color.foreground_right = colors[1].copy()
        elif colors_provided == 3:
            new.border_color.foreground_top = colors[0].copy()
            new.border_color.foreground_left = colors[1].copy()
            new.border_color.foreground_right = colors[1].copy()
            new.border_color.foreground_bottom = colors[2].copy()
        elif colors_provided == 4:
            new.border_color.foreground_top = colors[0].copy()
            new.border_color.foreground_right = colors[1].copy()
            new.border_color.foreground_bottom = colors[2].copy()
            new.border_color.foreground_left = colors[3].copy()
        else:
            return new^

        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^
    
    fn set_border_top_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the top border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new.border_color.foreground_top = color^
        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)
        return new^
    
    fn set_border_right_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the right border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new.border_color.foreground_right = color^
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)
        return new^

    fn set_border_bottom_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the bottom border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new.border_color.foreground_bottom = color^
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)
        return new^

    fn set_border_left_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color.

        Args:
            color: The foreground color for the left border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new.border_color.foreground_left = color^
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    fn set_border_foreground(self, var color: AnyTerminalColor) -> Self:
        """Set the border foreground color for all sides of the border.

        Args:
            color: The color to apply to all sides of the border.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new.border_color.foreground_top = color.copy()
        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)

        new.border_color.foreground_right = color.copy()
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)

        new.border_color.foreground_bottom = color.copy()
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)

        new.border_color.foreground_left = color.copy()
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    fn set_border_foreground(self, top_bottom_color: AnyTerminalColor, left_right_color: AnyTerminalColor) -> Self:
        """Set the border foreground color for all sides of the border.

        Args:
            top_bottom_color: The color to apply to the top and bottom sides of the border.
            left_right_color: The color to apply to the left and right sides of the border.

        Returns:
            A new Style with the border foreground color rules set.
        """
        var new = self.copy()
        new.border_color.foreground_top = top_bottom_color
        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)

        new.border_color.foreground_right = left_right_color
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)

        new.border_color.foreground_bottom = top_bottom_color
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)

        new.border_color.foreground_left = left_right_color
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^
    
    fn unset_border_foreground(
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
        if not top and not right and not bottom and not right:
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
    
    fn set_border_background(self, *colors: AnyTerminalColor) -> Self:
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
            new.border_color.background_top = colors[0].copy()
            new.border_color.background_bottom = colors[0].copy()
            new.border_color.background_left = colors[0].copy()
            new.border_color.background_right = colors[0].copy()
        elif colors_provided == 2:
            new.border_color.background_top = colors[0].copy()
            new.border_color.background_bottom = colors[0].copy()
            new.border_color.background_left = colors[1].copy()
            new.border_color.background_right = colors[1].copy()
        elif colors_provided == 3:
            new.border_color.background_top = colors[0].copy()
            new.border_color.background_left = colors[1].copy()
            new.border_color.background_right = colors[1].copy()
            new.border_color.background_bottom = colors[2].copy()
        elif colors_provided == 4:
            new.border_color.background_top = colors[0].copy()
            new.border_color.background_right = colors[1].copy()
            new.border_color.background_bottom = colors[2].copy()
            new.border_color.background_left = colors[3].copy()
        else:
            return new^

        new._properties.set[PropKey.BORDER_TOP_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_RIGHT_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_BOTTOM_FOREGROUND](True)
        new._properties.set[PropKey.BORDER_LEFT_FOREGROUND](True)
        return new^

    # TODO: Can't have a catchall set_border_background fn because Optional[Variant] does not work.
    fn set_border_top_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the top border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new.border_color.background_top = color^
        new._properties.set[PropKey.BORDER_TOP_BACKGROUND](True)
        return new^
    
    fn set_border_bottom_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the bottom border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new.border_color.background_bottom = color^
        new._properties.set[PropKey.BORDER_BOTTOM_BACKGROUND](True)
        return new^
    
    fn set_border_left_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the left border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new.border_color.background_left = color^
        new._properties.set[PropKey.BORDER_LEFT_BACKGROUND](True)
        return new^
    
    fn set_border_right_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color.

        Args:
            color: The background color for the right border side.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self.copy()
        new.border_color.background_right = color^
        new._properties.set[PropKey.BORDER_RIGHT_BACKGROUND](True)
        return new^

    fn set_border_background(self, var color: AnyTerminalColor) -> Self:
        """Set the border background color for all sides of the border.

        Args:
            color: The color to apply to all sides of the border.

        Returns:
            A new Style with the border background color rules set.
        """
        var new = self.copy()
        new.border_color.background_top = color.copy()
        new._properties.set[PropKey.BORDER_TOP_BACKGROUND](True)

        new.border_color.background_right = color.copy()
        new._properties.set[PropKey.BORDER_RIGHT_BACKGROUND](True)

        new.border_color.background_bottom = color.copy()
        new._properties.set[PropKey.BORDER_BOTTOM_BACKGROUND](True)

        new.border_color.background_left = color.copy()
        new._properties.set[PropKey.BORDER_LEFT_BACKGROUND](True)
        return new^

    fn unset_border_background(
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
        if not top and not right and not bottom and not right:
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

    fn set_padding(
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
        if not top and not right and not bottom and not right:
            return self.copy()

        var new = self.copy()
        if top:
            new.padding.top = UInt16(top.value())
            new._properties.set[PropKey.PADDING_TOP](True)

        if right:
            new.padding.right = UInt16(right.value())
            new._properties.set[PropKey.PADDING_RIGHT](True)

        if bottom:
            new.padding.bottom = UInt16(bottom.value())
            new._properties.set[PropKey.PADDING_BOTTOM](True)

        if left:
            new.padding.left = UInt16(left.value())
            new._properties.set[PropKey.PADDING_LEFT](True)
        return new^
    
    fn set_padding(self, width: UInt16) -> Self:
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
        new.padding.top = UInt16(width)
        new._properties.set[PropKey.PADDING_TOP](True)

        new.padding.right = UInt16(width)
        new._properties.set[PropKey.PADDING_RIGHT](True)

        new.padding.bottom = UInt16(width)
        new._properties.set[PropKey.PADDING_BOTTOM](True)

        new.padding.left = UInt16(width)
        new._properties.set[PropKey.PADDING_LEFT](True)
        return new^

    fn set_padding(self, top_bottom_width: UInt16, left_right_width: UInt16) -> Self:
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
        new.padding.top = UInt16(top_bottom_width)
        new._properties.set[PropKey.PADDING_TOP](True)

        new.padding.bottom = UInt16(top_bottom_width)
        new._properties.set[PropKey.PADDING_BOTTOM](True)

        new.padding.left = UInt16(left_right_width)
        new._properties.set[PropKey.PADDING_LEFT](True)

        new.padding.right = UInt16(left_right_width)
        new._properties.set[PropKey.PADDING_RIGHT](True)
        return new^
    
    fn unset_padding(
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
        if not top and not right and not bottom and not right:
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

    fn set_margin(
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
            new.margin.top = UInt16(top.value())
            new._properties.set[PropKey.MARGIN_TOP](True)

        if right:
            new.margin.right = UInt16(right.value())
            new._properties.set[PropKey.MARGIN_RIGHT](True)

        if bottom:
            new.margin.bottom = UInt16(bottom.value())
            new._properties.set[PropKey.MARGIN_BOTTOM](True)

        if left:
            new.margin.left = UInt16(left.value())
            new._properties.set[PropKey.MARGIN_LEFT](True)
        return new^
    
    fn set_margin(self, width: UInt16) -> Self:
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
        new.margin.top = UInt16(width)
        new._properties.set[PropKey.MARGIN_TOP](True)

        new.margin.right = UInt16(width)
        new._properties.set[PropKey.MARGIN_RIGHT](True)

        new.margin.bottom = UInt16(width)
        new._properties.set[PropKey.MARGIN_BOTTOM](True)

        new.margin.left = UInt16(width)
        new._properties.set[PropKey.MARGIN_LEFT](True)
        return new^

    fn set_margin(self, top_bottom_width: UInt16, left_right_width: UInt16) -> Self:
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
        new.margin.top = UInt16(top_bottom_width)
        new._properties.set[PropKey.MARGIN_TOP](True)

        new.margin.bottom = UInt16(top_bottom_width)
        new._properties.set[PropKey.MARGIN_BOTTOM](True)

        new.margin.left = UInt16(left_right_width)
        new._properties.set[PropKey.MARGIN_LEFT](True)

        new.margin.right = UInt16(left_right_width)
        new._properties.set[PropKey.MARGIN_RIGHT](True)
        return new^
    
    fn unset_margin(
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
        if not top and not right and not bottom and not right:
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

    fn set_margin_background(self, var color: AnyTerminalColor) -> Self:
        """Set the margin on the background color.

        Args:
            color: The margin width to apply.

        Returns:
            A new Style with the margin background rule set.
        """
        var new = self.copy()
        new.margin.background = color^
        new._properties.set[PropKey.MARGIN_BACKGROUND](True)
        return new^

    fn unset_margin_background(self) -> Self:
        """Unset the margin background rule.

        Returns:
            A new Style with the margin background rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MARGIN_BACKGROUND]()
        return new^
    
    fn uses_space_styler(self) -> Bool:
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

    fn render[*Ts: Writable](self, *texts: *Ts) -> String:
        """Creates a `Style` with the text provided.

        Args:
            texts: The strings to render.

        Returns:
            The rendered Style.
        """
        # If style has internal string, add it first. Join arbitrary list of texts into a single string.
        var input_text = self.value.copy()

        @parameter
        for i in range(texts.__len__()):
            input_text.write(texts[i])
            if i != len(texts) - 1:
                input_text.write(" ")

        var reverse = self.check_emphasis(Emphasis.REVERSE)
        var color_whitespace = self._check_attr[PropKey.COLOR_WHITESPACE](default=True)

        # If no style properties are set, return the input text as is with tabs maybe converted.
        if not any(self._properties.value):
            return _maybe_convert_tabs(self, input_text)

        var inline = self.check_if_inline()
        if inline:
            input_text = input_text.replace(NEWLINE, "")

        # Word wrap
        # force-wrap long strings
        if not inline and (self.width > 0):
            input_text = _wrap_words(input_text, self.width, self.padding.left, self.padding.right)

        var stylers = _get_styles(self)
        var result = _apply_styles(_maybe_convert_tabs(self, input_text), self.uses_space_styler(), stylers)

        # Do we need to style whitespace (padding and space outside paragraphs) separately?
        var use_whitespace_styler = reverse

        # Padding
        if not inline:
            if self.padding.left > 0:
                var style = self.renderer.as_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = stylers.whitespace.copy()
                result = pad_left(result, Int(self.padding.left), style)

            if self.padding.right > 0:
                var style = self.renderer.as_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = stylers.whitespace.copy()
                result = pad_right(result, Int(self.padding.right), style)

            if self.padding.top > 0:
                result = String(NEWLINE * Int(self.padding.top), result^)

            if self.padding.bottom > 0:
                result.write(NEWLINE * Int(self.padding.bottom))

        # Alignment
        var height = self.height
        if height > 0:
            var alignment = self.alignment.vertical if self.is_set[PropKey.VERTICAL_ALIGNMENT]() else Position(0)
            result = align_text_vertical(result, alignment, height)

        if self.width != 0 or get_widest_line(result) != 0:
            var style: mist.Style
            if color_whitespace or use_whitespace_styler:
                style = stylers.whitespace.copy()
            else:
                style = self.renderer.as_mist_style()
            var alignment = self.alignment.horizontal if self.is_set[PropKey.HORIZONTAL_ALIGNMENT]() else Position(0)
            result = align_text_horizontal(result, alignment, self.width, style)

        # Apply border at the end
        if not inline:
            result = _apply_margins(self, _apply_border(self, result), inline)

        # Truncate according to max_width
        if self.max_width > 0:
            var text_lines = result.split(NEWLINE)
            var truncated = String(capacity=Int(len(result) * 1.5))
            for i in range(len(text_lines)):
                if i != 0:
                    truncated.write(NEWLINE)
                truncated.write(truncate(text_lines[i], Int(self.max_width)))

            result = truncated^

        # Truncate according to max_height
        if self.max_height > 0:
            var final_lines = result.as_string_slice().get_immutable().splitlines()
            result = NEWLINE.join(final_lines[0 : min(Int(self.max_height), len(final_lines))])

        return result^
