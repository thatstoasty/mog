import mist
from mist.transform import truncate, word_wrap, wrap
from mist.transform.ansi import printable_rune_width
from mog._extensions import get_lines, get_widest_line, pad_left, pad_right
from mog._properties import Alignment, BorderColor, Coloring, Dimensions, Margin, Padding, Properties, PropKey, Side
from mog.align import align_text_horizontal, align_text_vertical
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


struct Style(Copyable, ImplicitlyCopyable, Movable):
    """Terminal styler.

    #### Usage:
    ```mojo
    import mog

    fn main():
        var style = (
            mog.Style(
                width=22,
                color=mog.Color(0xFAFAFA),
                background_color=mog.Color(0x7D56F4),
            )
            .bold_text()
            .set_padding(top=2, left=4)
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

    var _tab_width: UInt16
    """The number of spaces that a tab (/t) should be rendered as."""

    fn __init__(
        out self,
        renderer: Renderer,
        properties: Properties,
        var value: String,
        attrs: Properties,
        var color: Coloring,
        dimensions: Dimensions,
        max_dimensions: Dimensions,
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
            color: The coloring of the text.
            dimensions: The dimensions of the text.
            max_dimensions: The maximum dimensions of the text.
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
        self._color = color^
        self._dimensions = dimensions
        self._max_dimensions = max_dimensions
        self._alignment = alignment
        self._padding = padding
        self._margin = margin^
        self._border = border.copy()
        self._border_color = border_color^
        self._tab_width = tab_width
    
    fn __init__(
        out self,
        color_profile: Optional[mist.Profile] = None,
        width: Optional[Int] = None,
        height: Optional[Int] = None,
        max_width: Optional[Int] = None,
        max_height: Optional[Int] = None,
        color: AnyTerminalColor = NoColor(),
        background_color: AnyTerminalColor = NoColor(),
        border: Optional[Border] = None,
        var value: String = "",
    ):
        """Initialize A new Style.

        Args:
            color_profile: The renderer to use for the style, determines the color profile.
            width: TBD.
            height: TBD.
            max_width: TBD.
            max_height: TBD.
            color: Color of the text in the text area the style renders.
            background_color: Color of the background in the text area the style renders.
            border: TBD.
            value: TBD.
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
        self._dimensions = Dimensions()
        self._max_dimensions = Dimensions()
        self._color = Coloring()
        self._border = NO_BORDER.copy()

        if width:
            self._dimensions.width = width.value()
            self._set_attribute[PropKey.WIDTH](UInt16(width.value()))
        if height:
            self._dimensions.height = height.value()
            self._set_attribute[PropKey.HEIGHT](UInt16(height.value()))
        
        if max_width:
            self._max_dimensions.width = max_width.value()
            self._set_attribute[PropKey.WIDTH](UInt16(max_width.value()))
        if max_height:
            self._max_dimensions.height = max_height.value()
            self._set_attribute[PropKey.HEIGHT](UInt16(max_height.value()))

        if not color.is_same_type(NoColor()):
            self._color.foreground = color
            self._set_attribute[PropKey.FOREGROUND](color)
        if not background_color.is_same_type(NoColor()):
            self._color.background = background_color
            self._set_attribute[PropKey.BACKGROUND](background_color)

        if border:
            self._border = border.value().copy()
            self._set_attribute[PropKey.BORDER_STYLE](border.value())
            
            @parameter
            for key in [PropKey.BORDER_TOP, PropKey.BORDER_RIGHT, PropKey.BORDER_BOTTOM, PropKey.BORDER_LEFT]:
                self._set_attribute[key](value=True)


    # fn __init__(out self, color_profile: Optional[mist.Profile] = None, *, var value: String = ""):
    #     """Initialize A new Style.

    #     Args:
    #         color_profile: The color profile to use. Defaults to None, which means it'll be queried at run time instead.
    #         value: Internal string value to apply the style to. Not required, but useful for reusing some string you want to format multiple times.
    #     """
    #     self._renderer = Renderer(color_profile)
    #     self._properties = Properties()
    #     self._value = value^
    #     self._attrs = Properties()
    #     self._color = Coloring()
    #     self._dimensions = Dimensions()
    #     self._max_dimensions = Dimensions()
    #     self._alignment = Alignment()
    #     self._padding = Padding()
    #     self._margin = Margin()
    #     self._border = NO_BORDER.copy()
    #     self._border_color = BorderColor()
    #     self._tab_width = 0

    fn __moveinit__(out self, deinit other: Self):
        self._renderer = other._renderer
        self._properties = other._properties
        self._value = other._value^
        self._attrs = other._attrs
        self._color = other._color^
        self._dimensions = other._dimensions
        self._max_dimensions = other._max_dimensions
        self._alignment = other._alignment
        self._padding = other._padding
        self._margin = other._margin^
        self._border = other._border^
        self._border_color = other._border_color^
        self._tab_width = other._tab_width

    fn copy(self) -> Self:
        """Create a copy of the style.

        Returns:
            A new Style with the same properties as the original.
        """
        return Self(
            renderer=self._renderer,
            properties=self._properties,
            value=self._value,
            attrs=self._attrs,
            color=self._color.copy(),
            dimensions=self._dimensions,
            max_dimensions=self._max_dimensions,
            alignment=self._alignment,
            padding=self._padding,
            margin=self._margin.copy(),
            border=self._border,
            border_color=self._border_color.copy(),
            tab_width=self._tab_width,
        )

    fn _get_as_bool[key: PropKey](self, *, default: Bool = False) -> Bool:
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

    fn _get_as_color[key: PropKey](self) -> AnyTerminalColor:
        """Get a rule as an AnyTerminalColor value.

        Parameters:
            key: The key to get.

        Returns:
            The color value.
        """
        constrained[
            key
            in [
                PropKey.FOREGROUND,
                PropKey.BACKGROUND,
                PropKey.MARGIN_BACKGROUND,
                PropKey.BORDER_TOP_FOREGROUND,
                PropKey.BORDER_RIGHT_FOREGROUND,
                PropKey.BORDER_BOTTOM_FOREGROUND,
                PropKey.BORDER_LEFT_FOREGROUND,
                PropKey.BORDER_TOP_BACKGROUND,
                PropKey.BORDER_RIGHT_BACKGROUND,
                PropKey.BORDER_BOTTOM_BACKGROUND,
                PropKey.BORDER_LEFT_BACKGROUND,
            ],
            (
                "The key must be FOREGROUND, BACKGROUND, MARGIN_BACKGROUND, BORDER_TOP_FOREGROUND,"
                " BORDER_RIGHT_FOREGROUND, BORDER_BOTTOM_FOREGROUND, BORDER_LEFT_FOREGROUND, BORDER_TOP_BACKGROUND,"
                " BORDER_RIGHT_BACKGROUND, BORDER_BOTTOM_BACKGROUND, or BORDER_LEFT_BACKGROUND."
            ),
        ]()
        if not self.is_set[key]():
            return NoColor()

        @parameter
        if key == PropKey.FOREGROUND:
            return self._color.foreground.copy()
        elif key == PropKey.BACKGROUND:
            return self._color.background.copy()
        elif key == PropKey.BORDER_TOP_FOREGROUND:
            return self._border_color.foreground_top.copy()
        elif key == PropKey.BORDER_RIGHT_FOREGROUND:
            return self._border_color.foreground_right.copy()
        elif key == PropKey.BORDER_BOTTOM_FOREGROUND:
            return self._border_color.foreground_bottom.copy()
        elif key == PropKey.BORDER_LEFT_FOREGROUND:
            return self._border_color.foreground_left.copy()
        elif key == PropKey.BORDER_TOP_BACKGROUND:
            return self._border_color.background_top.copy()
        elif key == PropKey.BORDER_RIGHT_BACKGROUND:
            return self._border_color.background_right.copy()
        elif key == PropKey.BORDER_BOTTOM_BACKGROUND:
            return self._border_color.background_bottom.copy()
        elif key == PropKey.BORDER_LEFT_BACKGROUND:
            return self._border_color.background_left.copy()
        elif key == PropKey.MARGIN_BACKGROUND:
            return self._margin.background.copy()
        else:
            return NoColor()

    fn _get_as_uint16[key: PropKey](self) -> UInt16:
        """Get a rule as an integer value.

        Parameters:
            key: The key to get.

        Returns:
            The integer value.
        """
        constrained[
            key
            in [
                PropKey.WIDTH,
                PropKey.HEIGHT,
                PropKey.PADDING_TOP,
                PropKey.PADDING_RIGHT,
                PropKey.PADDING_BOTTOM,
                PropKey.PADDING_LEFT,
                PropKey.MARGIN_TOP,
                PropKey.MARGIN_RIGHT,
                PropKey.MARGIN_BOTTOM,
                PropKey.MARGIN_LEFT,
                PropKey.MAX_WIDTH,
                PropKey.MAX_HEIGHT,
                PropKey.TAB_WIDTH,
            ],
            (
                "The key must be WIDTH, HEIGHT, PADDING_TOP, PADDING_RIGHT, PADDING_BOTTOM, PADDING_LEFT, MARGIN_TOP,"
                " MARGIN_RIGHT, MARGIN_BOTTOM, MARGIN_LEFT, MAX_WIDTH, MAX_HEIGHT, or TAB_WIDTH."
            ),
        ]()
        if not self.is_set[key]():
            return 0

        @parameter
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

    fn _get_as_position[key: PropKey](self) -> Position:
        """Get a rule as a Position value.

        Parameters:
            key: The key to get.

        Returns:
            The Position value.
        """
        constrained[
            key in [PropKey.HORIZONTAL_ALIGNMENT, PropKey.VERTICAL_ALIGNMENT],
            "The key must be HORIZONTAL_ALIGNMENT or VERTICAL_ALIGNMENT.",
        ]()
        if not self.is_set[key]():
            return Position(0)

        @parameter
        if key == PropKey.HORIZONTAL_ALIGNMENT:
            return self._alignment.horizontal
        elif key == PropKey.VERTICAL_ALIGNMENT:
            return self._alignment.vertical
        else:
            return Position(0)

    fn get_border_style(self) -> Border:
        """Get the Border style rule.

        Returns:
            The Border style.
        """
        if not self.is_set[PropKey.BORDER_STYLE]():
            return Border()

        return self._border.copy()

    fn is_set[key: PropKey](self) -> Bool:
        """Check if a rule is set on the style.

        Parameters:
            key: The key to check.

        Returns:
            True if the rule is set, False otherwise.
        """
        return self._properties.has[key]()

    fn _set_attribute[key: PropKey](mut self, value: Border):
        """Set a border attribute on the style.

        Parameters:
            key: The key to set.

        Args:
            value: The value to set.
        """
        self._border = value.copy()
        self._properties.set[key](True)

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

    fn _set_attribute[key: PropKey](mut self, value: UInt16):
        """Set a int attribute on the style.

        Parameters:
            key: The key to set.

        Args:
            value: The value to set.
        """

        @parameter
        if key == PropKey.WIDTH:
            self._dimensions.width = value
        elif key == PropKey.HEIGHT:
            self._dimensions.height = value
        elif key == PropKey.PADDING_TOP:
            self._padding.top = value
        elif key == PropKey.PADDING_RIGHT:
            self._padding.right = value
        elif key == PropKey.PADDING_BOTTOM:
            self._padding.bottom = value
        elif key == PropKey.PADDING_LEFT:
            self._padding.left = value
        elif key == PropKey.MARGIN_TOP:
            self._margin.top = value
        elif key == PropKey.MARGIN_RIGHT:
            self._margin.right = value
        elif key == PropKey.MARGIN_BOTTOM:
            self._margin.bottom = value
        elif key == PropKey.MARGIN_LEFT:
            self._margin.left = value
        elif key == PropKey.MAX_WIDTH:
            self._max_dimensions.width = value
        elif key == PropKey.MAX_HEIGHT:
            self._max_dimensions.height = value
        elif key == PropKey.TAB_WIDTH:
            self._tab_width = value

        # Set the prop
        self._properties.set[key](True)

    fn _set_attribute[key: PropKey](mut self, value: Position):
        """Set a Position attribute on the style.

        Parameters:
            key: The key to set.

        Args:
            value: The value to set.
        """

        @parameter
        if key == PropKey.HORIZONTAL_ALIGNMENT:
            self._alignment.horizontal = value
        elif key == PropKey.VERTICAL_ALIGNMENT:
            self._alignment.vertical = value

        # Set the prop
        self._properties.set[key](True)

    fn _set_attribute[key: PropKey](mut self, value: AnyTerminalColor):
        """Set a int attribute on the style.

        Parameters:
            key: The key to set.

        Args:
            value: The value to set.
        """

        @parameter
        if key == PropKey.FOREGROUND:
            self._color.foreground = value.copy()
        elif key == PropKey.BACKGROUND:
            self._color.background = value.copy()
        elif key == PropKey.MARGIN_BACKGROUND:
            self._margin.background = value.copy()
        elif key == PropKey.BORDER_TOP_FOREGROUND:
            self._border_color.foreground_top = value.copy()
        elif key == PropKey.BORDER_RIGHT_FOREGROUND:
            self._border_color.foreground_right = value.copy()
        elif key == PropKey.BORDER_BOTTOM_FOREGROUND:
            self._border_color.foreground_bottom = value.copy()
        elif key == PropKey.BORDER_LEFT_FOREGROUND:
            self._border_color.foreground_left = value.copy()
        elif key == PropKey.BORDER_TOP_BACKGROUND:
            self._border_color.background_top = value.copy()
        elif key == PropKey.BORDER_RIGHT_BACKGROUND:
            self._border_color.background_right = value.copy()
        elif key == PropKey.BORDER_BOTTOM_BACKGROUND:
            self._border_color.background_bottom = value.copy()
        elif key == PropKey.BORDER_LEFT_BACKGROUND:
            self._border_color.background_left = value.copy()

        # Set the prop
        self._properties.set[key](True)

    fn _unset_attribute[key: PropKey](mut self):
        """Set a boolean attribute on the style.

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
        new._renderer = renderer
        return new^

    fn set_value(self, /, value: String) -> Self:
        """Set the string value for the style.

        Args:
            value: The string value to set.

        Returns:
            A new Style with the string value set.
        """
        var new = self.copy()
        new._value = value
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
        new._set_attribute[PropKey.TAB_WIDTH](width)
        return new^

    fn get_tab_width(self) -> UInt16:
        """Returns the tab width of the text.

        Returns:
            The tab width.
        """
        return self._get_as_uint16[PropKey.TAB_WIDTH]()

    fn unset_tab_width(self) -> Self:
        """Unset the tab width of the text.

        Returns:
            A new Style with the tab width rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.TAB_WIDTH]()
        return new^

    fn underline_spaces(self, value: Bool = True) -> Self:
        """Determines whether to underline spaces between words.
        Spaces can also be underlined without underlining the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the strikethrough rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.UNDERLINE_SPACES](value)
        return new^

    @always_inline
    fn check_if_underline_spaces(self) -> Bool:
        """Returns whether or not the underline spaces rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.UNDERLINE_SPACES](default=False)

    fn unset_underline_spaces(self) -> Self:
        """Unset the underline spaces rule.

        Returns:
            A new Style with the underline spaces rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.UNDERLINE_SPACES]()
        return new^

    fn strikethrough_spaces(self, value: Bool = True) -> Self:
        """Determines whether to strikethrough spaces between words. Spaces can also be
        crossed out without strikethrough on the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the strikethrough rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.STRIKETHROUGH_SPACES](value)
        return new^

    @always_inline
    fn check_if_strikethrough_spaces(self) -> Bool:
        """Returns whether or not the strikethrough spaces rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.STRIKETHROUGH_SPACES](default=False)

    fn unset_strikethrough_spaces(self) -> Self:
        """Unset the strikethrough spaces rule.

        Returns:
            A new Style with the strikethrough spaces rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.STRIKETHROUGH_SPACES]()
        return new^

    fn color_whitespace(self, value: Bool = True) -> Self:
        """Determines whether to color whitespace.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the color whitespace rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.COLOR_WHITESPACE](value)
        return new^

    @always_inline
    fn check_if_color_whitespace(self) -> Bool:
        """Returns whether or not the color whitespace rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.COLOR_WHITESPACE](default=False)

    fn unset_color_whitespace(self) -> Self:
        """Unset the color whitespace rule.

        Returns:
            A new Style with the color whitespace rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.COLOR_WHITESPACE]()
        return new^

    fn inline(self, value: Bool = True) -> Self:
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
        var new = self.copy()
        new._set_attribute[PropKey.INLINE](value)
        return new^

    @always_inline
    fn get_inline(self) -> Bool:
        """Returns whether or not the inline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.INLINE](default=False)

    fn unset_inline(self) -> Self:
        """Unset the inline rule.

        Returns:
            A new Style with the inline rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.INLINE]()
        return new^

    fn bold_text(self, value: Bool = True) -> Self:
        """Set the text to be bold.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the bold rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.BOLD](value)
        return new^

    @always_inline
    fn check_if_text_bolded(self) -> Bool:
        """Returns whether or not the bold rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.BOLD](default=False)

    fn unset_bold_text(self) -> Self:
        """Unset the bold rule.

        Returns:
            A new Style with the bold rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.BOLD]()
        return new^

    fn italicize_text(self, value: Bool = True) -> Self:
        """Set the text to be italic.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the italic rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.ITALIC](value)
        return new^

    @always_inline
    fn check_if_text_italicized(self) -> Bool:
        """Returns whether or not the italic rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.ITALIC](default=False)

    fn unset_italic_text(self) -> Self:
        """Unset the italic rule.

        Returns:
            A new Style with the italic rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.ITALIC]()
        return new^

    fn underline_text(self, value: Bool = True) -> Self:
        """Set the text to be underline.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the underline rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.UNDERLINE](value)
        return new^

    @always_inline
    fn get_underline(self) -> Bool:
        """Returns whether or not the underline rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.UNDERLINE](default=False)

    fn unset_underline(self) -> Self:
        """Unset the text to be underline.

        Returns:
            A new Style with the underline rule set.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.UNDERLINE]()
        return new^

    fn strikethrough_text(self, value: Bool = True) -> Self:
        """Set the text to be crossed out.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the strikethrough rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.STRIKETHROUGH](value)
        return new^

    @always_inline
    fn get_strikethrough(self) -> Bool:
        """Returns whether or not the strikethrough rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.STRIKETHROUGH](default=False)

    fn unset_strikethrough(self) -> Self:
        """Unset the strikethrough rule.

        Returns:
            A new Style with the strikethrough rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.STRIKETHROUGH]()
        return new^

    fn reverse_text_background_and_foreground(self, value: Bool = True) -> Self:
        """Set the text have the foreground and background colors reversed.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the reverse rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.REVERSE](value)
        return new^

    @always_inline
    fn check_if_text_colors_reversed(self) -> Bool:
        """Returns whether or not the reverse rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.REVERSE](default=False)

    fn unset_text_color_reversal(self) -> Self:
        """Unset the reverse rule.

        Returns:
            A new Style with the reverse rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.REVERSE]()
        return new^

    fn set_blink_text(self, value: Bool = True) -> Self:
        """Set the text to blink.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the blink rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.BLINK](value)
        return new^

    @always_inline
    fn get_blink(self) -> Bool:
        """Returns whether or not the blink rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.BLINK](default=False)

    fn unset_blink(self) -> Self:
        """Unset the blink rule.

        Returns:
            A new Style with the blink rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.BLINK]()
        return new^

    fn faint_text(self, value: Bool = True) -> Self:
        """Set the text to be faint.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style with the faint rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.FAINT](value)
        return new^

    @always_inline
    fn check_if_faint_text(self) -> Bool:
        """Returns whether or not the faint rule is set.

        Returns:
            True if set, False otherwise.
        """
        return self._get_as_bool[PropKey.FAINT](default=False)

    fn unset_faint(self) -> Self:
        """Unset the text to be faint.

        Returns:
            A new Style with the faint rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.FAINT]()
        return new^

    fn set_width(self, width: UInt16) -> Self:
        """Set the width of the text.

        Args:
            width: The width to apply.

        Returns:
            A new Style with the width rule set.

        #### Notes:
        If you need width to be truncated to obey the width rule, use `Style.max_width()` instead.
        """
        var new = self.copy()
        new._set_attribute[PropKey.WIDTH](width)
        return new^

    @always_inline
    fn get_width(self) -> UInt16:
        """Returns the width of the text.

        Returns:
            The width of the text.
        """
        return self._get_as_uint16[PropKey.WIDTH]()

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
        If you need height to be truncated to obey the height rule, use `Style.max_height()` instead.
        """
        var new = self.copy()
        new._set_attribute[PropKey.HEIGHT](height)
        return new^

    @always_inline
    fn get_height(self) -> UInt16:
        """Returns the height of the text.

        Returns:
            The height of the text.
        """
        return self._get_as_uint16[PropKey.HEIGHT]()

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
        .
        """
        var new = self.copy()
        new._set_attribute[PropKey.MAX_WIDTH](width)
        return new^

    @always_inline
    fn get_max_width(self) -> UInt16:
        """Returns the max width of the text.

        Returns:
            The max width of the text.
        """
        return self._get_as_uint16[PropKey.MAX_WIDTH]()

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
        new._set_attribute[PropKey.MAX_HEIGHT](height)
        return new^

    @always_inline
    fn get_max_height(self) -> UInt16:
        """Returns the max height of the text.

        Returns:
            The max height of the text.
        """
        return self._get_as_uint16[PropKey.MAX_HEIGHT]()

    fn unset_max_height(self) -> Self:
        """Unset the max height of the text.

        Returns:
            A new Style with the max height rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MAX_HEIGHT]()
        return new^

    fn set_horizontal_text_alignment(self, align: Position) -> Self:
        """Set the horizontal alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style with the alignment rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.HORIZONTAL_ALIGNMENT](align)
        return new^

    @always_inline
    fn get_horizontal_text_alignment(self) -> Position:
        """Returns the horizontal alignment of the text.

        Returns:
            The horizontal alignment of the text.
        """
        return self._get_as_position[PropKey.HORIZONTAL_ALIGNMENT]()

    fn unset_horizontal_text_alignment(self) -> Self:
        """Unset the horizontal alignment of the text.

        Returns:
            A new Style with the horizontal alignment rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.HORIZONTAL_ALIGNMENT]()
        return new^

    fn set_vertical_text_alignment(self, align: Position) -> Self:
        """Set the vertical alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style with the alignment rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.VERTICAL_ALIGNMENT](align)
        return new^

    @always_inline
    fn get_vertical_text_alignment(self) -> Position:
        """Returns the vertical alignment of the text.

        Returns:
            The vertical alignment of the text.
        """
        return self._get_as_position[PropKey.VERTICAL_ALIGNMENT]()

    fn unset_vertical_alignment(self) -> Self:
        """Unset the vertical alignment of the text.

        Returns:
            A new Style with the vertical alignment rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.VERTICAL_ALIGNMENT]()
        return new^

    fn set_text_alignment(self, *align: Position) -> Self:
        """Align is a shorthand method for setting horizontal and vertical alignment.

        With one argument, the position value is applied to the horizontal alignment.

        With two arguments, the value is applied to the horizontal and vertical
        alignments, in that order.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style with the alignment rules set.
        """
        var new = self.copy()

        if len(align) > 0:
            new._set_attribute[PropKey.HORIZONTAL_ALIGNMENT](align[0])
        if len(align) > 1:
            new._set_attribute[PropKey.VERTICAL_ALIGNMENT](align[1])
        return new^

    fn set_foreground_color(self, color: AnyTerminalColor) -> Self:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the foreground color rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.FOREGROUND](color)
        return new^

    fn get_foreground_color(self) -> AnyTerminalColor:
        """Returns the foreground color of the text.

        Returns:
            The foreground color of the text.
        """
        return self._get_as_color[PropKey.FOREGROUND]()

    fn unset_foreground_color(self) -> Self:
        """Unset the foreground color of the text.

        Returns:
            A new Style with the foreground color rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.FOREGROUND]()
        return new^

    fn set_background_color(self, color: AnyTerminalColor) -> Self:
        """Set the background color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style with the background color rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.BACKGROUND](color)
        return new^

    fn get_background_color(self) -> AnyTerminalColor:
        """Returns the background color of the text.

        Returns:
            The background color of the text.
        """
        return self._get_as_color[PropKey.BACKGROUND]()

    fn unset_background(self) -> Self:
        """Unset the background color of the text.

        Returns:
            A new Style with the background color rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.BACKGROUND]()
        return new^

    fn set_border(
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
        if not top and not right and not bottom and not right:
            return self.copy()

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
    
    fn unset_border(
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
        if not top and not right and not bottom and not right:
            return self.copy()

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
            return self._get_as_bool[PropKey.BORDER_TOP](default=False)
        elif side == Side.RIGHT:
            return self._get_as_bool[PropKey.BORDER_RIGHT](default=False)
        elif side == Side.BOTTOM:
            return self._get_as_bool[PropKey.BORDER_BOTTOM](default=False)
        elif side == Side.LEFT:
            return self._get_as_bool[PropKey.BORDER_LEFT](default=False)
        
        # TODO: Remove this when we have enums and exhaustive matching.
        return False
    
    fn set_border_foreground(
        self,
        *,
        top: Optional[AnyTerminalColor] = None,
        right: Optional[AnyTerminalColor] = None,
        bottom: Optional[AnyTerminalColor] = None,
        left: Optional[AnyTerminalColor] = None,
    ) -> Self:
        """Set the border foreground color.

        Args:
            top: The foreground color for the top border side.
            right: The foreground color for the right border side.
            bottom: The foreground color for the bottom border side.
            left: The foreground color for the left border side.

        Returns:
            A new Style with the border foreground color rules set.
        """
        if not top and not right and not bottom and not right:
            return self.copy()

        var new = self.copy()
        if top:
            new._set_attribute[PropKey.BORDER_TOP_FOREGROUND](top.value())

        if right:
            new._set_attribute[PropKey.BORDER_RIGHT_FOREGROUND](right.value())

        if bottom:
            new._set_attribute[PropKey.BORDER_BOTTOM_FOREGROUND](bottom.value())

        if left:
            new._set_attribute[PropKey.BORDER_LEFT_FOREGROUND](left.value())
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
    
    fn get_border_foreground(self, side: Side) -> AnyTerminalColor:
        """Returns the border foreground color.

        Args:
            side: The side of the border to return the color for.

        Returns:
            The border foreground color.
        """
        if side == Side.TOP:
            return self._get_as_color[PropKey.BORDER_TOP_FOREGROUND]()
        elif side == Side.RIGHT:
            return self._get_as_color[PropKey.BORDER_RIGHT_FOREGROUND]()
        elif side == Side.BOTTOM:
            return self._get_as_color[PropKey.BORDER_BOTTOM_FOREGROUND]()
        elif side == Side.LEFT:
            return self._get_as_color[PropKey.BORDER_LEFT_FOREGROUND]()
        
        # TODO: Remove this when we have enums and exhaustive matching.
        return NoColor()

    fn set_border_background(
        self,
        *,
        top: Optional[AnyTerminalColor] = None,
        right: Optional[AnyTerminalColor] = None,
        bottom: Optional[AnyTerminalColor] = None,
        left: Optional[AnyTerminalColor] = None,
    ) -> Self:
        """Set the border background color.

        Args:
            top: The background color for the top border side.
            right: The background color for the right border side.
            bottom: The background color for the bottom border side.
            left: The background color for the left border side.

        Returns:
            A new Style with the border background color rules set.
        """
        if not top and not right and not bottom and not right:
            return self.copy()

        var new = self.copy()
        if top:
            new._set_attribute[PropKey.BORDER_TOP_BACKGROUND](top.value())

        if right:
            new._set_attribute[PropKey.BORDER_RIGHT_BACKGROUND](right.value())

        if bottom:
            new._set_attribute[PropKey.BORDER_BOTTOM_BACKGROUND](bottom.value())

        if left:
            new._set_attribute[PropKey.BORDER_LEFT_BACKGROUND](left.value())
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
    
    fn get_border_background(self, side: Side) -> AnyTerminalColor:
        """Returns the border background color.

        Args:
            side: The side of the border to return the color for.

        Returns:
            The border background color.
        """
        if side == Side.TOP:
            return self._get_as_color[PropKey.BORDER_TOP_BACKGROUND]()
        elif side == Side.RIGHT:
            return self._get_as_color[PropKey.BORDER_RIGHT_BACKGROUND]()
        elif side == Side.BOTTOM:
            return self._get_as_color[PropKey.BORDER_BOTTOM_BACKGROUND]()
        elif side == Side.LEFT:
            return self._get_as_color[PropKey.BORDER_LEFT_BACKGROUND]()
        
        # TODO: Remove this when we have enums and exhaustive matching.
        return NoColor()

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
            new._set_attribute[PropKey.PADDING_TOP](UInt16(top.value()))

        if right:
            new._set_attribute[PropKey.PADDING_RIGHT](UInt16(right.value()))

        if bottom:
            new._set_attribute[PropKey.PADDING_BOTTOM](UInt16(bottom.value()))

        if left:
            new._set_attribute[PropKey.PADDING_LEFT](UInt16(left.value()))
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
    
    fn get_padding(self, side: Side) -> UInt16:
        """Returns the padding width for the given side of the text area.

        Args:
            side: The side of the text area to return the padding width for.

        Returns:
            The padding width.
        """
        if side == Side.TOP:
            return self._get_as_uint16[PropKey.PADDING_TOP]()
        elif side == Side.RIGHT:
            return self._get_as_uint16[PropKey.PADDING_RIGHT]()
        elif side == Side.BOTTOM:
            return self._get_as_uint16[PropKey.PADDING_BOTTOM]()
        elif side == Side.LEFT:
            return self._get_as_uint16[PropKey.PADDING_LEFT]()
        
        # TODO: Remove this when we have enums and exhaustive matching.
        return 0

    fn set_margin(
        self,
        *,
        top: Optional[UInt16] = None,
        right: Optional[UInt16] = None,
        bottom: Optional[UInt16] = None,
        left: Optional[UInt16] = None,
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
        if not top and not right and not bottom and not right:
            return self.copy()

        var new = self.copy()
        if top:
            new._set_attribute[PropKey.PADDING_TOP](top.value())

        if right:
            new._set_attribute[PropKey.PADDING_RIGHT](right.value())

        if bottom:
            new._set_attribute[PropKey.PADDING_BOTTOM](bottom.value())

        if left:
            new._set_attribute[PropKey.PADDING_LEFT](left.value())
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
    
    fn get_margin(self, side: Side) -> UInt16:
        """Returns the margin width for the given side of the text area.

        Args:
            side: The side of the text area to return the margin width for.

        Returns:
            The margin width.
        """
        if side == Side.TOP:
            return self._get_as_uint16[PropKey.MARGIN_TOP]()
        elif side == Side.RIGHT:
            return self._get_as_uint16[PropKey.MARGIN_RIGHT]()
        elif side == Side.BOTTOM:
            return self._get_as_uint16[PropKey.MARGIN_BOTTOM]()
        elif side == Side.LEFT:
            return self._get_as_uint16[PropKey.MARGIN_LEFT]()
        
        # TODO: Remove this when we have enums and exhaustive matching.
        return 0

    fn set_margin_background(self, /, color: AnyTerminalColor) -> Self:
        """Set the margin on the background color.

        Args:
            color: The margin width to apply.

        Returns:
            A new Style with the margin background rule set.
        """
        var new = self.copy()
        new._set_attribute[PropKey.MARGIN_BACKGROUND](color)
        return new^

    fn get_margin_background(self) -> AnyTerminalColor:
        """Returns the margin background color.

        Returns:
            The margin background color.
        """
        return self._get_as_color[PropKey.MARGIN_BACKGROUND]()

    fn unset_margin_background(self) -> Self:
        """Unset the margin background rule.

        Returns:
            A new Style with the margin background rule unset.
        """
        var new = self.copy()
        new._unset_attribute[PropKey.MARGIN_BACKGROUND]()
        return new^

    fn _maybe_convert_tabs(self, text: String) -> String:
        """Convert tabs to spaces if the tab width is set.

        Args:
            text: The text to convert tabs in.

        Returns:
            The text with tabs converted to spaces.
        """
        var DEFAULT_TAB_WIDTH: UInt16 = TAB_WIDTH
        if self.is_set[PropKey.TAB_WIDTH]():
            DEFAULT_TAB_WIDTH = self.get_tab_width()

        if DEFAULT_TAB_WIDTH == -1:
            return text.copy()

        if DEFAULT_TAB_WIDTH == 0:
            return text.replace("\t", "")
        else:
            return text.replace("\t", (WHITESPACE * Int(DEFAULT_TAB_WIDTH)))

    fn uses_space_styler(self) -> Bool:
        """Returns whether or not the style uses the space styler.

        Returns:
            True if the style uses the space styler, False otherwise.
        """
        var underline = self._get_as_bool[PropKey.UNDERLINE](default=False)
        var underline_spaces = self._get_as_bool[PropKey.UNDERLINE_SPACES](default=False) or (
            underline and self._get_as_bool[PropKey.UNDERLINE_SPACES](default=True)
        )

        var strikethrough = self._get_as_bool[PropKey.STRIKETHROUGH](default=False)
        var strikethrough_spaces = self._get_as_bool[PropKey.STRIKETHROUGH_SPACES](default=False) or (
            strikethrough and self._get_as_bool[PropKey.STRIKETHROUGH_SPACES](default=True)
        )

        return underline_spaces or strikethrough_spaces

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

        return (
            self._renderer.as_mist_style()
            .foreground(color=fg.to_mist_color(self._renderer))
            .background(color=bg.to_mist_color(self._renderer))
            .render(border)
        )

    fn _apply_border(self, text: String) -> String:
        """Apply a border to the text.

        Args:
            text: The text to apply the border to.

        Returns:
            The text with the border applied.
        """
        var top_set = self.is_set[PropKey.BORDER_TOP]()
        var right_set = self.is_set[PropKey.BORDER_RIGHT]()
        var bottom_set = self.is_set[PropKey.BORDER_BOTTOM]()
        var left_set = self.is_set[PropKey.BORDER_LEFT]()

        var border = self.get_border_style()
        var has_top = self.check_if_border_side_will_render(Side.TOP)
        var has_right = self.check_if_border_side_will_render(Side.RIGHT)
        var has_bottom = self.check_if_border_side_will_render(Side.BOTTOM)
        var has_left = self.check_if_border_side_will_render(Side.LEFT)

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
                self._style_border(
                    render_horizontal_edge(border.top_left, border.top, border.top_right, width),
                    self.get_border_foreground(Side.TOP),
                    self.get_border_background(Side.TOP),
                ),
                NEWLINE,
            )

        # Render sides once, and reuse for each line.
        var left_border: String
        if has_left:
            left_border = self._style_border(
                border.left, self.get_border_foreground(Side.LEFT), self.get_border_background(Side.LEFT)
            )
        else:
            left_border = ""

        var right_border: String
        if has_right:
            right_border = self._style_border(
                border.right, self.get_border_foreground(Side.RIGHT), self.get_border_background(Side.RIGHT)
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
                self._style_border(
                    render_horizontal_edge(border.bottom_left, border.bottom, border.bottom_right, width),
                    self.get_border_foreground(Side.BOTTOM),
                    self.get_border_background(Side.BOTTOM),
                ),
            )

        return result^

    fn _apply_margins(self, var text: String, inline: Bool) -> String:
        """Apply margins to the text.

        Args:
            text: The text to apply the margins to.
            inline: Whether the text is inline or not.

        Returns:
            The text with the margins applied.
        """
        var styler = self._renderer.as_mist_style().background(
            color=self.get_margin_background().to_mist_color(self._renderer)
        )

        # Add left and right margin
        text = pad_right(pad_left(text^, Int(self.get_margin(Side.LEFT)), styler), Int(self.get_margin(Side.RIGHT)), styler)

        # Top/bottom margin
        var top_margin = Int(self.get_margin(Side.TOP))
        var bottom_margin = Int(self.get_margin(Side.BOTTOM))
        if not inline:
            var width = get_widest_line(text)
            if top_margin > 0:
                text = String((WHITESPACE * width + NEWLINE) * top_margin, text)
            if bottom_margin > 0:
                text.write((NEWLINE + WHITESPACE * width) * bottom_margin)

        return text^

    fn _get_styles(self) -> Stylers:
        var base = self._renderer.as_mist_style()
        var stylers = Stylers(base.copy(), base.copy(), base.copy())

        if self.check_if_text_bolded():
            stylers.common = stylers.common.bold()
        if self.check_if_text_italicized():
            stylers.common = stylers.common.italic()
        if self.get_underline():
            stylers.common = stylers.common.underline()
        if self.check_if_text_colors_reversed():
            stylers.common = stylers.common.reverse()
            stylers.whitespace = stylers.whitespace.reverse()
        if self.get_blink():
            stylers.common = stylers.common.blink()
        if self.check_if_faint_text():
            stylers.common = stylers.common.faint()
        if self.get_strikethrough():
            stylers.common = stylers.common.strikethrough()

        var fg_color = self.get_foreground_color().to_mist_color(self._renderer)
        var bg_color = self.get_background_color().to_mist_color(self._renderer)
        stylers.common = stylers.common.foreground(color=fg_color).background(color=bg_color)

        # Do we need to style spaces separately?
        var color_whitespace = self._get_as_bool[PropKey.COLOR_WHITESPACE](default=True)
        var underline = self.get_underline()
        var underline_spaces = self.check_if_underline_spaces() or (
            underline and self._get_as_bool[PropKey.UNDERLINE_SPACES](default=True)
        )

        var strikethrough = self.get_strikethrough()
        var strikethrough_spaces = self.check_if_strikethrough_spaces() or (
            strikethrough and self._get_as_bool[PropKey.STRIKETHROUGH_SPACES](default=True)
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

    fn render[*Ts: Writable](self, *texts: *Ts) -> String:
        """Render the text with the style.

        Args:
            texts: The strings to render.

        Returns:
            The rendered text.
        """
        # If style has internal string, add it first. Join arbitrary list of texts into a single string.
        var input_text = self._value.copy()

        @parameter
        for i in range(texts.__len__()):
            input_text.write(texts[i])
            if i != len(texts) - 1:
                input_text.write(" ")

        var reverse = self.check_if_text_colors_reversed()
        var color_whitespace = self._get_as_bool[PropKey.COLOR_WHITESPACE](default=True)
        var max_width = self.get_max_width()
        var max_height = self.get_max_height()

        # If no style properties are set, return the input text as is with tabs maybe converted.
        if not any(self._properties.value):
            return self._maybe_convert_tabs(input_text)

        var inline = self.get_inline()
        if inline:
            input_text = input_text.replace(NEWLINE, "")

        # Word wrap
        var top_padding = self.get_padding(Side.TOP)
        var right_padding = self.get_padding(Side.RIGHT)
        var bottom_padding = self.get_padding(Side.BOTTOM)
        var left_padding = self.get_padding(Side.LEFT)
        var width = self.get_width()

        # force-wrap long strings
        if not inline and (width > 0):
            input_text = _wrap_words(input_text, width, left_padding, right_padding)

        var stylers = self._get_styles()
        var result = _apply_styles(self._maybe_convert_tabs(input_text), self.uses_space_styler(), stylers)

        # Do we need to style whitespace (padding and space outside paragraphs) separately?
        var use_whitespace_styler = reverse

        # Padding
        if not inline:
            if left_padding > 0:
                var style = self._renderer.as_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = stylers.whitespace.copy()
                result = pad_left(result, Int(left_padding), style)

            if right_padding > 0:
                var style = self._renderer.as_mist_style()
                if color_whitespace or use_whitespace_styler:
                    style = stylers.whitespace.copy()
                result = pad_right(result, Int(right_padding), style)

            if top_padding > 0:
                result = String(NEWLINE * Int(top_padding), result^)

            if bottom_padding > 0:
                result.write(NEWLINE * Int(bottom_padding))

        # Alignment
        var height = self.get_height()
        if height > 0:
            result = align_text_vertical(result, self.get_vertical_text_alignment(), height)

        if width != 0 or get_widest_line(result) != 0:
            var style: mist.Style
            if color_whitespace or use_whitespace_styler:
                style = stylers.whitespace.copy()
            else:
                style = self._renderer.as_mist_style()
            result = align_text_horizontal(result, self.get_horizontal_text_alignment(), width, style)

        # Apply border at the end
        if not inline:
            result = self._apply_margins(self._apply_border(result), inline)

        # Truncate according to max_width
        if max_width > 0:
            var text_lines = result.split(NEWLINE)
            var truncated = String(capacity=Int(len(result) * 1.5))
            for i in range(len(text_lines)):
                if i != 0:
                    truncated.write(NEWLINE)
                truncated.write(truncate(text_lines[i], Int(max_width)))

            result = truncated^

        # Truncate according to max_height
        if max_height > 0:
            var final_lines = result.as_string_slice().get_immutable().splitlines()
            result = StaticString(NEWLINE).join(final_lines[0 : min(Int(max_height), len(final_lines))])

        return result^
