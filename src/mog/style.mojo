from collections import Optional
from .renderer import Renderer
from .position import Position
from .border import (
    Border,
    render_horizontal_edge,
    NO_BORDER,
    HIDDEN_BORDER,
    DOUBLE_BORDER,
    ROUNDED_BORDER,
    NORMAL_BORDER,
    BLOCK_BORDER,
    INNER_HALF_BLOCK_BORDER,
    OUTER_HALF_BLOCK_BORDER,
    THICK_BORDER,
    ASCII_BORDER,
    STAR_BORDER,
    PLUS_BORDER,
)
from .extensions import get_lines
from .align import align_text_horizontal, align_text_vertical
from .color import (
    AnyTerminalColor,
    TerminalColor,
    NoColor,
    Color,
    ANSIColor,
    AdaptiveColor,
    CompleteColor,
    CompleteAdaptiveColor,
)
from weave import wrap, word_wrap, truncate
from weave.ansi import printable_rune_width
import mist


alias TAB_WIDTH: Int = 4

alias NO_TAB_CONVERSION = -1
"""NoTabConversion can be passed to [Style.tab_width] to disable the replacement
of tabs with spaces at render time."""

alias PropertyKey = Int
alias BOLD_KEY: PropertyKey = 1
alias ITALIC_KEY: PropertyKey = 2
alias UNDERLINE_KEY: PropertyKey = 3
alias CROSSOUT_KEY: PropertyKey = 4
alias REVERSE_KEY: PropertyKey = 5
alias BLINK_KEY: PropertyKey = 6
alias FAINT_KEY: PropertyKey = 7
alias FOREGROUND_KEY: PropertyKey = 8
alias BACKGROUND_KEY: PropertyKey = 9
alias WIDTH_KEY: PropertyKey = 10
alias HEIGHT_KEY: PropertyKey = 11
alias HORIZONTAL_ALIGNMENT_KEY: PropertyKey = 12
alias VERTICAL_ALIGNMENT_KEY: PropertyKey = 13

# Padding.
alias PADDING_TOP_KEY: PropertyKey = 14
alias PADDING_RIGHT_KEY: PropertyKey = 15
alias PADDING_BOTTOM_KEY: PropertyKey = 16
alias PADDING_LEFT_KEY: PropertyKey = 17

alias COLOR_WHITESPACE_KEY: PropertyKey = 18

# Margins.
alias MARGIN_TOP_KEY: PropertyKey = 19
alias MARGIN_RIGHT_KEY: PropertyKey = 20
alias MARGIN_BOTTOM_KEY: PropertyKey = 21
alias MARGIN_LEFT_KEY: PropertyKey = 22
alias MARGIN_BACKGROUND_KEY: PropertyKey = 23

# Border runes.
alias BORDER_STYLE_KEY: PropertyKey = 24

# Border edges.
alias BORDER_TOP_KEY: PropertyKey = 25
alias BORDER_RIGHT_KEY: PropertyKey = 26
alias BORDER_BOTTOM_KEY: PropertyKey = 27
alias BORDER_LEFT_KEY: PropertyKey = 28

# Border foreground colors.
alias BORDER_TOP_FOREGROUND_KEY: PropertyKey = 29
alias BORDER_RIGHT_FOREGROUND_KEY: PropertyKey = 30
alias BORDER_BOTTOM_FOREGROUND_KEY: PropertyKey = 31
alias BORDER_LEFT_FOREGROUND_KEY: PropertyKey = 32

# Border background colors.
alias BORDER_TOP_BACKGROUND_KEY: PropertyKey = 33
alias BORDER_RIGHT_BACKGROUND_KEY: PropertyKey = 34
alias BORDER_BOTTOM_BACKGROUND_KEY: PropertyKey = 35
alias BORDER_LEFT_BACKGROUND_KEY: PropertyKey = 36

alias INLINE_KEY: PropertyKey = 37
alias MAX_WIDTH_KEY: PropertyKey = 38
alias MAX_HEIGHT_KEY: PropertyKey = 39
alias TAB_WIDTH_KEY: PropertyKey = 40
alias UNDERLINE_SPACES_KEY: PropertyKey = 41
alias CROSSOUT_SPACES_KEY: PropertyKey = 42


fn pad(text: String, n: Int, style: mist.Style) -> String:
    """Pad text with spaces.

    Args:
        text: The text to pad.
        n: The number of spaces to pad with.
        style: The style to use for the spaces.
    
    Returns:
        The padded text.
    """
    if n == 0:
        return text

    var spaces = style.render(WHITESPACE * abs(n))
    var result = String(capacity=int(len(text) * 1.5))
    var lines = text.as_string_slice().splitlines()
    for i in range(len(lines)):
        if n > 0:
            result.write(lines[i], spaces)
        else:
            result.write(spaces, lines[i])

        if i != len(lines) - 1:
            result.write(NEWLINE)

    return result


fn pad_left(text: String, n: Int, style: mist.Style) -> String:
    """Pad text with spaces to the left.

    Args:
        text: The text to pad.
        n: The number of spaces to pad with.
        style: The style to use for the spaces.
    
    Returns:
        The padded text.
    """
    return pad(text, -n, style)


fn pad_right(text: String, n: Int, style: mist.Style) -> String:
    """Pad text with spaces to the right.

    Args:
        text: The text to pad.
        n: The number of spaces to pad with.
        style: The style to use for the spaces.
    
    Returns:
        The padded text.
    """
    return pad(text, n, style)


@register_passable("trivial")
struct Properties:
    """Properties for a style."""

    var value: SIMD[DType.uint8, 64]
    """Array of attributes with 1 or 0 values to determine if a property is set."""

    fn __init__(out self, value: SIMD[DType.uint8, 64] = SIMD[DType.uint8, 64]()):
        """Initialize a new Properties object.
        
        Args:
            value: The value to set the properties to.
        """
        self.value = value

    fn set(self, key: PropertyKey) -> Properties:
        """Set a property.

        Args:
            key: The key to set.

        Returns:
            A new Properties object with the property set.
        """
        var new = self
        new.value[key] = 1
        return new

    fn unset(self, key: PropertyKey) -> Properties:
        """Unset a property.

        Args:
            key: The key to unset.

        Returns:
            A new Properties object with the property unset.
        """
        var new = self
        new.value[key] = 0
        return new

    fn has(self, key: PropertyKey) -> Bool:
        """Check if a property is set.

        Args:
            key: The key to check.

        Returns:
            True if the property is set, False otherwise.
        """
        return self.value[key] == 1


@value
struct Style:
    """Terminal styler.

    Usage:
    ```mojo
    import mog

    fn main():
        var style = (
            mog.Style()
            .bold(True)
            .foreground(mog.Color(0xFAFAFA))
            .background(mog.Color(0x7D56F4))
            .padding_top(2)
            .padding_left(4)
            .width(22)
        )
        print(style.render("Hello, world"))
    ```
    More documentation to come."""

    var renderer: Renderer
    """The renderer to use for the style, determines the color profile."""
    var properties: Properties
    """List of attributes with 1 or 0 values to determine if a property is set.
    properties = is it set? attrs = is it set to true or false? (for bool properties).
    """
    var value: String
    """The string value to apply the style to. All rendered text will start with this value."""

    var attrs: Properties
    """Stores the value of set bool properties here.
    Eg. Setting bool to to true on a style makes attrs.has(BOOL_KEY) return true.
    """

    # props that have values
    var _fg: AnyTerminalColor
    """The foreground color."""
    var _bg: AnyTerminalColor
    """The background color."""

    var _width: Int
    """The desired width of the text."""
    var _height: Int
    """The desired height of the text."""

    var _horizontal_alignment: Position
    """The horizontal alignment of the text."""
    var _vertical_alignment: Position
    """The vertical alignment of the text."""

    var _padding_top: Int
    """The padding level at the top of the text."""
    var _padding_right: Int
    """The padding level to the right of the text."""
    var _padding_bottom: Int
    """The padding level at the bottom of the text."""
    var _padding_left: Int
    """The padding level to the left of the text."""

    var _margin_top: Int
    """The margin level at the top of the text."""
    var _margin_right: Int
    """The margin level to the right of the text."""
    var _margin_bottom: Int
    """The margin level at the bottom of the text."""
    var _margin_left: Int
    """The margin level to the left of the text."""
    var _margin_bg: AnyTerminalColor
    """The background color of the margin."""

    var _border: Border
    """The border style."""
    var _border_top_fg: AnyTerminalColor
    """The foreground color of the top border."""
    var _border_right_fg: AnyTerminalColor
    """The foreground color of the right border."""
    var _border_bottom_fg: AnyTerminalColor
    """The foreground color of the bottom border."""
    var _border_left_fg: AnyTerminalColor
    """The foreground color of the left border."""
    var _border_top_bg: AnyTerminalColor
    """The background color of the top border."""
    var _border_right_bg: AnyTerminalColor
    """The background color of the right border."""
    var _border_bottom_bg: AnyTerminalColor
    """The background color of the bottom border."""
    var _border_left_bg: AnyTerminalColor
    """The background color of the left border."""

    var _max_width: Int
    """The maximum width of the text."""
    var _max_height: Int
    """The maximum height of the text."""
    var _tab_width: Int
    """The number of spaces that a tab (/t) should be rendered as."""

    fn __init__(out self, value: String = "", color_profile: Optional[Int] = None):
        """Initialize a new Style object.

        Args:
            value: Internal string value to apply the style to. Not required, but useful for reusing some string you want to format multiple times.
            color_profile: The color profile to use. Defaults to None, which means it'll be queried at run time instead.
        """
        if color_profile:
            self.renderer = Renderer(color_profile)
        else:
            self.renderer = Renderer()
        self.properties = Properties()
        self.value = value
        self.attrs = Properties()

        self._fg = NoColor()
        self._bg = NoColor()

        self._width = 0
        self._height = 0

        self._horizontal_alignment = 0
        self._vertical_alignment = 0

        self._padding_top = 0
        self._padding_right = 0
        self._padding_bottom = 0
        self._padding_left = 0

        self._margin_top = 0
        self._margin_right = 0
        self._margin_bottom = 0
        self._margin_left = 0
        self._margin_bg = NoColor()

        self._border = NO_BORDER
        self._border_top_fg = NoColor()
        self._border_right_fg = NoColor()
        self._border_bottom_fg = NoColor()
        self._border_left_fg = NoColor()
        self._border_top_bg = NoColor()
        self._border_right_bg = NoColor()
        self._border_bottom_bg = NoColor()
        self._border_left_bg = NoColor()

        self._max_width = 0
        self._max_height = 0
        self._tab_width = 0

    fn get_as_bool(self, key: PropertyKey, default: Bool = False) -> Bool:
        """Get a rule as a boolean value.

        Args:
            key: The key to get.
            default: The default value to return if the rule is not set.

        Returns:
            The boolean value.
        """
        if not self.is_set(key):
            return default

        return self.attrs.has(key)

    fn get_as_color(self, key: PropertyKey) -> AnyTerminalColor:
        """Get a rule as an AnyTerminalColor value.

        Args:
            key: The key to get.

        Returns:
            The color value.
        """
        if not self.is_set(key):
            return NoColor()

        if key == FOREGROUND_KEY:
            return self._fg
        elif key == BACKGROUND_KEY:
            return self._bg
        elif key == BORDER_TOP_FOREGROUND_KEY:
            return self._border_top_fg
        elif key == BORDER_RIGHT_FOREGROUND_KEY:
            return self._border_right_fg
        elif key == BORDER_BOTTOM_FOREGROUND_KEY:
            return self._border_bottom_fg
        elif key == BORDER_LEFT_FOREGROUND_KEY:
            return self._border_left_fg
        elif key == BORDER_TOP_BACKGROUND_KEY:
            return self._border_top_bg
        elif key == BORDER_RIGHT_BACKGROUND_KEY:
            return self._border_right_bg
        elif key == BORDER_BOTTOM_BACKGROUND_KEY:
            return self._border_bottom_bg
        elif key == BORDER_LEFT_BACKGROUND_KEY:
            return self._border_left_bg
        elif key == MARGIN_BACKGROUND_KEY:
            return self._margin_bg
        else:
            return NoColor()

    fn get_as_int(self, key: PropertyKey) -> Int:
        """Get a rule as an integer value.

        Args:
            key: The key to get.

        Returns:
            The integer value.
        """
        if not self.is_set(key):
            return 0

        if key == WIDTH_KEY:
            return self._width
        elif key == HEIGHT_KEY:
            return self._height
        elif key == PADDING_TOP_KEY:
            return self._padding_top
        elif key == PADDING_RIGHT_KEY:
            return self._padding_right
        elif key == PADDING_BOTTOM_KEY:
            return self._padding_bottom
        elif key == PADDING_LEFT_KEY:
            return self._padding_left
        elif key == MARGIN_TOP_KEY:
            return self._margin_top
        elif key == MARGIN_RIGHT_KEY:
            return self._margin_right
        elif key == MARGIN_BOTTOM_KEY:
            return self._margin_bottom
        elif key == MARGIN_LEFT_KEY:
            return self._margin_left
        elif key == MAX_WIDTH_KEY:
            return self._max_width
        elif key == MAX_HEIGHT_KEY:
            return self._max_height
        elif key == TAB_WIDTH_KEY:
            return self._tab_width
        else:
            return 0

    fn get_as_position(self, key: PropertyKey) -> Position:
        """Get a rule as a Position value.

        Args:
            key: The key to get.

        Returns:
            The Position value.
        """
        if not self.is_set(key):
            return 0

        if key == HORIZONTAL_ALIGNMENT_KEY:
            return self._horizontal_alignment
        elif key == VERTICAL_ALIGNMENT_KEY:
            return self._vertical_alignment
        else:
            return 0

    fn get_border_style(self) -> Border:
        """Get the Border style rule.

        Returns:
            The Border style.
        """
        if not self.is_set(BORDER_STYLE_KEY):
            return Border()

        return self._border

    fn is_set(self, key: PropertyKey) -> Bool:
        """Check if a rule is set on the style.

        Args:
            key: The key to check.

        Returns:
            True if the rule is set, False otherwise.
        """
        return self.properties.has(key)

    fn set_attribute(inout self, key: PropertyKey, value: Border):
        """Set a border attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        self._border = value
        self.properties = self.properties.set(key)

    fn set_attribute(inout self, key: PropertyKey, value: Bool):
        """Set a boolean attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if value:
            self.attrs = self.attrs.set(key)
        else:
            self.attrs = self.attrs.unset(key)

        # Set the prop
        self.properties = self.properties.set(key)

    fn set_attribute(inout self, key: PropertyKey, value: Int):
        """Set a int attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if key == WIDTH_KEY:
            self._width = max(0, value)
        elif key == HEIGHT_KEY:
            self._height = max(0, value)
        elif key == PADDING_TOP_KEY:
            self._padding_top = max(0, value)
        elif key == PADDING_RIGHT_KEY:
            self._padding_right = max(0, value)
        elif key == PADDING_BOTTOM_KEY:
            self._padding_bottom = max(0, value)
        elif key == PADDING_LEFT_KEY:
            self._padding_left = max(0, value)
        elif key == MARGIN_TOP_KEY:
            self._margin_top = max(0, value)
        elif key == MARGIN_RIGHT_KEY:
            self._margin_right = max(0, value)
        elif key == MARGIN_BOTTOM_KEY:
            self._margin_bottom = max(0, value)
        elif key == MARGIN_LEFT_KEY:
            self._margin_left = max(0, value)
        elif key == MAX_WIDTH_KEY:
            self._max_width = max(0, value)
        elif key == MAX_HEIGHT_KEY:
            self._max_height = max(0, value)
        elif key == TAB_WIDTH_KEY:
            self._tab_width = value

        # Set the prop
        self.properties = self.properties.set(key)

    fn set_attribute(inout self, key: PropertyKey, value: Position):
        """Set a Position attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if key == HORIZONTAL_ALIGNMENT_KEY:
            self._horizontal_alignment = value
        elif key == VERTICAL_ALIGNMENT_KEY:
            self._vertical_alignment = value

        # Set the prop
        self.properties = self.properties.set(key)

    fn set_attribute(inout self, key: PropertyKey, value: AnyTerminalColor):
        """Set a int attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if key == FOREGROUND_KEY:
            self._fg = value
        elif key == BACKGROUND_KEY:
            self._bg = value
        elif key == MARGIN_BACKGROUND_KEY:
            self._margin_bg = value
        elif key == BORDER_TOP_FOREGROUND_KEY:
            self._border_top_fg = value
        elif key == BORDER_RIGHT_FOREGROUND_KEY:
            self._border_right_fg = value
        elif key == BORDER_BOTTOM_FOREGROUND_KEY:
            self._border_bottom_fg = value
        elif key == BORDER_LEFT_FOREGROUND_KEY:
            self._border_left_fg = value
        elif key == BORDER_TOP_BACKGROUND_KEY:
            self._border_top_bg = value
        elif key == BORDER_RIGHT_BACKGROUND_KEY:
            self._border_right_bg = value
        elif key == BORDER_BOTTOM_BACKGROUND_KEY:
            self._border_bottom_bg = value
        elif key == BORDER_LEFT_BACKGROUND_KEY:
            self._border_left_bg = value

        # Set the prop
        self.properties = self.properties.set(key)

    fn unset_attribute(inout self, key: PropertyKey):
        """Set a boolean attribute on the style.

        Args:
            key: The key to set.
        """
        self.properties = self.properties.unset(key)

    fn set_renderer(self, renderer: Renderer) -> Style:
        """Set the renderer for the style.

        Args:
            renderer: The renderer to set.

        Returns:
            A new Style object with the renderer set.
        """
        var new_style = self
        new_style.renderer = renderer
        return new_style

    fn set_string(self, value: String) -> Style:
        """Set the string value for the style.

        Args:
            value: The string value to set.

        Returns:
            A new Style object with the string value set.
        """
        var new_style = self
        new_style.value = value
        return new_style

    fn tab_width(self, width: Int) -> Style:
        """Sets the number of spaces that a tab (/t) should be rendered as.
        When set to 0, tabs will be removed. To disable the replacement of tabs with
        spaces entirely, set this to [NO_TAB_CONVERSION].

        By default, tabs will be replaced with 4 spaces.

        Args:
            width: The tab width to apply.

        Returns:
            A new Style object with the tab width rule set.
        """
        var n = -1 if width <= -1 else width
        var new = self
        new.set_attribute(TAB_WIDTH_KEY, n)
        return new

    fn unset_tab_width(self) -> Style:
        """Unset the tab width of the text.

        Returns:
            A new Style object with the tab width rule unset.
        """
        var new = self
        new.unset_attribute(TAB_WIDTH_KEY)
        return new

    fn underline_spaces(self, value: Bool = True) -> Style:
        """Determines whether to underline spaces between words.
        Spaces can also be underlined without underlining the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the crossout rule set.
        """
        var new = self
        new.set_attribute(UNDERLINE_SPACES_KEY, value)
        return new

    fn unset_underline_spaces(self) -> Style:
        """Unset the underline spaces rule.

        Returns:
            A new Style object with the underline spaces rule unset.
        """
        var new = self
        new.unset_attribute(UNDERLINE_SPACES_KEY)
        return new

    fn crossout_spaces(self, value: Bool = True) -> Style:
        """Determines whether to crossout spaces between words. Spaces can also be
        crossed out without crossout on the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the crossout rule set.
        """
        var new = self
        new.set_attribute(CROSSOUT_SPACES_KEY, value)
        return new

    fn unset_crossout_spaces(self) -> Style:
        """Unset the crossout spaces rule.

        Returns:
            A new Style object with the crossout spaces rule unset.
        """
        var new = self
        new.unset_attribute(CROSSOUT_SPACES_KEY)
        return new

    fn color_whitespace(self, value: Bool = True) -> Style:
        """Determines whether to color whitespace.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the color whitespace rule set.
        """
        var new = self
        new.set_attribute(COLOR_WHITESPACE_KEY, value)
        return new

    fn unset_color_whitespace(self) -> Style:
        """Unset the color whitespace rule.

        Returns:
            A new Style object with the color whitespace rule unset.
        """
        var new = self
        new.unset_attribute(COLOR_WHITESPACE_KEY)
        return new

    fn inline(self, value: Bool = True) -> Style:
        """Makes rendering output one line and disables the rendering of
        margins, padding and borders. This is useful when you need a style to apply
        only to font rendering and don't want it to change any physical dimensions.
        It works well with Style.max_width.

        Because this in intended to be used at the time of render, this method will
        not mutate the style and instead return a copy.

        Example:
        ```mojo
        var user_input: String = "..."
        var user_style = mog.Style().inline(True)
        print(user_style.render(user_input))
        ```

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the bold rule set.
        """
        var new = self
        new.set_attribute(INLINE_KEY, value)
        return new

    fn get_inline(self) -> Bool:
        """Returns whether or not the inline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self.get_as_bool(INLINE_KEY, False)

    fn unset_inline(self) -> Style:
        """Unset the inline rule.

        Returns:
            A new Style object with the inline rule unset.
        """
        var new = self
        new.unset_attribute(INLINE_KEY)
        return new

    fn bold(self, value: Bool = True) -> Style:
        """Set the text to be bold.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the bold rule set.
        """
        var new = self
        new.set_attribute(BOLD_KEY, value)
        return new

    fn get_bold(self) -> Bool:
        """Returns whether or not the bold rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self.get_as_bool(BOLD_KEY, False)

    fn italic(self, value: Bool = True) -> Style:
        """Set the text to be italic.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the italic rule set.
        """
        var new = self
        new.set_attribute(ITALIC_KEY, value)
        return new

    fn get_italic(self) -> Bool:
        """Returns whether or not the italic rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self.get_as_bool(ITALIC_KEY, False)

    fn underline(self, value: Bool = True) -> Style:
        """Set the text to be underline.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the underline rule set.
        """
        var new = self
        new.set_attribute(UNDERLINE_KEY, value)
        return new

    fn crossout(self, value: Bool = True) -> Style:
        """Set the text to be crossed out.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the crossout rule set.
        """
        var new = self
        new.set_attribute(CROSSOUT_KEY, value)
        return new

    fn reverse(self, value: Bool = True) -> Style:
        """Set the text have the foreground and background colors reversed.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the reverse rule set.
        """
        var new = self
        new.set_attribute(REVERSE_KEY, value)
        return new

    fn blink(self, value: Bool = True) -> Style:
        """Set the text to blink.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the blink rule set.
        """
        var new = self
        new.set_attribute(BLINK_KEY, value)
        return new

    fn faint(self, value: Bool = True) -> Style:
        """Set the text to be faint.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the faint rule set.
        """
        var new = self
        new.set_attribute(FAINT_KEY, value)
        return new

    fn unset_bold(self) -> Style:
        """Unset the bold rule.

        Returns:
            A new Style object with the bold rule unset.
        """
        var new = self
        new.unset_attribute(BOLD_KEY)
        return new

    fn unset_italic(self) -> Style:
        """Unset the italic rule.

        Returns:
            A new Style object with the italic rule unset.
        """
        var new = self
        new.unset_attribute(ITALIC_KEY)
        return new

    fn unset_underline(self) -> Style:
        """Unset the text to be underline.

        Returns:
            A new Style object with the underline rule set.
        """
        var new = self
        new.unset_attribute(UNDERLINE_KEY)
        return new

    fn unset_crossout(self) -> Style:
        """Unset the crossout rule.

        Returns:
            A new Style object with the crossout rule unset.
        """
        var new = self
        new.unset_attribute(CROSSOUT_KEY)
        return new

    fn unset_reverse(self) -> Style:
        """Unset the reverse rule.

        Returns:
            A new Style object with the reverse rule unset.
        """
        var new = self
        new.unset_attribute(REVERSE_KEY)
        return new

    fn unset_blink(self) -> Style:
        """Unset the blink rule.

        Returns:
            A new Style object with the blink rule unset.
        """
        var new = self
        new.unset_attribute(BLINK_KEY)
        return new

    fn unset_faint(self) -> Style:
        """Unset the text to be faint.

        Returns:
            A new Style object with the faint rule unset.
        """
        var new = self
        new.unset_attribute(FAINT_KEY)
        return new

    fn width(self, width: Int) -> Style:
        """Set the width of the text.

        Args:
            width: The width to apply.

        Returns:
            A new Style object with the width rule set.
        """
        var new = self
        new.set_attribute(WIDTH_KEY, width)
        return new

    fn unset_width(self) -> Style:
        """Unset the width of the text.

        Returns:
            A new Style object with the width rule unset.
        """
        var new = self
        new.unset_attribute(WIDTH_KEY)
        return new

    fn height(self, height: Int) -> Style:
        """Set the height of the text.

        Args:
            height: The height to apply.

        Returns:
            A new Style object with the height rule set.
        """
        var new = self
        new.set_attribute(HEIGHT_KEY, height)
        return new

    fn unset_height(self) -> Style:
        """Unset the height of the text.

        Returns:
            A new Style object with the height rule unset.
        """
        var new = self
        new.unset_attribute(HEIGHT_KEY)
        return new

    fn max_width(self, width: Int) -> Style:
        """Applies a max width to a given style. This is useful in enforcing
        a certain width at render time, particularly with arbitrary strings and
        styles.

        Because this in intended to be used at the time of render, this method will
        not mutate the style and instead return a copy.

        Example:
        ```mojo
        var user_input: String = "..."
        var user_style = mog.Style().max_width(16)
        print(user_style.render(user_input))
        ```

        Args:
            width: The maximum height to apply.

        Returns:
            A new Style object with the maximum width rule set.
        """
        var new = self
        new.set_attribute(MAX_WIDTH_KEY, width)
        return new

    fn unset_max_width(self) -> Style:
        """Unset the max width of the text.

        Returns:
            A new Style object with the max width rule unset.
        """
        var new = self
        new.unset_attribute(MAX_WIDTH_KEY)
        return new

    fn max_height(self, height: Int) -> Style:
        """Set the maximum height of the text.

        Args:
            height: The maximum height to apply.

        Returns:
            A new Style object with the maximum height rule set.
        """
        var new = self
        new.set_attribute(MAX_HEIGHT_KEY, height)
        return new

    fn unset_max_height(self) -> Style:
        """Unset the max height of the text.

        Returns:
            A new Style object with the max height rule unset.
        """
        var new = self
        new.unset_attribute(MAX_HEIGHT_KEY)
        return new

    fn horizontal_alignment(self, align: Position) -> Style:
        """Set the horizontal alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style object with the alignment rule set.
        """
        var new = self
        new.set_attribute(HORIZONTAL_ALIGNMENT_KEY, align)
        return new

    fn unset_horizontal_alignment(self) -> Style:
        """Unset the horizontal alignment of the text.

        Returns:
            A new Style object with the horizontal alignment rule unset.
        """
        var new = self
        new.unset_attribute(HORIZONTAL_ALIGNMENT_KEY)
        return new

    fn vertical_alignment(self, align: Position) -> Style:
        """Set the vertical alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style object with the alignment rule set.
        """
        var new = self
        new.set_attribute(VERTICAL_ALIGNMENT_KEY, align)
        return new

    fn unset_vertical_alignment(self) -> Style:
        """Unset the vertical alignment of the text.

        Returns:
            A new Style object with the vertical alignment rule unset.
        """
        var new = self
        new.unset_attribute(VERTICAL_ALIGNMENT_KEY)
        return new

    fn alignment(self, *align: Position) -> Style:
        """Align is a shorthand method for setting horizontal and vertical alignment.

        With one argument, the position value is applied to the horizontal alignment.

        With two arguments, the value is applied to the horizontal and vertical
        alignments, in that order.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style object with the alignment rules set.
        """
        var new = self

        if len(align) > 0:
            new.set_attribute(HORIZONTAL_ALIGNMENT_KEY, align[0])
        if len(align) > 1:
            new.set_attribute(VERTICAL_ALIGNMENT_KEY, align[1])
        return new

    fn foreground(self, color: AnyTerminalColor) -> Style:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the foreground color rule set.
        """
        var new = self
        new.set_attribute(FOREGROUND_KEY, color)
        return new

    fn unset_foreground(self) -> Style:
        """Unset the foreground color of the text.

        Returns:
            A new Style object with the foreground color rule unset.
        """
        var new = self
        new.unset_attribute(FOREGROUND_KEY)
        return new

    fn background(self, color: AnyTerminalColor) -> Style:
        """Set the background color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the background color rule set.
        """
        var new = self
        new.set_attribute(BACKGROUND_KEY, color)
        return new

    fn unset_background(self) -> Style:
        """Unset the background color of the text.

        Returns:
            A new Style object with the background color rule unset.
        """
        var new = self
        new.unset_attribute(BACKGROUND_KEY)
        return new

    fn border(self, border: Border, *sides: Bool) -> Style:
        """Set the border style of the text.

        Args:
            border: The border style to apply.
            sides: The sides to apply the border to.

        Returns:
            A new Style object with the border rule set.
        """
        var new = self
        new.set_attribute(BORDER_STYLE_KEY, border)
        var top = True
        var right = True
        var bottom = True
        var left = True

        var sides_specified = len(sides)
        if sides_specified == 1:
            top = sides[0]
            bottom = sides[0]
            left = sides[0]
            right = sides[0]
        elif sides_specified == 2:
            top = sides[0]
            bottom = sides[0]
            left = sides[1]
            right = sides[1]
        elif sides_specified == 3:
            top = sides[0]
            left = sides[1]
            right = sides[1]
            bottom = sides[2]
        elif sides_specified == 4:
            top = sides[0]
            right = sides[1]
            bottom = sides[2]
            left = sides[3]

        new.set_attribute(BORDER_TOP_KEY, top)
        new.set_attribute(BORDER_RIGHT_KEY, right)
        new.set_attribute(BORDER_BOTTOM_KEY, bottom)
        new.set_attribute(BORDER_LEFT_KEY, left)
        return new

    fn border_top(self, top: Bool) -> Style:
        """Sets the top border to be rendered or not.

        Args:
            top: Whether to apply the border to the top side.

        Returns:
            A new Style object with the border rule set.
        """
        var new = self
        new.set_attribute(BORDER_TOP_KEY, top)
        return new

    fn unset_border_top(self) -> Style:
        """Unsets the top border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_TOP_KEY)
        return new

    fn border_bottom(self, bottom: Bool) -> Style:
        """Sets the bottom border to be rendered or not.

        Args:
            bottom: Whether to apply the border to the bottom side.

        Returns:
            A new Style object with the border rule set.
        """
        var new = self
        new.set_attribute(BORDER_BOTTOM_KEY, bottom)
        return new

    fn unset_border_bottom(self) -> Style:
        """Unsets the bottom border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_BOTTOM_KEY)
        return new

    fn border_left(self, left: Bool) -> Style:
        """Sets the left border to be rendered or not.

        Args:
            left: Whether to apply the border to the left side.

        Returns:
            A new Style object with the border rule set.
        """
        var new = self
        new.set_attribute(BORDER_LEFT_KEY, left)
        return new

    fn unset_border_left(self) -> Style:
        """Unsets the left border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_LEFT_KEY)
        return new

    fn border_right(self, right: Bool) -> Style:
        """Sets the right border to be rendered or not.

        Args:
            right: Whether to apply the border to the right side.

        Returns:
            A new Style object with the border rule set.
        """
        var new = self
        new.set_attribute(BORDER_RIGHT_KEY, right)
        return new

    fn unset_border_right(self) -> Style:
        """Unsets the right border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        var new = self
        new.unset_attribute(TAB_WIDTH_KEY)
        return new

    fn border_foreground(self, *colors: AnyTerminalColor) -> Style:
        """Set the border foreground color.

        Args:
            colors: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        var top: AnyTerminalColor = NoColor()
        var bottom: AnyTerminalColor = NoColor()
        var left: AnyTerminalColor = NoColor()
        var right: AnyTerminalColor = NoColor()
        var new = self
        var widths_specified = len(colors)
        if widths_specified == 1:
            top = colors[0]
            bottom = colors[0]
            left = colors[0]
            right = colors[0]
        elif widths_specified == 2:
            top = colors[0]
            bottom = colors[0]
            left = colors[1]
            right = colors[1]
        elif widths_specified == 3:
            top = colors[0]
            left = colors[1]
            right = colors[1]
            bottom = colors[2]
        elif widths_specified == 4:
            top = colors[0]
            right = colors[1]
            bottom = colors[2]
            left = colors[3]
        else:
            return new

        new.set_attribute(BORDER_TOP_FOREGROUND_KEY, top)
        new.set_attribute(BORDER_RIGHT_FOREGROUND_KEY, right)
        new.set_attribute(BORDER_BOTTOM_FOREGROUND_KEY, bottom)
        new.set_attribute(BORDER_LEFT_FOREGROUND_KEY, left)
        return new

    fn border_top_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the top border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_TOP_FOREGROUND_KEY)
        new._border_top_fg = color
        return new

    fn unset_border_top_foreground(self) -> Style:
        """Unsets the top border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_TOP_FOREGROUND_KEY)
        return new

    fn border_right_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the right border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_RIGHT_FOREGROUND_KEY)
        new._border_right_fg = color
        return new

    fn unset_border_right_foreground(self) -> Style:
        """Unsets the right border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_RIGHT_FOREGROUND_KEY)
        return new

    fn border_left_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the left border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_LEFT_FOREGROUND_KEY)
        new._border_left_fg = color
        return new

    fn unset_border_left_foreground(self) -> Style:
        """Unsets the left border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_LEFT_FOREGROUND_KEY)
        return new

    fn border_bottom_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the bottom border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_BOTTOM_FOREGROUND_KEY)
        new._border_bottom_fg = color
        return new

    fn unset_border_bottom_foreground(self) -> Style:
        """Unsets the bottom border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_BOTTOM_FOREGROUND_KEY)
        return new

    fn border_background(self, *colors: AnyTerminalColor) -> Style:
        """Set the border background color.

        Args:
            colors: The colors to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        var top: AnyTerminalColor = NoColor()
        var bottom: AnyTerminalColor = NoColor()
        var left: AnyTerminalColor = NoColor()
        var right: AnyTerminalColor = NoColor()
        var new = self
        var widths_specified = len(colors)
        if widths_specified == 1:
            top = colors[0]
            bottom = colors[0]
            left = colors[0]
            right = colors[0]
        elif widths_specified == 2:
            top = colors[0]
            bottom = colors[0]
            left = colors[1]
            right = colors[1]
        elif widths_specified == 3:
            top = colors[0]
            left = colors[1]
            right = colors[1]
            bottom = colors[2]
        elif widths_specified == 4:
            top = colors[0]
            right = colors[1]
            bottom = colors[2]
            left = colors[3]
        else:
            return new

        new.set_attribute(BORDER_TOP_BACKGROUND_KEY, top)
        new.set_attribute(BORDER_RIGHT_BACKGROUND_KEY, right)
        new.set_attribute(BORDER_BOTTOM_BACKGROUND_KEY, bottom)
        new.set_attribute(BORDER_LEFT_BACKGROUND_KEY, left)
        return new

    fn border_top_background(self, color: AnyTerminalColor) -> Style:
        """Set the top border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_TOP_BACKGROUND_KEY)
        new._border_top_bg = color
        return new

    fn unset_border_top_background(self) -> Style:
        """Unsets the top border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_TOP_BACKGROUND_KEY)
        return new

    fn border_right_background(self, color: AnyTerminalColor) -> Style:
        """Set the right border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_RIGHT_BACKGROUND_KEY)
        new._border_right_bg = color
        return new

    fn unset_border_right_background(self) -> Style:
        """Unsets the right border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_RIGHT_BACKGROUND_KEY)
        return new

    fn border_left_background(self, color: AnyTerminalColor) -> Style:
        """Set the left border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_LEFT_BACKGROUND_KEY)
        new._border_left_bg = color
        return new

    fn unset_border_left_background(self) -> Style:
        """Unsets the left border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_LEFT_BACKGROUND_KEY)
        return new

    fn border_bottom_background(self, color: AnyTerminalColor) -> Style:
        """Set the bottom border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        var new = self
        new.properties = new.properties.set(BORDER_BOTTOM_BACKGROUND_KEY)
        new._border_bottom_bg = color
        return new

    fn unset_border_bottom_background(self) -> Style:
        """Unsets the bottom border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        var new = self
        new.unset_attribute(BORDER_BOTTOM_BACKGROUND_KEY)
        return new

    fn padding(self, *widths: Int) -> Style:
        """Shorthand method for setting padding on all sides at once.

        With one argument, the value is applied to all sides.

        With two arguments, the value is applied to the vertical and horizontal
        sides, in that order.

        With three arguments, the value is applied to the top side, the horizontal
        sides, and the bottom side, in that order.

        With four arguments, the value is applied clockwise starting from the top
        side, followed by the right side, then the bottom, and finally the left.

        With more than four arguments no padding will be added.

        Args:
            widths: The padding widths to apply.
        
        Returns:
            A new Style object with the padding rule set.
        """
        var top = 0
        var bottom = 0
        var left = 0
        var right = 0
        var new = self
        var widths_specified = len(widths)
        if widths_specified == 1:
            top = widths[0]
            bottom = widths[0]
            left = widths[0]
            right = widths[0]
        elif widths_specified == 2:
            top = widths[0]
            bottom = widths[0]
            left = widths[1]
            right = widths[1]
        elif widths_specified == 3:
            top = widths[0]
            left = widths[1]
            right = widths[1]
            bottom = widths[2]
        elif widths_specified == 4:
            top = widths[0]
            right = widths[1]
            bottom = widths[2]
            left = widths[3]
        else:
            return new

        new.set_attribute(PADDING_TOP_KEY, top)
        new.set_attribute(PADDING_RIGHT_KEY, right)
        new.set_attribute(PADDING_BOTTOM_KEY, bottom)
        new.set_attribute(PADDING_LEFT_KEY, left)
        return new

    fn padding_top(self, width: Int) -> Style:
        """Set the padding on the top side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding top rule set.
        """
        var new = self
        new.set_attribute(PADDING_TOP_KEY, width)
        return new

    fn unset_padding_top(self) -> Style:
        """Unset the padding top rule.

        Returns:
            A new Style object with the padding top rule unset.
        """
        var new = self
        new.unset_attribute(PADDING_TOP_KEY)
        return new

    fn padding_right(self, width: Int) -> Style:
        """Set the padding on the right side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding right rule set.
        """
        var new = self
        new.set_attribute(PADDING_RIGHT_KEY, width)
        return new

    fn unset_padding_right(self) -> Style:
        """Unset the padding right rule.

        Returns:
            A new Style object with the padding right rule unset.
        """
        var new = self
        new.unset_attribute(PADDING_RIGHT_KEY)
        return new

    fn padding_bottom(self, width: Int) -> Style:
        """Set the padding on the bottom side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding bottom rule set.
        """
        var new = self
        new.set_attribute(PADDING_BOTTOM_KEY, width)
        return new

    fn unset_padding_bottom(self) -> Style:
        """Unset the padding bottom rule.

        Returns:
            A new Style object with the padding bottom rule unset.
        """
        var new = self
        new.unset_attribute(PADDING_BOTTOM_KEY)
        return new

    fn padding_left(self, width: Int) -> Style:
        """Set the padding on the left side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding left rule set.
        """
        var new = self
        new.set_attribute(PADDING_LEFT_KEY, width)
        return new

    fn unset_padding_left(self) -> Style:
        """Unset the padding left rule.

        Returns:
            A new Style object with the padding left rule unset.
        """
        var new = self
        new.unset_attribute(PADDING_LEFT_KEY)
        return new

    fn margin(self, *widths: Int) -> Style:
        """Shorthand method for setting padding on all sides at once.

        With one argument, the value is applied to all sides.

        With two arguments, the value is applied to the vertical and horizontal
        sides, in that order.

        With three arguments, the value is applied to the top side, the horizontal
        sides, and the bottom side, in that order.

        With four arguments, the value is applied clockwise starting from the top
        side, followed by the right side, then the bottom, and finally the left.

        With more than four arguments no padding will be added.

        Args:
            widths: The padding widths to apply.

        Returns:
            A new Style object with the margin rule set.
        """
        var top = 0
        var bottom = 0
        var left = 0
        var right = 0
        var new = self
        var widths_specified = len(widths)
        if widths_specified == 1:
            top = widths[0]
            bottom = widths[0]
            left = widths[0]
            right = widths[0]
        elif widths_specified == 2:
            top = widths[0]
            bottom = widths[0]
            left = widths[1]
            right = widths[1]
        elif widths_specified == 3:
            top = widths[0]
            left = widths[1]
            right = widths[1]
            bottom = widths[2]
        elif widths_specified == 4:
            top = widths[0]
            right = widths[1]
            bottom = widths[2]
            left = widths[3]
        else:
            return new

        new.set_attribute(MARGIN_TOP_KEY, top)
        new.set_attribute(MARGIN_RIGHT_KEY, right)
        new.set_attribute(MARGIN_BOTTOM_KEY, bottom)
        new.set_attribute(MARGIN_LEFT_KEY, left)
        return new

    fn margin_top(self, width: Int) -> Style:
        """Set the margin on the top side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin top rule set.
        """
        var new = self
        new.set_attribute(MARGIN_TOP_KEY, width)
        return new

    fn unset_margin_top(self) -> Style:
        """Unset the margin top rule.

        Returns:
            A new Style object with the margin top rule unset.
        """
        var new = self
        new.unset_attribute(MARGIN_TOP_KEY)
        return new

    fn margin_right(self, width: Int) -> Style:
        """Set the margin on the right side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin right rule set.
        """
        var new = self
        new.set_attribute(MARGIN_RIGHT_KEY, width)
        return new

    fn unset_margin_right(self) -> Style:
        """Unset the margin right rule.

        Returns:
            A new Style object with the margin right rule unset.
        """
        var new = self
        new.unset_attribute(MARGIN_RIGHT_KEY)
        return new

    fn margin_bottom(self, width: Int) -> Style:
        """Set the margin on the bottom side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin bottom rule set.
        """
        var new = self
        new.set_attribute(MARGIN_BOTTOM_KEY, width)
        return new

    fn unset_margin_bottom(self) -> Style:
        """Unset the margin bottom rule.

        Returns:
            A new Style object with the margin bottom rule unset.
        """
        var new = self
        new.unset_attribute(MARGIN_BOTTOM_KEY)
        return new

    fn margin_left(self, width: Int) -> Style:
        """Set the margin on the left side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin left rule set.
        """
        var new = self
        new.set_attribute(MARGIN_LEFT_KEY, width)
        return new

    fn unset_margin_left(self) -> Style:
        """Unset the margin left rule.

        Returns:
            A new Style object with the margin left rule unset.
        """
        var new = self
        new.unset_attribute(MARGIN_LEFT_KEY)
        return new

    fn margin_background(self, color: AnyTerminalColor) -> Style:
        """Set the margin on the background color.

        Args:
            color: The margin width to apply.

        Returns:
            A new Style object with the margin background rule set.
        """
        var new = self
        new.set_attribute(MARGIN_BACKGROUND_KEY, color)
        return new

    fn unset_margin_background(self) -> Style:
        """Unset the margin background rule.

        Returns:
            A new Style object with the margin background rule unset.
        """
        var new = self
        new.unset_attribute(MARGIN_BACKGROUND_KEY)
        return new

    fn maybe_convert_tabs(self, text: String) -> String:
        """Convert tabs to spaces if the tab width is set.

        Args:
            text: The text to convert tabs in.

        Returns:
            The text with tabs converted to spaces.
        """
        var DEFAULT_TAB_WIDTH = TAB_WIDTH
        if self.is_set(TAB_WIDTH_KEY):
            DEFAULT_TAB_WIDTH = self.get_as_int(TAB_WIDTH_KEY)

        if DEFAULT_TAB_WIDTH == -1:
            return text
        if DEFAULT_TAB_WIDTH == 0:
            return text.replace("\t", "")
        else:
            return text.replace("\t", (WHITESPACE * DEFAULT_TAB_WIDTH))

    fn style_border(self, border: String, fg: AnyTerminalColor, bg: AnyTerminalColor) -> String:
        """Style a border with foreground and background colors.

        Args:
            border: The border to style.
            fg: The foreground color.
            bg: The background color.

        Returns:
            The styled border.
        """
        if fg.isa[NoColor]() and bg.isa[NoColor]():
            return border

        var styler = mist.Style()

        # Sooooo verbose compared to just passing the string value. But this is closer to the lipgloss API.
        # It's more verbose because we can't pass around args with trait as the arg type.
        if fg.isa[Color]():
            styler = styler.foreground(color=fg[Color].color(self.renderer))
        elif fg.isa[ANSIColor]():
            styler = styler.foreground(color=fg[ANSIColor].color(self.renderer))
        elif fg.isa[AdaptiveColor]():
            styler = styler.foreground(color=fg[AdaptiveColor].color(self.renderer))
        elif fg.isa[CompleteColor]():
            styler = styler.foreground(color=fg[CompleteColor].color(self.renderer))
        elif fg.isa[CompleteAdaptiveColor]():
            styler = styler.foreground(color=fg[CompleteAdaptiveColor].color(self.renderer))

        if bg.isa[Color]():
            styler = styler.background(color=bg[Color].color(self.renderer))
        elif bg.isa[ANSIColor]():
            styler = styler.background(color=bg[ANSIColor].color(self.renderer))
        elif bg.isa[AdaptiveColor]():
            styler = styler.background(color=bg[AdaptiveColor].color(self.renderer))
        elif bg.isa[CompleteColor]():
            styler = styler.background(color=bg[CompleteColor].color(self.renderer))
        elif bg.isa[CompleteAdaptiveColor]():
            styler = styler.background(color=bg[CompleteAdaptiveColor].color(self.renderer))

        return styler.render(border)

    fn apply_border(self, text: String) -> String:
        """Apply a border to the text.

        Args:
            text: The text to apply the border to.

        Returns:
            The text with the border applied.
        """
        var top_set = self.is_set(BORDER_TOP_KEY)
        var right_set = self.is_set(BORDER_RIGHT_KEY)
        var bottom_set = self.is_set(BORDER_BOTTOM_KEY)
        var left_set = self.is_set(BORDER_LEFT_KEY)

        var border = self.get_border_style()
        var has_top = self.get_as_bool(BORDER_TOP_KEY)
        var has_right = self.get_as_bool(BORDER_RIGHT_KEY)
        var has_bottom = self.get_as_bool(BORDER_BOTTOM_KEY)
        var has_left = self.get_as_bool(BORDER_LEFT_KEY)

        # FG Colors
        var top_fg = self.get_as_color(BORDER_TOP_FOREGROUND_KEY)
        var right_fg = self.get_as_color(BORDER_RIGHT_FOREGROUND_KEY)
        var bottom_fg = self.get_as_color(BORDER_BOTTOM_FOREGROUND_KEY)
        var left_fg = self.get_as_color(BORDER_LEFT_FOREGROUND_KEY)

        # BG Colors
        var top_bg = self.get_as_color(BORDER_TOP_BACKGROUND_KEY)
        var right_bg = self.get_as_color(BORDER_RIGHT_BACKGROUND_KEY)
        var bottom_bg = self.get_as_color(BORDER_BOTTOM_BACKGROUND_KEY)
        var left_bg = self.get_as_color(BORDER_LEFT_BACKGROUND_KEY)

        # If a border is set and no sides have been specifically turned on or off
        # render borders on all sides.
        var borderless = NO_BORDER
        if border != borderless and not (top_set or right_set or bottom_set or left_set):
            has_top = True
            has_right = True
            has_bottom = True
            has_left = True

        # If no border is set or all borders are been disabled, abort.
        if border == borderless or (not has_top and not has_right and not has_bottom and not has_left):
            return text

        var lines: List[String]
        var width: Int
        lines, width = get_lines(text)

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

        var result = String(capacity=int(len(text) * 1.5))

        # Render top
        if has_top:
            top = self.style_border(
                render_horizontal_edge(border.top_left, border.top, border.top_right, width),
                top_fg,
                top_bg
            )
            result.write(top, NEWLINE)

        # Render sides
        for i in range(len(lines)):
            var line = lines[i]
            if has_left:
                result.write(self.style_border(border.left, left_fg, left_bg))

            result.write(line)

            if has_right:
                result.write(self.style_border(border.right, right_fg, right_bg))

            if i < len(lines) - 1:
                result.write(NEWLINE)

        # Render bottom
        if has_bottom:
            bottom = self.style_border(
                render_horizontal_edge(border.bottom_left, border.bottom, border.bottom_right, width),
                bottom_fg,
                bottom_bg
            )
            result.write(NEWLINE, bottom)

        return result

    fn apply_margins(self, owned text: String, inline: Bool) -> String:
        """Apply margins to the text.

        Args:
            text: The text to apply the margins to.
            inline: Whether the text is inline or not.
        
        Returns:
            The text with the margins applied.
        """
        var top_margin = self.get_as_int(MARGIN_TOP_KEY)
        var right_margin = self.get_as_int(MARGIN_RIGHT_KEY)
        var bottom_margin = self.get_as_int(MARGIN_BOTTOM_KEY)
        var left_margin = self.get_as_int(MARGIN_LEFT_KEY)

        var styler = mist.Style(self.renderer.color_profile.value)

        var bgc = self.get_as_color(MARGIN_BACKGROUND_KEY)

        # TODO: Dealing with variants is verbose :(
        if bgc.isa[Color]():
            styler = styler.background(color=bgc[Color].color(self.renderer))
        elif bgc.isa[ANSIColor]():
            styler = styler.background(color=bgc[ANSIColor].color(self.renderer))
        elif bgc.isa[AdaptiveColor]():
            styler = styler.background(color=bgc[AdaptiveColor].color(self.renderer))
        elif bgc.isa[CompleteColor]():
            styler = styler.background(color=bgc[CompleteColor].color(self.renderer))
        elif bgc.isa[CompleteAdaptiveColor]():
            styler = styler.background(color=bgc[CompleteAdaptiveColor].color(self.renderer))

        # Add left and right margin
        text = pad_left(text, left_margin, styler)
        text = pad_right(text, right_margin, styler)

        # Top/bottom margin
        if not inline:
            _, width = get_lines(text)
            if top_margin > 0:
                text = ((WHITESPACE * width + NEWLINE) * top_margin) + text
            if bottom_margin > 0:
                text.write((NEWLINE + WHITESPACE * width) * bottom_margin)

        return text

    fn render(self, *texts: String) -> String:
        """Render the text with the style.

        Args:
            texts: The strings to render.

        Returns:
            The rendered text.
        """
        # If style has internal string, add it first. Join arbitrary list of texts into a single string.
        var input_text = String()
        if self.value != "":
            input_text.write(self.value)

        for i in range(len(texts)):
            input_text.write(texts[i])
            if i != len(texts) - 1:
                input_text.write(" ")

        var term_style = mist.Style(self.renderer.color_profile.value)
        var term_style_space = term_style
        var term_style_whitespace = term_style

        var bold = self.get_as_bool(BOLD_KEY, False)
        var italic = self.get_as_bool(ITALIC_KEY, False)
        var underline = self.get_as_bool(UNDERLINE_KEY, False)
        var crossout = self.get_as_bool(CROSSOUT_KEY, False)
        var reverse = self.get_as_bool(REVERSE_KEY, False)
        var blink = self.get_as_bool(BLINK_KEY, False)
        var faint = self.get_as_bool(FAINT_KEY, False)

        var fg = self.get_as_color(FOREGROUND_KEY)
        var bg = self.get_as_color(BACKGROUND_KEY)

        var width = self.get_as_int(WIDTH_KEY)
        var height = self.get_as_int(HEIGHT_KEY)
        var top_padding = self.get_as_int(PADDING_TOP_KEY)
        var right_padding = self.get_as_int(PADDING_RIGHT_KEY)
        var bottom_padding = self.get_as_int(PADDING_BOTTOM_KEY)
        var left_padding = self.get_as_int(PADDING_LEFT_KEY)

        var horizontal_align = self.get_as_position(HORIZONTAL_ALIGNMENT_KEY)
        var vertical_align = self.get_as_position(VERTICAL_ALIGNMENT_KEY)

        var color_whitespace = self.get_as_bool(COLOR_WHITESPACE_KEY, True)
        var inline = self.get_as_bool(INLINE_KEY, False)
        var max_width = self.get_as_int(MAX_WIDTH_KEY)
        var max_height = self.get_as_int(MAX_HEIGHT_KEY)

        var underline_spaces = self.get_as_bool(UNDERLINE_SPACES_KEY, False) or (
            underline and self.get_as_bool(UNDERLINE_SPACES_KEY, True)
        )
        var crossout_spaces = self.get_as_bool(CROSSOUT_SPACES_KEY, False) or (
            crossout and self.get_as_bool(CROSSOUT_SPACES_KEY, True)
        )

        # Do we need to style whitespace (padding and space outside paragraphs) separately?
        var use_whitespace_styler = reverse

        # Do we need to style spaces separately?
        var use_space_styler = underline_spaces or crossout_spaces

        # transform = self.get_as_transform("transform")
        # If no style properties are set, return the input text as is with tabs maybe converted.
        if not any(self.properties.value):
            return self.maybe_convert_tabs(input_text)

        if bold:
            term_style = term_style.bold()
        if italic:
            term_style = term_style.italic()
        if underline:
            term_style = term_style.underline()
        if reverse:
            term_style = term_style.reverse()
            term_style_whitespace = term_style_whitespace.reverse()
        if blink:
            term_style = term_style.blink()
        if faint:
            term_style = term_style.faint()
        if crossout:
            term_style = term_style.crossout()

        # TODO: Again super verbose and repetitive bc of Variant
        if fg.isa[Color]():
            var terminal_color = fg[Color].color(self.renderer)
            term_style = term_style.foreground(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(color=terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(color=terminal_color)
        elif fg.isa[ANSIColor]():
            var terminal_color = fg[ANSIColor].color(self.renderer)
            term_style = term_style.foreground(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(color=terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(color=terminal_color)
        elif fg.isa[AdaptiveColor]():
            var terminal_color = fg[AdaptiveColor].color(self.renderer)
            term_style = term_style.foreground(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(color=terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(color=terminal_color)
        elif fg.isa[CompleteColor]():
            var terminal_color = fg[CompleteColor].color(self.renderer)
            term_style = term_style.foreground(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(color=terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(color=terminal_color)
        elif fg.isa[CompleteAdaptiveColor]():
            var terminal_color = fg[CompleteAdaptiveColor].color(self.renderer)
            term_style = term_style.foreground(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(color=terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(color=terminal_color)

        if bg.isa[Color]():
            var terminal_color = bg[Color].color(self.renderer)
            term_style = term_style.background(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(color=terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(color=terminal_color)
        elif bg.isa[ANSIColor]():
            var terminal_color = bg[ANSIColor].color(self.renderer)
            term_style = term_style.background(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(color=terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(color=terminal_color)
        elif bg.isa[AdaptiveColor]():
            var terminal_color = bg[AdaptiveColor].color(self.renderer)
            term_style = term_style.background(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(color=terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(color=terminal_color)
        elif bg.isa[CompleteColor]():
            var terminal_color = bg[CompleteColor].color(self.renderer)
            term_style = term_style.background(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(color=terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(color=terminal_color)
        elif bg.isa[CompleteAdaptiveColor]():
            var terminal_color = bg[CompleteAdaptiveColor].color(self.renderer)
            term_style = term_style.background(color=terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(color=terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(color=terminal_color)

        if underline_spaces:
            term_style = term_style_space.underline()
        if crossout_spaces:
            term_style = term_style_space.crossout()

        if inline:
            input_text = input_text.replace(NEWLINE, "")

        # Word wrap
        if (not inline) and (width > 0):
            var wrap_at = width - left_padding - right_padding
            input_text = word_wrap(input_text, wrap_at)
            input_text = wrap(input_text, wrap_at)  # force-wrap long strings

        input_text = self.maybe_convert_tabs(input_text)

        var result = String(capacity=int(len(input_text) * 1.5))
        var lines = input_text.splitlines()

        for i in range(len(lines)):
            if use_space_styler:
                # Look for spaces and apply a different styler
                for char in lines[i]:
                    if char == " ":
                        result.write(term_style_space.render(char))
                    else:
                        result.write(term_style.render(char))
            else:
                result.write(term_style.render(lines[i]))

            # Readd the newlines
            if i != len(lines) - 1:
                result.write(NEWLINE)

        # Padding
        if not inline:
            if left_padding > 0:
                var style = mist.Style(self.renderer.color_profile.value)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                result = pad_left(result, left_padding, style)

            if right_padding > 0:
                var style = mist.Style(self.renderer.color_profile.value)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                result = pad_right(result, right_padding, style)

            if top_padding > 0:
                result = (NEWLINE * top_padding) + result

            if bottom_padding > 0:
                result += NEWLINE * bottom_padding

        # Alignment
        if height > 0:
            result = align_text_vertical(result, vertical_align, height)

        # Truncate according to max_width
        if max_width > 0:
            var lines = result.splitlines()
            for i in range(len(lines)):
                lines[i] = truncate(lines[i], max_width)

            result = NEWLINE.join(lines)

        # Truncate according to max_height
        if max_height > 0:
            var lines = result.splitlines()
            var truncated_lines = lines[0 : min(max_height, len(lines))]
            result = NEWLINE.join(truncated_lines)

        # if transform:
        #     return transform(result)

        lines = result.splitlines()
        if width != 0:
            var style = mist.Style(self.renderer.color_profile.value)
            if color_whitespace or use_whitespace_styler:
                style = term_style_whitespace
            result = align_text_horizontal(result, horizontal_align, width, style)

        # Apply border at the end
        if not inline:
            result = self.apply_border(result)
            result = self.apply_margins(result, inline)

        return result
