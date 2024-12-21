from collections import Optional
from utils import StringSlice
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
from .extensions import get_lines, get_widest_line, pad_left, pad_right
from .properties import Properties, PropKey, Dimensions, Padding, Margin, Coloring, BorderColor, Alignment
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
    any_terminal_color_to_any_color,
)
from weave import wrap, word_wrap, truncate
from weave.ansi import printable_rune_width
import mist


alias TAB_WIDTH = 4
"""The default tab width to use when rendering text with tabs."""

alias NO_TAB_CONVERSION = -1
"""Used to disable the replacement of tabs with spaces at render time."""


@value
struct Style:
    """Terminal styler.

    #### Usage:
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
    var _color: Coloring
    """The coloring of the text."""
    var _dimensions: Dimensions
    """The dimensions of the text."""
    var _max_dimensions: Dimensions
    """The maximum dimensions of the text."""
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

    var _tab_width: Int
    """The number of spaces that a tab (/t) should be rendered as."""

    fn __init__(out self, color_profile: Int = -1, *, value: String = ""):
        """Initialize A new Style.

        Args:
            color_profile: The color profile to use. Defaults to None, which means it'll be queried at run time instead.
            value: Internal string value to apply the style to. Not required, but useful for reusing some string you want to format multiple times.
        """
        self._renderer = Renderer(color_profile)
        self._properties = Properties()
        self._value = value
        self._attrs = Properties()
        self._color = Coloring()
        self._dimensions = Dimensions()
        self._max_dimensions = Dimensions()
        self._alignment = Alignment()
        self._padding = Padding()
        self._margin = Margin()
        self._border = NO_BORDER
        self._border_color = BorderColor()
        self._tab_width = 0

    fn _get_as_bool(self, key: Int, default: Bool = False) -> Bool:
        """Get a rule as a boolean value.

        Args:
            key: The key to get.
            default: The default value to return if the rule is not set.

        Returns:
            The boolean value.
        """
        if not self._is_set(key):
            return default

        return self._attrs.has(key)

    fn _get_as_color(self, key: Int) -> AnyTerminalColor:
        """Get a rule as an AnyTerminalColor value.

        Args:
            key: The key to get.

        Returns:
            The color value.
        """
        if not self._is_set(key):
            return NoColor()

        if key == PropKey.FOREGROUND:
            return self._color.foreground
        elif key == PropKey.BACKGROUND:
            return self._color.background
        elif key == PropKey.BORDER_TOP_FOREGROUND:
            return self._border_color.foreground_top
        elif key == PropKey.BORDER_RIGHT_FOREGROUND:
            return self._border_color.foreground_right
        elif key == PropKey.BORDER_BOTTOM_FOREGROUND:
            return self._border_color.foreground_bottom
        elif key == PropKey.BORDER_LEFT_FOREGROUND:
            return self._border_color.foreground_left
        elif key == PropKey.BORDER_TOP_BACKGROUND:
            return self._border_color.background_top
        elif key == PropKey.BORDER_RIGHT_BACKGROUND:
            return self._border_color.background_right
        elif key == PropKey.BORDER_BOTTOM_BACKGROUND:
            return self._border_color.background_bottom
        elif key == PropKey.BORDER_LEFT_BACKGROUND:
            return self._border_color.background_left
        elif key == PropKey.MARGIN_BACKGROUND:
            return self._margin.background
        else:
            return NoColor()

    fn _get_as_int(self, key: Int) -> Int:
        """Get a rule as an integer value.

        Args:
            key: The key to get.

        Returns:
            The integer value.
        """
        if not self._is_set(key):
            return 0

        if key == PropKey.WIDTH:
            return self._dimensions.width
        elif key == PropKey.HEIGHT:
            return self._dimensions.height
        elif key == PropKey.PADDING_TOP:
            return self._padding.top
        elif key == PropKey.PADDING_RIGHT:
            return self._padding.right
        elif key == PropKey.PADDING_BOTTOM:
            return self._padding.bottom
        elif key == PropKey.PADDING_LEFT:
            return self._padding.left
        elif key == PropKey.MARGIN_TOP:
            return self._margin.top
        elif key == PropKey.MARGIN_RIGHT:
            return self._margin.right
        elif key == PropKey.MARGIN_BOTTOM:
            return self._margin.bottom
        elif key == PropKey.MARGIN_LEFT:
            return self._margin.left
        elif key == PropKey.MAX_WIDTH:
            return self._max_dimensions.width
        elif key == PropKey.MAX_HEIGHT:
            return self._max_dimensions.height
        elif key == PropKey.TAB_WIDTH:
            return self._tab_width
        else:
            return 0

    fn _get_as_position(self, key: Int) -> Position:
        """Get a rule as a Position value.

        Args:
            key: The key to get.

        Returns:
            The Position value.
        """
        if not self._is_set(key):
            return 0

        if key == PropKey.HORIZONTAL_ALIGNMENT:
            return self._alignment.horizontal
        elif key == PropKey.VERTICAL_ALIGNMENT:
            return self._alignment.vertical
        else:
            return 0

    fn _get_border_style(self) -> Border:
        """Get the Border style rule.

        Returns:
            The Border style.
        """
        if not self._is_set(PropKey.BORDER_STYLE):
            return Border()

        return self._border

    fn _is_set(self, key: Int) -> Bool:
        """Check if a rule is set on the style.

        Args:
            key: The key to check.

        Returns:
            True if the rule is set, False otherwise.
        """
        return self._properties.has(key)

    fn _set_attribute(mut self, key: Int, value: Border):
        """Set a border attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        self._border = value
        self._properties.set(key, True)

    fn _set_attribute(mut self, key: Int, value: Bool):
        """Set a boolean attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        # Mark the attribute as active
        self._attrs.set(key, value)

        # Set the value
        self._properties.set(key, value)

    fn _set_attribute(mut self, key: Int, value: Int):
        """Set a int attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if key == PropKey.WIDTH:
            self._dimensions.width = max(0, value)
        elif key == PropKey.HEIGHT:
            self._dimensions.height = max(0, value)
        elif key == PropKey.PADDING_TOP:
            self._padding.top = max(0, value)
        elif key == PropKey.PADDING_RIGHT:
            self._padding.right = max(0, value)
        elif key == PropKey.PADDING_BOTTOM:
            self._padding.bottom = max(0, value)
        elif key == PropKey.PADDING_LEFT:
            self._padding.left = max(0, value)
        elif key == PropKey.MARGIN_TOP:
            self._margin.top = max(0, value)
        elif key == PropKey.MARGIN_RIGHT:
            self._margin.right = max(0, value)
        elif key == PropKey.MARGIN_BOTTOM:
            self._margin.bottom = max(0, value)
        elif key == PropKey.MARGIN_LEFT:
            self._margin.left = max(0, value)
        elif key == PropKey.MAX_WIDTH:
            self._max_dimensions.width = max(0, value)
        elif key == PropKey.MAX_HEIGHT:
            self._max_dimensions.height = max(0, value)
        elif key == PropKey.TAB_WIDTH:
            self._tab_width = value

        # Set the prop
        self._properties.set(key, True)

    fn _set_attribute(mut self, key: Int, value: Position):
        """Set a Position attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if key == PropKey.HORIZONTAL_ALIGNMENT:
            self._alignment.horizontal = value
        elif key == PropKey.VERTICAL_ALIGNMENT:
            self._alignment.vertical = value

        # Set the prop
        self._properties.set(key, True)

    fn _set_attribute(mut self, key: Int, value: AnyTerminalColor):
        """Set a int attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if key == PropKey.FOREGROUND:
            self._color.foreground = value
        elif key == PropKey.BACKGROUND:
            self._color.background = value
        elif key == PropKey.MARGIN_BACKGROUND:
            self._margin.background = value
        elif key == PropKey.BORDER_TOP_FOREGROUND:
            self._border_color.foreground_top = value
        elif key == PropKey.BORDER_RIGHT_FOREGROUND:
            self._border_color.foreground_right = value
        elif key == PropKey.BORDER_BOTTOM_FOREGROUND:
            self._border_color.foreground_bottom = value
        elif key == PropKey.BORDER_LEFT_FOREGROUND:
            self._border_color.foreground_left = value
        elif key == PropKey.BORDER_TOP_BACKGROUND:
            self._border_color.background_top = value
        elif key == PropKey.BORDER_RIGHT_BACKGROUND:
            self._border_color.background_right = value
        elif key == PropKey.BORDER_BOTTOM_BACKGROUND:
            self._border_color.background_bottom = value
        elif key == PropKey.BORDER_LEFT_BACKGROUND:
            self._border_color.background_left = value

        # Set the prop
        self._properties.set(key, True)

    fn _unset_attribute(mut self, key: Int):
        """Set a boolean attribute on the style.

        Args:
            key: The key to set.
        """
        self._properties.set(key, False)
    
    fn _get_mist_style(self) -> mist.Style:
        """Returns a the `mist.Style` using the same profile as the `mog.Style` for the style.

        Returns:
            The mist profile.
        """
        return mist.Style(self._renderer.profile)

    fn renderer(self, /, renderer: Renderer) -> Style:
        """Set the renderer for the style.

        Args:
            renderer: The renderer to set.

        Returns:
            A new Style with the renderer set.
        """
        var new = self
        new._renderer = renderer
        return new

    fn value(self, /, value: String) -> Style:
        """Set the string value for the style.

        Args:
            value: The string value to set.

        Returns:
            A new Style with the string value set.
        """
        var new = self
        new._value = value
        return new

    fn tab_width(self, /, width: Int) -> Style:
        """Sets the number of spaces that a tab (/t) should be rendered as.
        When set to 0, tabs will be removed. To disable the replacement of tabs with
        spaces entirely, set this to [NO_TAB_CONVERSION].

        By default, tabs will be replaced with 4 spaces.

        Args:
            width: The tab width to apply.

        Returns:
            A new Style with the tab width rule set.
        """
        var n = -1 if width <= -1 else width
        var new = self
        new._set_attribute(PropKey.TAB_WIDTH, n)
        return new

    fn unset_tab_width(self) -> Style:
        """Unset the tab width of the text.

        Returns:
            A new Style with the tab width rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.TAB_WIDTH)
        return new

    fn underline_spaces(self, /, value: Bool = True) -> Style:
        """Determines whether to underline spaces between words.
        Spaces can also be underlined without underlining the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the crossout rule set.
        """
        var new = self
        new._set_attribute(PropKey.UNDERLINE_SPACES, value)
        return new
    
    fn get_underline_spaces(self) -> Bool:
        """Returns whether or not the underline spaces rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.UNDERLINE_SPACES, False)

    fn unset_underline_spaces(self) -> Style:
        """Unset the underline spaces rule.

        Returns:
            A new Style with the underline spaces rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.UNDERLINE_SPACES)
        return new

    fn crossout_spaces(self, /, value: Bool = True) -> Style:
        """Determines whether to crossout spaces between words. Spaces can also be
        crossed out without crossout on the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the crossout rule set.
        """
        var new = self
        new._set_attribute(PropKey.CROSSOUT_SPACES, value)
        return new
    
    fn get_crossout_spaces(self) -> Bool:
        """Returns whether or not the crossout spaces rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.CROSSOUT_SPACES, False)

    fn unset_crossout_spaces(self) -> Style:
        """Unset the crossout spaces rule.

        Returns:
            A new Style with the crossout spaces rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.CROSSOUT_SPACES)
        return new

    fn color_whitespace(self, /, value: Bool = True) -> Style:
        """Determines whether to color whitespace.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the color whitespace rule set.
        """
        var new = self
        new._set_attribute(PropKey.COLOR_WHITESPACE, value)
        return new
    
    fn get_color_whitespace(self) -> Bool:
        """Returns whether or not the color whitespace rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.COLOR_WHITESPACE, False)

    fn unset_color_whitespace(self) -> Style:
        """Unset the color whitespace rule.

        Returns:
            A new Style with the color whitespace rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.COLOR_WHITESPACE)
        return new

    fn inline(self, /, value: Bool = True) -> Style:
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
        var input = "..."
        var style = mog.Style().inline()
        print(style.render(input))
        ```
        .
        """
        var new = self
        new._set_attribute(PropKey.INLINE, value)
        return new

    fn get_inline(self) -> Bool:
        """Returns whether or not the inline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.INLINE, False)

    fn unset_inline(self) -> Style:
        """Unset the inline rule.

        Returns:
            A new Style with the inline rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.INLINE)
        return new

    fn bold(self, /, value: Bool = True) -> Style:
        """Set the text to be bold.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the bold rule set.
        """
        var new = self
        new._set_attribute(PropKey.BOLD, value)
        return new

    fn get_bold(self) -> Bool:
        """Returns whether or not the bold rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.BOLD, False)
    
    fn unset_bold(self) -> Style:
        """Unset the bold rule.

        Returns:
            A new Style with the bold rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BOLD)
        return new

    fn italic(self, /, value: Bool = True) -> Style:
        """Set the text to be italic.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the italic rule set.
        """
        var new = self
        new._set_attribute(PropKey.ITALIC, value)
        return new

    fn get_italic(self) -> Bool:
        """Returns whether or not the italic rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.ITALIC, False)
    
    fn unset_italic(self) -> Style:
        """Unset the italic rule.

        Returns:
            A new Style with the italic rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.ITALIC)
        return new

    fn underline(self, /, value: Bool = True) -> Style:
        """Set the text to be underline.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the underline rule set.
        """
        var new = self
        new._set_attribute(PropKey.UNDERLINE, value)
        return new
    
    fn get_underline(self) -> Bool:
        """Returns whether or not the underline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.UNDERLINE, False)
    
    fn unset_underline(self) -> Style:
        """Unset the text to be underline.

        Returns:
            A new Style with the underline rule set.
        """
        var new = self
        new._unset_attribute(PropKey.UNDERLINE)
        return new

    fn crossout(self, /, value: Bool = True) -> Style:
        """Set the text to be crossed out.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the crossout rule set.
        """
        var new = self
        new._set_attribute(PropKey.CROSSOUT, value)
        return new
    
    fn get_crossout(self) -> Bool:
        """Returns whether or not the crossout rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.CROSSOUT, False)
    
    fn unset_crossout(self) -> Style:
        """Unset the crossout rule.

        Returns:
            A new Style with the crossout rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.CROSSOUT)
        return new

    fn reverse(self, /, value: Bool = True) -> Style:
        """Set the text have the foreground and background colors reversed.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the reverse rule set.
        """
        var new = self
        new._set_attribute(PropKey.REVERSE, value)
        return new
    
    fn get_reverse(self) -> Bool:
        """Returns whether or not the reverse rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.REVERSE, False)
    
    fn unset_reverse(self) -> Style:
        """Unset the reverse rule.

        Returns:
            A new Style with the reverse rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.REVERSE)
        return new

    fn blink(self, /, value: Bool = True) -> Style:
        """Set the text to blink.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the blink rule set.
        """
        var new = self
        new._set_attribute(PropKey.BLINK, value)
        return new
    
    fn get_blink(self) -> Bool:
        """Returns whether or not the blink rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.BLINK, False)
    
    fn unset_blink(self) -> Style:
        """Unset the blink rule.

        Returns:
            A new Style with the blink rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BLINK)
        return new

    fn faint(self, /, value: Bool = True) -> Style:
        """Set the text to be faint.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the faint rule set.
        """
        var new = self
        new._set_attribute(PropKey.FAINT, value)
        return new
    
    fn get_faint(self) -> Bool:
        """Returns whether or not the faint rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool(PropKey.FAINT, False)
    
    fn unset_faint(self) -> Style:
        """Unset the text to be faint.

        Returns:
            A new Style with the faint rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.FAINT)
        return new

    fn width(self, width: Int) -> Style:
        """Set the width of the text.

        Args:
            width: The width to apply.

        Returns:
            A new Style with the width rule set.
        
        #### Notes:
        If you need width to be truncated to obey the width rule, use `Style.max_width()` instead.
        """
        var new = self
        new._set_attribute(PropKey.WIDTH, width)
        return new

    fn unset_width(self) -> Style:
        """Unset the width of the text.

        Returns:
            A new Style with the width rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.WIDTH)
        return new

    fn height(self, height: Int) -> Style:
        """Set the height of the text.
        If the height of the text being styled is greater than height, then this is a noop.

        Args:
            height: The height to apply.

        Returns:
            A new Style with the height rule set.
        
        #### Notes:
        If you need height to be truncated to obey the height rule, use `Style.max_height()` instead.
        """
        var new = self
        new._set_attribute(PropKey.HEIGHT, height)
        return new

    fn unset_height(self) -> Style:
        """Unset the height of the text.

        Returns:
            A new Style with the height rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.HEIGHT)
        return new

    fn max_width(self, width: Int) -> Style:
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
        var user_style = mog.Style().max_width(16)
        print(user_style.render(user_input))
        ```
        .
        """
        var new = self
        new._set_attribute(PropKey.MAX_WIDTH, width)
        return new

    fn unset_max_width(self) -> Style:
        """Unset the max width of the text.

        Returns:
            A new Style with the max width rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MAX_WIDTH)
        return new

    fn max_height(self, height: Int) -> Style:
        """Set the maximum height of the text.
        This enforces a max height by only rendering the first n lines.

        Args:
            height: The maximum height to apply.

        Returns:
            A new Style with the maximum height rule set.
        
        #### Notes:
        This does **NOT** pad the lines to the max height, if you want to pad all lines to the height given use `Style.height()` instead.
        """
        var new = self
        new._set_attribute(PropKey.MAX_HEIGHT, height)
        return new

    fn unset_max_height(self) -> Style:
        """Unset the max height of the text.

        Returns:
            A new Style with the max height rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MAX_HEIGHT)
        return new

    fn horizontal_alignment(self, align: Position) -> Style:
        """Set the horizontal alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style with the alignment rule set.
        """
        var new = self
        new._set_attribute(PropKey.HORIZONTAL_ALIGNMENT, align)
        return new

    fn unset_horizontal_alignment(self) -> Style:
        """Unset the horizontal alignment of the text.

        Returns:
            A new Style with the horizontal alignment rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.HORIZONTAL_ALIGNMENT)
        return new

    fn vertical_alignment(self, align: Position) -> Style:
        """Set the vertical alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style with the alignment rule set.
        """
        var new = self
        new._set_attribute(PropKey.VERTICAL_ALIGNMENT, align)
        return new

    fn unset_vertical_alignment(self) -> Style:
        """Unset the vertical alignment of the text.

        Returns:
            A new Style with the vertical alignment rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.VERTICAL_ALIGNMENT)
        return new

    fn alignment(self, *align: Position) -> Style:
        """Align is a shorthand method for setting horizontal and vertical alignment.

        With one argument, the position value is applied to the horizontal alignment.

        With two arguments, the value is applied to the horizontal and vertical
        alignments, in that order.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self

        if len(align) > 0:
            new._set_attribute(PropKey.HORIZONTAL_ALIGNMENT, align[0])
        if len(align) > 1:
            new._set_attribute(PropKey.VERTICAL_ALIGNMENT, align[1])
        return new

    fn foreground(self, color: AnyTerminalColor) -> Style:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the foreground color rule set.
        """
        var new = self
        new._set_attribute(PropKey.FOREGROUND, color)
        return new

    fn unset_foreground(self) -> Style:
        """Unset the foreground color of the text.

        Returns:
            A new Style with the foreground color rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.FOREGROUND)
        return new

    fn background(self, color: AnyTerminalColor) -> Style:
        """Set the background color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the background color rule set.
        """
        var new = self
        new._set_attribute(PropKey.BACKGROUND, color)
        return new

    fn unset_background(self) -> Style:
        """Unset the background color of the text.

        Returns:
            A new Style with the background color rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BACKGROUND)
        return new

    fn border(self, border: Border, *sides: Bool) -> Style:
        """Set the border style of the text.

        Args:
            border: The border style to apply.
            sides: The sides to apply the border to.

        Returns:
            A new Style with the border rule set.
        """
        var new = self
        new._set_attribute(PropKey.BORDER_STYLE, border)
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

        new._set_attribute(PropKey.BORDER_TOP, top)
        new._set_attribute(PropKey.BORDER_RIGHT, right)
        new._set_attribute(PropKey.BORDER_BOTTOM, bottom)
        new._set_attribute(PropKey.BORDER_LEFT, left)
        return new

    fn border_top(self, /, top: Bool = True) -> Style:
        """Sets the top border to be rendered or not.

        Args:
            top: Whether to apply the border to the top side.

        Returns:
            A new Style with the border rule set.
        """
        var new = self
        new._set_attribute(PropKey.BORDER_TOP, top)
        return new

    fn unset_border_top(self) -> Style:
        """Unsets the top border rule.

        Returns:
            A new Style with the border rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_TOP)
        return new

    fn border_bottom(self, /, bottom: Bool = True) -> Style:
        """Sets the bottom border to be rendered or not.

        Args:
            bottom: Whether to apply the border to the bottom side.

        Returns:
            A new Style with the border rule set.
        """
        var new = self
        new._set_attribute(PropKey.BORDER_BOTTOM, bottom)
        return new

    fn unset_border_bottom(self) -> Style:
        """Unsets the bottom border rule.

        Returns:
            A new Style with the border rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_BOTTOM)
        return new

    fn border_left(self, /, left: Bool = True) -> Style:
        """Sets the left border to be rendered or not.

        Args:
            left: Whether to apply the border to the left side.

        Returns:
            A new Style with the border rule set.
        """
        var new = self
        new._set_attribute(PropKey.BORDER_LEFT, left)
        return new

    fn unset_border_left(self) -> Style:
        """Unsets the left border rule.

        Returns:
            A new Style with the border rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_LEFT)
        return new

    fn border_right(self, /, right: Bool = True) -> Style:
        """Sets the right border to be rendered or not.

        Args:
            right: Whether to apply the border to the right side.

        Returns:
            A new Style with the border rule set.
        """
        var new = self
        new._set_attribute(PropKey.BORDER_RIGHT, right)
        return new

    fn unset_border_right(self) -> Style:
        """Unsets the right border rule.

        Returns:
            A new Style with the border rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_RIGHT)
        return new

    fn border_foreground(self, *colors: AnyTerminalColor) -> Style:
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

        new._set_attribute(PropKey.BORDER_TOP_FOREGROUND, top)
        new._set_attribute(PropKey.BORDER_RIGHT_FOREGROUND, right)
        new._set_attribute(PropKey.BORDER_BOTTOM_FOREGROUND, bottom)
        new._set_attribute(PropKey.BORDER_LEFT_FOREGROUND, left)
        return new

    fn border_top_foreground(self, /, color: AnyTerminalColor) -> Style:
        """Set the top border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border foreground color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_TOP_FOREGROUND, True)
        new._border_color.foreground_top = color
        return new

    fn unset_border_top_foreground(self) -> Style:
        """Unsets the top border foreground rule.

        Returns:
            A new Style with the border foreground rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_TOP_FOREGROUND)
        return new

    fn border_right_foreground(self, /, color: AnyTerminalColor) -> Style:
        """Set the right border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border foreground color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_RIGHT_FOREGROUND, True)
        new._border_color.foreground_right = color
        return new

    fn unset_border_right_foreground(self) -> Style:
        """Unsets the right border foreground rule.

        Returns:
            A new Style with the border foreground rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_RIGHT_FOREGROUND)
        return new

    fn border_left_foreground(self, /, color: AnyTerminalColor) -> Style:
        """Set the left border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border foreground color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_LEFT_FOREGROUND, True)
        new._border_color.foreground_left = color
        return new

    fn unset_border_left_foreground(self) -> Style:
        """Unsets the left border foreground rule.

        Returns:
            A new Style with the border foreground rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_LEFT_FOREGROUND)
        return new

    fn border_bottom_foreground(self, /, color: AnyTerminalColor) -> Style:
        """Set the bottom border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border foreground color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_BOTTOM_FOREGROUND, True)
        new._border_color.foreground_bottom = color
        return new

    fn unset_border_bottom_foreground(self) -> Style:
        """Unsets the bottom border foreground rule.

        Returns:
            A new Style with the border foreground rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_BOTTOM_FOREGROUND)
        return new

    fn border_background(self, *colors: AnyTerminalColor) -> Style:
        """Set the border background color.

        Args:
            colors: The colors to apply.

        Returns:
            A new Style with the border background color rule set.
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

        new._set_attribute(PropKey.BORDER_TOP_BACKGROUND, top)
        new._set_attribute(PropKey.BORDER_RIGHT_BACKGROUND, right)
        new._set_attribute(PropKey.BORDER_BOTTOM_BACKGROUND, bottom)
        new._set_attribute(PropKey.BORDER_LEFT_BACKGROUND, left)
        return new

    fn border_top_background(self, /, color: AnyTerminalColor) -> Style:
        """Set the top border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_TOP_BACKGROUND, True)
        new._border_color.background_top = color
        return new

    fn unset_border_top_background(self) -> Style:
        """Unsets the top border background rule.

        Returns:
            A new Style with the border background rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_TOP_BACKGROUND)
        return new

    fn border_right_background(self, /, color: AnyTerminalColor) -> Style:
        """Set the right border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_RIGHT_BACKGROUND, True)
        new._border_color.background_right = color
        return new

    fn unset_border_right_background(self) -> Style:
        """Unsets the right border background rule.

        Returns:
            A new Style with the border background rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_RIGHT_BACKGROUND)
        return new

    fn border_left_background(self, /, color: AnyTerminalColor) -> Style:
        """Set the left border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_LEFT_BACKGROUND, True)
        new._border_color.background_left = color
        return new

    fn unset_border_left_background(self) -> Style:
        """Unsets the left border background rule.

        Returns:
            A new Style with the border background rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_LEFT_BACKGROUND)
        return new

    fn border_bottom_background(self, /, color: AnyTerminalColor) -> Style:
        """Set the bottom border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the border background color rule set.
        """
        var new = self
        new._properties.set(PropKey.BORDER_BOTTOM_BACKGROUND, True)
        new._border_color.background_bottom = color
        return new

    fn unset_border_bottom_background(self) -> Style:
        """Unsets the bottom border background rule.

        Returns:
            A new Style with the border background rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.BORDER_BOTTOM_BACKGROUND)
        return new

    fn padding(self, *widths: Int) -> Style:
        """Shorthand method for setting padding on all sides at once.

        Args:
            widths: The padding widths to apply.

        Returns:
            A new Style with the padding rule set.
        
        #### Notes:
        Padding is applied inside the text area, inside of the border if there is one.
        Margin is applied outside the text area, outside of the border if there is one.
        * With one argument, the value is applied to all sides.
        * With two arguments, the value is applied to the vertical and horizontal
        sides, in that order.
        * With three arguments, the value is applied to the top side, the horizontal
        sides, and the bottom side, in that order.
        * With four arguments, the value is applied clockwise starting from the top
        side, followed by the right side, then the bottom, and finally the left.
        * With more than four arguments no padding will be added.
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

        new._set_attribute(PropKey.PADDING_TOP, top)
        new._set_attribute(PropKey.PADDING_RIGHT, right)
        new._set_attribute(PropKey.PADDING_BOTTOM, bottom)
        new._set_attribute(PropKey.PADDING_LEFT, left)
        return new

    fn padding_top(self, /, width: Int) -> Style:
        """Set the padding on the top side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style with the padding top rule set.
        
        #### Notes:
        Padding is applied inside the text area, inside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.PADDING_TOP, width)
        return new

    fn unset_padding_top(self) -> Style:
        """Unset the padding top rule.

        Returns:
            A new Style with the padding top rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.PADDING_TOP)
        return new

    fn padding_right(self, /, width: Int) -> Style:
        """Set the padding on the right side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style with the padding right rule set.
        
        #### Notes:
        Padding is applied inside the text area, inside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.PADDING_RIGHT, width)
        return new

    fn unset_padding_right(self) -> Style:
        """Unset the padding right rule.

        Returns:
            A new Style with the padding right rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.PADDING_RIGHT)
        return new

    fn padding_bottom(self, /, width: Int) -> Style:
        """Set the padding on the bottom side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style with the padding bottom rule set.
        
        #### Notes:
        Padding is applied inside the text area, inside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.PADDING_BOTTOM, width)
        return new

    fn unset_padding_bottom(self) -> Style:
        """Unset the padding bottom rule.

        Returns:
            A new Style with the padding bottom rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.PADDING_BOTTOM)
        return new

    fn padding_left(self, /, width: Int) -> Style:
        """Set the padding on the left side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style with the padding left rule set.
        
        #### Notes:
        Padding is applied inside the text area, inside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.PADDING_LEFT, width)
        return new

    fn unset_padding_left(self) -> Style:
        """Unset the padding left rule.

        Returns:
            A new Style with the padding left rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.PADDING_LEFT)
        return new

    fn margin(self, *widths: Int) -> Style:
        """Shorthand method for setting margin on all sides at once.

        Args:
            widths: The padding widths to apply.

        Returns:
            A new Style with the margin rule set.
        
        #### Notes:
        Padding is applied inside the text area, inside of the border if there is one.
        Margin is applied outside the text area, outside of the border if there is one.
        * With one argument, the value is applied to all sides.
        * With two arguments, the value is applied to the vertical and horizontal
        sides, in that order.
        * With three arguments, the value is applied to the top side, the horizontal
        sides, and the bottom side, in that order.
        * With four arguments, the value is applied clockwise starting from the top
        side, followed by the right side, then the bottom, and finally the left.
        * With more than four arguments no margin will be added.
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

        new._set_attribute(PropKey.MARGIN_TOP, top)
        new._set_attribute(PropKey.MARGIN_RIGHT, right)
        new._set_attribute(PropKey.MARGIN_BOTTOM, bottom)
        new._set_attribute(PropKey.MARGIN_LEFT, left)
        return new

    fn margin_top(self, /, width: Int) -> Style:
        """Set the margin on the top side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style with the margin top rule set.
        
        #### Notes:
        Margin is applied uotside the text area, outside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.MARGIN_TOP, width)
        return new

    fn unset_margin_top(self) -> Style:
        """Unset the margin top rule.

        Returns:
            A new Style with the margin top rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MARGIN_TOP)
        return new

    fn margin_right(self, /, width: Int) -> Style:
        """Set the margin on the right side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style with the margin right rule set.
        
        #### Notes:
        Margin is applied uotside the text area, outside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.MARGIN_RIGHT, width)
        return new

    fn unset_margin_right(self) -> Style:
        """Unset the margin right rule.

        Returns:
            A new Style with the margin right rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MARGIN_RIGHT)
        return new

    fn margin_bottom(self, /, width: Int) -> Style:
        """Set the margin on the bottom side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style with the margin bottom rule set.
        
        #### Notes:
        Margin is applied uotside the text area, outside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.MARGIN_BOTTOM, width)
        return new

    fn unset_margin_bottom(self) -> Style:
        """Unset the margin bottom rule.

        Returns:
            A new Style with the margin bottom rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MARGIN_BOTTOM)
        return new

    fn margin_left(self, /, width: Int) -> Style:
        """Set the margin on the left side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style with the margin left rule set.
        
        #### Notes:
        Margin is applied uotside the text area, outside of the border if there is one.
        """
        var new = self
        new._set_attribute(PropKey.MARGIN_LEFT, width)
        return new

    fn unset_margin_left(self) -> Style:
        """Unset the margin left rule.

        Returns:
            A new Style with the margin left rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MARGIN_LEFT)
        return new

    fn margin_background(self, /, color: AnyTerminalColor) -> Style:
        """Set the margin on the background color.

        Args:
            color: The margin width to apply.

        Returns:
            A new Style with the margin background rule set.
        """
        var new = self
        new._set_attribute(PropKey.MARGIN_BACKGROUND, color)
        return new

    fn unset_margin_background(self) -> Style:
        """Unset the margin background rule.

        Returns:
            A new Style with the margin background rule unset.
        """
        var new = self
        new._unset_attribute(PropKey.MARGIN_BACKGROUND)
        return new

    fn _maybe_convert_tabs(self, text: String) -> String:
        """Convert tabs to spaces if the tab width is set.

        Args:
            text: The text to convert tabs in.

        Returns:
            The text with tabs converted to spaces.
        """
        var DEFAULT_TAB_WIDTH = TAB_WIDTH
        if self._is_set(PropKey.TAB_WIDTH):
            DEFAULT_TAB_WIDTH = self._get_as_int(PropKey.TAB_WIDTH)

        if DEFAULT_TAB_WIDTH == -1:
            return text
        if DEFAULT_TAB_WIDTH == 0:
            return text.replace("\t", "")
        else:
            return text.replace("\t", (WHITESPACE * DEFAULT_TAB_WIDTH))

    fn _style_border(self, border: String, fg: AnyTerminalColor, bg: AnyTerminalColor) -> String:
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

        var styler = self._get_mist_style().foreground(color=any_terminal_color_to_any_color(fg, self._renderer)).background(
            color=any_terminal_color_to_any_color(bg, self._renderer)
        )
        return styler.render(border)

    fn _apply_border(self, text: String) -> String:
        """Apply a border to the text.

        Args:
            text: The text to apply the border to.

        Returns:
            The text with the border applied.
        """
        var top_set = self._is_set(PropKey.BORDER_TOP)
        var right_set = self._is_set(PropKey.BORDER_RIGHT)
        var bottom_set = self._is_set(PropKey.BORDER_BOTTOM)
        var left_set = self._is_set(PropKey.BORDER_LEFT)

        var border = self._get_border_style()
        var has_top = self._get_as_bool(PropKey.BORDER_TOP)
        var has_right = self._get_as_bool(PropKey.BORDER_RIGHT)
        var has_bottom = self._get_as_bool(PropKey.BORDER_BOTTOM)
        var has_left = self._get_as_bool(PropKey.BORDER_LEFT)

        # FG Colors
        var top_fg = self._get_as_color(PropKey.BORDER_TOP_FOREGROUND)
        var right_fg = self._get_as_color(PropKey.BORDER_RIGHT_FOREGROUND)
        var bottom_fg = self._get_as_color(PropKey.BORDER_BOTTOM_FOREGROUND)
        var left_fg = self._get_as_color(PropKey.BORDER_LEFT_FOREGROUND)

        # BG Colors
        var top_bg = self._get_as_color(PropKey.BORDER_TOP_BACKGROUND)
        var right_bg = self._get_as_color(PropKey.BORDER_RIGHT_BACKGROUND)
        var bottom_bg = self._get_as_color(PropKey.BORDER_BOTTOM_BACKGROUND)
        var left_bg = self._get_as_color(PropKey.BORDER_LEFT_BACKGROUND)

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
            top = self._style_border(
                render_horizontal_edge(border.top_left, border.top, border.top_right, width), top_fg, top_bg
            )
            result.write(top, NEWLINE)

        # Render sides once, and reuse for each line.
        var left_border: String = ""
        var right_border: String = ""
        if has_left:
            left_border = self._style_border(border.left, left_fg, left_bg)
        if has_right:
            right_border = self._style_border(border.right, right_fg, right_bg)

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
            bottom = self._style_border(
                render_horizontal_edge(border.bottom_left, border.bottom, border.bottom_right, width),
                bottom_fg,
                bottom_bg,
            )
            result.write(NEWLINE, bottom)

        return result

    fn _apply_margins(self, owned text: String, inline: Bool) -> String:
        """Apply margins to the text.

        Args:
            text: The text to apply the margins to.
            inline: Whether the text is inline or not.

        Returns:
            The text with the margins applied.
        """
        var top_margin = self._get_as_int(PropKey.MARGIN_TOP)
        var right_margin = self._get_as_int(PropKey.MARGIN_RIGHT)
        var bottom_margin = self._get_as_int(PropKey.MARGIN_BOTTOM)
        var left_margin = self._get_as_int(PropKey.MARGIN_LEFT)

        var bgc = self._get_as_color(PropKey.MARGIN_BACKGROUND)
        var styler = self._get_mist_style().background(color=any_terminal_color_to_any_color(bgc, self._renderer))

        # Add left and right margin
        text = pad_right(pad_left(text, left_margin, styler), right_margin, styler)

        # Top/bottom margin
        if not inline:
            width = get_widest_line(text)
            if top_margin > 0:
                text = ((WHITESPACE * width + NEWLINE) * top_margin) + text
            if bottom_margin > 0:
                text.write((NEWLINE + WHITESPACE * width) * bottom_margin)

        return text

    fn render[*Ts: Writable](self, *texts: *Ts) -> String:
        """Render the text with the style.

        Args:
            texts: The strings to render.

        Returns:
            The rendered text.
        """
        # If style has internal string, add it first. Join arbitrary list of texts into a single string.
        var input_text = String()
        if self._value != "":
            input_text.write(self._value)

        @parameter
        fn write_text[i: Int, T: Writable](text: T) -> None:
            input_text.write(text)
            if i != len(texts) - 1:
                input_text.write(" ")

        texts.each_idx[write_text]()

        var term_style = self._get_mist_style()
        var term_style_space = term_style
        var term_style_whitespace = term_style

        var bold = self._get_as_bool(PropKey.BOLD, False)
        var italic = self._get_as_bool(PropKey.ITALIC, False)
        var underline = self._get_as_bool(PropKey.UNDERLINE, False)
        var crossout = self._get_as_bool(PropKey.CROSSOUT, False)
        var reverse = self._get_as_bool(PropKey.REVERSE, False)
        var blink = self._get_as_bool(PropKey.BLINK, False)
        var faint = self._get_as_bool(PropKey.FAINT, False)

        var fg = self._get_as_color(PropKey.FOREGROUND)
        var bg = self._get_as_color(PropKey.BACKGROUND)

        var width = self._get_as_int(PropKey.WIDTH)
        var height = self._get_as_int(PropKey.HEIGHT)
        var top_padding = self._get_as_int(PropKey.PADDING_TOP)
        var right_padding = self._get_as_int(PropKey.PADDING_RIGHT)
        var bottom_padding = self._get_as_int(PropKey.PADDING_BOTTOM)
        var left_padding = self._get_as_int(PropKey.PADDING_LEFT)

        var horizontal_align = self._get_as_position(PropKey.HORIZONTAL_ALIGNMENT)
        var vertical_align = self._get_as_position(PropKey.VERTICAL_ALIGNMENT)

        var color_whitespace = self._get_as_bool(PropKey.COLOR_WHITESPACE, True)
        var inline = self._get_as_bool(PropKey.INLINE, False)
        var max_width = self._get_as_int(PropKey.MAX_WIDTH)
        var max_height = self._get_as_int(PropKey.MAX_HEIGHT)

        var underline_spaces = self._get_as_bool(PropKey.UNDERLINE_SPACES, False) or (
            underline and self._get_as_bool(PropKey.UNDERLINE_SPACES, True)
        )
        var crossout_spaces = self._get_as_bool(PropKey.CROSSOUT_SPACES, False) or (
            crossout and self._get_as_bool(PropKey.CROSSOUT_SPACES, True)
        )

        # Do we need to style whitespace (padding and space outside paragraphs) separately?
        var use_whitespace_styler = reverse

        # Do we need to style spaces separately?
        var use_space_styler = underline_spaces or crossout_spaces

        # transform = self.get_as_transform("transform")
        # If no style properties are set, return the input text as is with tabs maybe converted.
        if not any(self._properties.value):
            return self._maybe_convert_tabs(input_text)

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

        var fg_color = any_terminal_color_to_any_color(fg, self._renderer)
        var bg_color = any_terminal_color_to_any_color(bg, self._renderer)
        term_style = term_style.foreground(color=fg_color).background(color=bg_color)
        if use_space_styler:
            term_style_space = term_style_space.foreground(color=fg_color).background(color=bg_color)
        if color_whitespace:
            term_style_whitespace = term_style_whitespace.foreground(color=fg_color).background(color=bg_color)

        if underline_spaces:
            term_style_space = term_style_space.underline()
        if crossout_spaces:
            term_style_space = term_style_space.crossout()

        if inline:
            input_text = input_text.replace(NEWLINE, "")

        # Word wrap
        if (not inline) and (width > 0):
            var wrap_at = width - left_padding - right_padding
            input_text = wrap(word_wrap(input_text, wrap_at), wrap_at)  # force-wrap long strings

        input_text = self._maybe_convert_tabs(input_text)

        var result = String(capacity=int(len(input_text) * 1.5))

        # Even though String.splitlines allocates new strings, we need to add the newlines back in. Can't do it for a list of stringslice unfortunately.
        lines, _ = get_lines(input_text)
        for i in range(len(lines)):
            if use_space_styler:
                # Look for spaces and apply a different styler
                for char in lines[i]:
                    if char.isspace():
                        # While I could use a buffer for spaces, it would result in more frequent allocations.
                        # TODO: Maybe I can figure out how to use a space buffer without allocating too often.
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
                var style = self._get_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                result = pad_left(result, left_padding, style)

            if right_padding > 0:
                var style = self._get_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                result = pad_right(result, right_padding, style)

            if top_padding > 0:
                var new = String(capacity=len(result) + top_padding + 1)
                new.write(NEWLINE * top_padding, result)
                result = new

            if bottom_padding > 0:
                result.write(NEWLINE * bottom_padding)

        # Alignment
        if height > 0:
            result = align_text_vertical(result, vertical_align, height)
        
        if width != 0 or get_widest_line(result) != 0:
            var style = self._get_mist_style()
            if color_whitespace or use_whitespace_styler:
                style = term_style_whitespace
            result = align_text_horizontal(result, horizontal_align, width, style)
        
        # Apply border at the end
        if not inline:
            result = self._apply_margins(self._apply_border(result^), inline)

        # Truncate according to max_width
        if max_width > 0:
            lines, _ = get_lines(result)
            truncated = String(capacity=int(len(result) * 1.5))
            for i in range(len(lines)):
                truncated.write(truncate(lines[i], max_width))
                if i < len(lines) - 1:
                    truncated.write(NEWLINE)

            result = truncated

        # Truncate according to max_height
        if max_height > 0:
            lines, _ = get_lines(result)
            result = NEWLINE.join(lines[0 : min(max_height, len(lines))])

        # if transform:
        #     return transform(result)

        # if width != 0 or get_widest_line(result) != 0:
        #     var style = self._get_mist_style()
        #     if color_whitespace or use_whitespace_styler:
        #         style = term_style_whitespace
        #     result = align_text_horizontal(result, horizontal_align, width, style)

        # # Apply border at the end
        # if not inline:
        #     result = self._apply_margins(self._apply_border(result^), inline)

        return result
