from external.string_dict import Dict
from .renderer import Renderer
from .position import Position
from .border import (
    Border,
    render_horizontal_edge,
    no_border,
    hidden_border,
    double_border,
    rounded_border,
    normal_border,
    block_border,
    inner_half_block_border,
    outer_half_block_border,
    thick_border,
    ascii_border,
    star_border,
    plus_border,
)
from .extensions import join, split
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
from external.weave import wrap, wordwrap, truncate
from external.weave.ansi.ansi import printable_rune_width
import external.mist
from external.gojo.strings import StringBuilder


alias TAB_WIDTH: Int = 4
# NoTabConversion can be passed to [Style.tab_width] to disable the replacement
# of tabs with spaces at render time.
alias NO_TAB_CONVERSION = -1


alias PropertyKey = Int
alias BOLD_KEY: PropertyKey = 0
alias ITALIC_KEY: PropertyKey = 1
alias UNDERLINE_KEY: PropertyKey = 2
alias CROSSOUT_KEY: PropertyKey = 3
alias REVERSE_KEY: PropertyKey = 4
alias BLINK_KEY: PropertyKey = 5
alias FAINT_KEY: PropertyKey = 6
alias FOREGROUND_KEY: PropertyKey = 7
alias BACKGROUND_KEY: PropertyKey = 8
alias WIDTH_KEY: PropertyKey = 9
alias HEIGHT_KEY: PropertyKey = 10
alias HORIZONTAL_ALIGNMENT_KEY: PropertyKey = 11
alias VERTICAL_ALIGNMENT_KEY: PropertyKey = 12

# Padding.
alias PADDING_TOP_KEY: PropertyKey = 13
alias PADDING_RIGHT_KEY: PropertyKey = 14
alias PADDING_BOTTOM_KEY: PropertyKey = 15
alias PADDING_LEFT_KEY: PropertyKey = 16

alias COLOR_WHITESPACE_KEY: PropertyKey = 17

# Margins.
alias MARGIN_TOP_KEY: PropertyKey = 18
alias MARGIN_RIGHT_KEY: PropertyKey = 19
alias MARGIN_BOTTOM_KEY: PropertyKey = 20
alias MARGIN_LEFT_KEY: PropertyKey = 21
alias MARGIN_BACKGROUND_KEY: PropertyKey = 22

# Border runes.
alias BORDER_STYLE_KEY: PropertyKey = 23

# Border edges.
alias BORDER_TOP_KEY: PropertyKey = 24
alias BORDER_RIGHT_KEY: PropertyKey = 25
alias BORDER_BOTTOM_KEY: PropertyKey = 26
alias BORDER_LEFT_KEY: PropertyKey = 27

# Border foreground colors.
alias BORDER_TOP_FOREGROUND_KEY: PropertyKey = 28
alias BORDER_RIGHT_FOREGROUND_KEY: PropertyKey = 29
alias BORDER_BOTTOM_FOREGROUND_KEY: PropertyKey = 30
alias BORDER_LEFT_FOREGROUND_KEY: PropertyKey = 31

# Border background colors.
alias BORDER_TOP_BACKGROUND_KEY: PropertyKey = 32
alias BORDER_RIGHT_BACKGROUND_KEY: PropertyKey = 33
alias BORDER_BOTTOM_BACKGROUND_KEY: PropertyKey = 34
alias BORDER_LEFT_BACKGROUND_KEY: PropertyKey = 35

alias INLINE_KEY: PropertyKey = 36
alias MAX_WIDTH_KEY: PropertyKey = 37
alias MAX_HEIGHT_KEY: PropertyKey = 38
alias TAB_WIDTH_KEY: PropertyKey = 39
alias UNDERLINE_SPACES_KEY: PropertyKey = 40
alias CROSSOUT_SPACES_KEY: PropertyKey = 41


fn get_lines(text: String) -> Tuple[List[String], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = split(text, "\n")

    var widest_line: Int = 0
    for i in range(len(lines)):
        if printable_rune_width(lines[i]) > widest_line:
            widest_line = printable_rune_width(lines[i])

    return lines, widest_line


@always_inline
fn to_bool(s: String) -> Bool:
    alias TRUTHY_VALUES = List[String]("True", "true", "TRUE", "1")
    return s in TRUTHY_VALUES


# Apply left padding.
fn pad_left(text: String, n: Int, style: mist.Style) -> String:
    if n == 0:
        return text

    var sp = style.render(WHITESPACE * n)
    var padded_text: String = ""
    var lines = split(text, "\n")

    for i in range(len(lines)):
        padded_text += sp
        padded_text += lines[i]
        if i != len(lines) - 1:
            padded_text += "\n"

    return padded_text


# Apply right padding.
fn pad_right(text: String, n: Int, style: mist.Style) -> String:
    if n == 0 or text == "":
        return text

    var sp = style.render(WHITESPACE * n)
    var padded_text: String = ""
    var lines = split(text, "\n")

    for i in range(len(lines)):
        padded_text += lines[i]
        padded_text += sp
        if i != len(lines) - 1:
            padded_text += "\n"

    return padded_text


alias Rule = Variant[Bool, Border, Int, Position, AnyTerminalColor]


fn new_style() -> Style:
    """Create a new Style object."""
    return Style()


@register_passable("trivial")
struct Properties:
    """Properties for a style."""

    var properties: PropertyKey

    fn __init__(inout self, properties: PropertyKey = 0):
        """Initialize a new Properties object.

        Args:
            properties: The properties to set.
        """
        self.properties = properties

    fn set(self, key: PropertyKey) -> Properties:
        """Set a property.

        Args:
            key: The key to set.

        Returns:
            A new Properties object with the property set.
        """
        return self.properties | key

    fn unset(self, key: PropertyKey) -> Properties:
        """Unset a property.

        Args:
            key: The key to unset.

        Returns:
            A new Properties object with the property unset.
        """
        return self.properties & ~key

    fn has(self, key: PropertyKey) -> Bool:
        """Check if a property is set.

        Args:
            key: The key to check.

        Returns:
            True if the property is set, False otherwise.
        """
        return (self.properties & key) != 0


@value
struct Style:
    """Terminal styler.

    More documentation to come."""

    var renderer: Renderer
    var properites: Properties
    var rules: Dict[Rule]
    var value: String

    # we store bool props values here
    var attrs: Int

    # props that have values
    var _fg: AnyTerminalColor
    var _bg: AnyTerminalColor

    var _width: Int
    var _height: Int

    var _horizontal_alignment: Position
    var _vertical_alignment: Position

    var _padding_top: Int
    var _padding_right: Int
    var _padding_bottom: Int
    var _padding_left: Int

    var _margin_top: Int
    var _margin_right: Int
    var _margin_bottom: Int
    var _margin_left: Int
    var _margin_bg: AnyTerminalColor

    var _border: Border
    var _border_top_fg: AnyTerminalColor
    var _border_right_fg: AnyTerminalColor
    var _border_bottom_fg: AnyTerminalColor
    var _border_left_fg: AnyTerminalColor
    var _border_top_bg: AnyTerminalColor
    var _border_right_bg: AnyTerminalColor
    var _border_bottom_bg: AnyTerminalColor
    var _border_left_bg: AnyTerminalColor

    var _max_width: Int
    var _max_height: Int
    var _tab_width: Int

    fn __init__(inout self, value: String = ""):
        """Initialize a new Style object.

        Args:
            value: Internal string value to apply the style to. Not required, but useful for reusing some string you want to format multiple times.
        """
        self.renderer = Renderer()
        self.rules = Dict[Rule]()
        self.value = value
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

        self._border = no_border()
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

        return self.attrs & int(key) != 0

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
        return self.properites.has(key)

    fn set_attribute(inout self, key: PropertyKey, value: Bool):
        """Set a boolean attribute on the style.

        Args:
            key: The key to set.
            value: The value to set.
        """
        if value:
            self.attrs |= key
        else:
            self.attrs &= ~key

        # Set the prop
        self.properites = self.properites.set(key)

    fn unset_attribute(inout self, key: PropertyKey):
        """Set a boolean attribute on the style.

        Args:
            key: The key to set.
        """
        # Set the prop
        self.properites = self.properites.unset(key)

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
        var new = self
        new._tab_width = width
        return new

    fn unset_tab_width(self) -> Style:
        """Unset the tab width of the text.

        Returns:
            A new Style object with the tab width rule unset.
        """
        var new = self
        new._tab_width = TAB_WIDTH
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

            var: String = "..."
            var user_style = mog.new_style().inline(True)
            print(user_style.render(user_input))

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the bold rule set.
        """
        var new = self
        new.set_attribute(INLINE_KEY, value)
        return new

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
        new._width = width
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
        new._height = height
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
            var: String = "..."
            var user_style = mog.new_style().max_width(16)
            print(user_style.render(user_input))

        Args:
            width: The maximum height to apply.

        Returns:
            A new Style object with the maximum width rule set.
        """
        var new = self
        new._max_width = width
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
        new._max_height = height
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
        new._horizontal_alignment = align
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
        new._vertical_alignment = align
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
            new._horizontal_alignment = align[0]
        if len(align) > 1:
            new._vertical_alignment = align[1]
        return new

    fn foreground(self, color: AnyTerminalColor) -> Style:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the foreground color rule set.
        """
        var new = self
        new._fg = color
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
        new._bg = color
        return new

    fn unset_background(self) -> Style:
        """Unset the background color of the text.

        Returns:
            A new Style object with the background color rule unset.
        """
        var new = self
        new.unset_attribute(BACKGROUND_KEY)
        return new

    fn border(
        self,
        border: Border,
        top: Bool = True,
        right: Bool = True,
        bottom: Bool = True,
        left: Bool = True,
    ) -> Style:
        """Set the border style of the text.

        Args:
            border: The border style to apply.
            top: Whether to apply the border to the top side.
            right: Whether to apply the border to the right side.
            bottom: Whether to apply the border to the bottom side.
            left: Whether to apply the border to the left side.

        Returns:
            A new Style object with the border rule set.
        """
        var new = self
        new._border = border
        if top:
            new = new.border_top(True)
        if right:
            new = new.border_right(True)
        if bottom:
            new = new.border_bottom(True)
        if left:
            new = new.border_left(True)
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

        return (
            new.border_top_foreground(top)
            .border_right_foreground(right)
            .border_bottom_foreground(bottom)
            .border_left_foreground(left)
        )

    fn border_top_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the top border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        var new = self
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
        var new_style = self.copy()
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
            return new_style

        return (
            new_style.border_top_background(top)
            .border_right_background(right)
            .border_bottom_background(bottom)
            .border_left_background(left)
        )

    fn border_top_background(self, color: AnyTerminalColor) -> Style:
        """Set the top border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        var new = self
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

        return new.padding_top(top).padding_right(right).padding_bottom(bottom).padding_left(left)

    fn padding_top(self, width: Int) -> Style:
        """Set the padding on the top side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding top rule set.
        """
        var new = self
        new._padding_top = width
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
        new._padding_right = width
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
        new._padding_bottom = width
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
        new._padding_left = width
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

        return new.margin_top(top).margin_right(right).margin_bottom(bottom).margin_left(left)

    fn margin_top(self, width: Int) -> Style:
        """Set the margin on the top side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin top rule set.
        """
        var new = self
        new._margin_top = width
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
        new._margin_right = width
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
        new._margin_right = width
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
        new._margin_left = width
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
        new._margin_bg = color
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

        var styler = mist.new_style()

        # Sooooo verbose compared to just passing the string value. But this is closer to the lipgloss API.
        # It's more verbose because we can't pass around args with trait as the arg type.
        if fg.isa[Color]():
            styler = styler.foreground(fg[Color].color(self.renderer))
        elif fg.isa[ANSIColor]():
            styler = styler.foreground(fg[ANSIColor].color(self.renderer))
        elif fg.isa[AdaptiveColor]():
            styler = styler.foreground(fg[AdaptiveColor].color(self.renderer))
        elif fg.isa[CompleteColor]():
            styler = styler.foreground(fg[CompleteColor].color(self.renderer))
        elif fg.isa[CompleteAdaptiveColor]():
            styler = styler.foreground(fg[CompleteAdaptiveColor].color(self.renderer))

        if bg.isa[Color]():
            styler = styler.background(bg[Color].color(self.renderer))
        elif bg.isa[ANSIColor]():
            styler = styler.background(bg[ANSIColor].color(self.renderer))
        elif bg.isa[AdaptiveColor]():
            styler = styler.background(bg[AdaptiveColor].color(self.renderer))
        elif bg.isa[CompleteColor]():
            styler = styler.background(bg[CompleteColor].color(self.renderer))
        elif bg.isa[CompleteAdaptiveColor]():
            styler = styler.background(bg[CompleteAdaptiveColor].color(self.renderer))

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
        # render borders on all sideself.
        var borderless = no_border()
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

        # TODO: Commenting out for now, later when unicode is supported, this should be limiting corner to 1 rune length
        # border.top_left = border.top_left[:1]
        # border.top_right = border.top_right[:1]
        # border.bottom_right = border.bottom_right[:1]
        # border.bottom_left = border.bottom_left[:1]

        var builder = StringBuilder(capacity=int(len(text) * 1.5))

        # Render top
        if has_top:
            var top = render_horizontal_edge(border.top_left, border.top, border.top_right, width)
            top = self.style_border(top, top_fg, top_bg)
            _ = builder.write_string(top)
            _ = builder.write_string("\n")

        # Render sides
        var left_runes = List[String]()
        left_runes.append(border.left)
        var left_index = 0

        var right_runes = List[String]()
        right_runes.append(border.right)
        var right_index = 0

        for i in range(len(lines)):
            var line = lines[i]
            if has_left:
                var r = left_runes[left_index]
                left_index += 1

                if left_index >= len(left_runes):
                    left_index = 0

                _ = builder.write_string(self.style_border(r, left_fg, left_bg))

            _ = builder.write_string(line)

            if has_right:
                var r = right_runes[right_index]
                right_index += 1

                if right_index >= len(right_runes):
                    right_index = 0

                _ = builder.write_string(self.style_border(r, right_fg, right_bg))

            if i < len(lines) - 1:
                _ = builder.write_string("\n")

        # Render bottom
        if has_bottom:
            var bottom = render_horizontal_edge(border.bottom_left, border.bottom, border.bottom_right, width)
            bottom = self.style_border(bottom, bottom_fg, bottom_bg)
            _ = builder.write_string("\n")
            _ = builder.write_string(bottom)

        return str(builder)

    fn apply_margins(self, text: String, inline: Bool) -> String:
        var padded_text: String = text
        var top_margin = self.get_as_int(MARGIN_TOP_KEY)
        var right_margin = self.get_as_int(MARGIN_RIGHT_KEY)
        var bottom_margin = self.get_as_int(MARGIN_BOTTOM_KEY)
        var left_margin = self.get_as_int(MARGIN_LEFT_KEY)

        var styler = mist.new_style(self.renderer.color_profile)

        var bgc = self.get_as_color(MARGIN_BACKGROUND_KEY)

        # TODO: Dealing with variants is verbose :(
        if bgc.isa[Color]():
            styler = styler.background(bgc[Color].color(self.renderer))
        elif bgc.isa[ANSIColor]():
            styler = styler.background(bgc[ANSIColor].color(self.renderer))
        elif bgc.isa[AdaptiveColor]():
            styler = styler.background(bgc[AdaptiveColor].color(self.renderer))
        elif bgc.isa[CompleteColor]():
            styler = styler.background(bgc[CompleteColor].color(self.renderer))
        elif bgc.isa[CompleteAdaptiveColor]():
            styler = styler.background(bgc[CompleteAdaptiveColor].color(self.renderer))

        # Add left and right margin
        padded_text = pad_left(padded_text, left_margin, styler)
        padded_text = pad_right(padded_text, right_margin, styler)

        # Top/bottom margin
        if not inline:
            var lines: List[String]
            var width: Int
            lines, width = get_lines(text)

            var spaces = WHITESPACE * width

            if top_margin > 0:
                padded_text = (NEWLINE * top_margin) + padded_text
            if bottom_margin > 0:
                padded_text += NEWLINE * bottom_margin

        return padded_text

    fn render(self, *texts: String) -> String:
        """Render the text with the style.

        Args:
            texts: The strings to render.

        Returns:
            The rendered text.
        """
        # If style has internal string, add it first. Join arbitrary list of texts into a single string.
        var input_text: String = ""
        if self.value != "":
            input_text += self.value

        for i in range(len(texts)):
            input_text += texts[i]
            if i != len(texts) - 1:
                input_text += " "

        var p = self.renderer.color_profile
        var term_style = mist.new_style(p)
        var term_style_space = mist.new_style(p)
        var term_style_whitespace = mist.new_style(p)

        var bold: Bool = self.get_as_bool(BOLD_KEY)
        var italic: Bool = self.get_as_bool(ITALIC_KEY)
        var underline: Bool = self.get_as_bool(UNDERLINE_KEY)
        var crossout: Bool = self.get_as_bool(CROSSOUT_KEY)
        var reverse: Bool = self.get_as_bool(REVERSE_KEY)
        var blink: Bool = self.get_as_bool(BLINK_KEY)
        var faint: Bool = self.get_as_bool(FAINT_KEY)

        var fg = self.get_as_color(FOREGROUND_KEY)
        var bg = self.get_as_color(BACKGROUND_KEY)

        var width: Int = self.get_as_int(WIDTH_KEY)
        var height: Int = self.get_as_int(HEIGHT_KEY)
        var top_padding: Int = self.get_as_int(PADDING_TOP_KEY)
        var right_padding: Int = self.get_as_int(PADDING_RIGHT_KEY)
        var bottom_padding: Int = self.get_as_int(PADDING_BOTTOM_KEY)
        var left_padding: Int = self.get_as_int(PADDING_LEFT_KEY)

        var horizontal_align: Position = self.get_as_position(HORIZONTAL_ALIGNMENT_KEY)
        var vertical_align: Position = self.get_as_position(VERTICAL_ALIGNMENT_KEY)

        var color_whitespace: Bool = self.get_as_bool(COLOR_WHITESPACE_KEY, True)
        var inline: Bool = self.get_as_bool(INLINE_KEY)
        var max_width: Int = self.get_as_int(MAX_WIDTH_KEY)
        var max_height: Int = self.get_as_int(MAX_HEIGHT_KEY)

        var underline_spaces = underline and self.get_as_bool(UNDERLINE_SPACES_KEY, True)
        var crossout_spaces = crossout and self.get_as_bool(CROSSOUT_SPACES_KEY, True)

        # Do we need to style whitespace (padding and space outside paragraphs) separately?
        var use_whitespace_styler = reverse

        # Do we need to style spaces separately?
        var use_space_styler = underline_spaces or crossout_spaces

        # transform = self.get_as_transform("transform")
        if len(self.rules) == 0:
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
            term_style = term_style.foreground(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(terminal_color)
        elif fg.isa[ANSIColor]():
            var terminal_color = fg[ANSIColor].color(self.renderer)
            term_style = term_style.foreground(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(terminal_color)
        elif fg.isa[AdaptiveColor]():
            var terminal_color = fg[AdaptiveColor].color(self.renderer)
            term_style = term_style.foreground(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(terminal_color)
        elif fg.isa[CompleteColor]():
            var terminal_color = fg[CompleteColor].color(self.renderer)
            term_style = term_style.foreground(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(terminal_color)
        elif fg.isa[CompleteAdaptiveColor]():
            var terminal_color = fg[CompleteAdaptiveColor].color(self.renderer)
            term_style = term_style.foreground(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.foreground(terminal_color)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(terminal_color)

        if bg.isa[Color]():
            var terminal_color = bg[Color].color(self.renderer)
            term_style = term_style.background(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(terminal_color)
        elif bg.isa[ANSIColor]():
            var terminal_color = bg[ANSIColor].color(self.renderer)
            term_style = term_style.background(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(terminal_color)
        elif bg.isa[AdaptiveColor]():
            var terminal_color = bg[AdaptiveColor].color(self.renderer)
            term_style = term_style.background(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(terminal_color)
        elif bg.isa[CompleteColor]():
            var terminal_color = bg[CompleteColor].color(self.renderer)
            term_style = term_style.background(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(terminal_color)
        elif bg.isa[CompleteAdaptiveColor]():
            var terminal_color = bg[CompleteAdaptiveColor].color(self.renderer)
            term_style = term_style.background(terminal_color)
            if use_space_styler:
                term_style_space = term_style_space.background(terminal_color)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(terminal_color)

        if underline_spaces:
            term_style = term_style_space.underline()
        if crossout_spaces:
            term_style = term_style_space.crossout()

        if inline:
            input_text = input_text.replace("\n", "")

        # Word wrap
        if (not inline) and (width > 0):
            var wrap_at = width - left_padding - right_padding
            input_text = wordwrap(input_text, wrap_at)
            input_text = wrap(input_text, wrap_at)  # force-wrap long strings

        input_text = self.maybe_convert_tabs(input_text)

        var builder = StringBuilder(capacity=int(len(input_text) * 1.5))
        var lines = split(input_text, "\n")

        for i in range(len(lines)):
            var line = lines[i]
            if use_space_styler:
                # Look for spaces and apply a different styler
                for i in range(printable_rune_width(line)):
                    var character = line[i]
                    if character == " ":
                        _ = builder.write_string(term_style_space.render(character))
                    else:
                        _ = builder.write_string(term_style.render(character))
            else:
                _ = builder.write_string(term_style.render(line))

            # Readd the newlines
            if i != len(lines) - 1:
                _ = builder.write_string("\n")
        var styled_text = str(builder)

        # Padding
        if not inline:
            if left_padding > 0:
                var style = mist.new_style(self.renderer.color_profile)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                styled_text = pad_left(styled_text, left_padding, style)

            if right_padding > 0:
                var style = mist.new_style(self.renderer.color_profile)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                styled_text = pad_right(styled_text, right_padding, style)

            if top_padding > 0:
                styled_text = (NEWLINE * top_padding) + styled_text

            if bottom_padding > 0:
                styled_text += NEWLINE * bottom_padding

        # Alignment
        if height > 0:
            styled_text = align_text_vertical(styled_text, vertical_align, height)

        # Truncate according to max_width
        if max_width > 0:
            var lines = split(styled_text, "\n")

            for i in range(len(lines)):
                lines[i] = truncate(lines[i], max_width)

            styled_text = join("\n", lines)

        # Truncate according to max_height
        if max_height > 0:
            var lines = split(styled_text, "\n")
            var truncated_lines = lines[0 : min(max_height, len(lines))]
            styled_text = join("\n", truncated_lines)

        # if transform:
        #     return transform(styled_text)

        # Apply border at the end
        try:
            lines = styled_text.split("\n")
        except:
            lines = List[String](styled_text)

        var number_of_lines = len(lines)
        if not (number_of_lines == 0 and width == 0):
            var style = mist.new_style(self.renderer.color_profile)
            if color_whitespace or use_whitespace_styler:
                style = term_style_whitespace
            styled_text = align_text_horizontal(styled_text, horizontal_align, width, style)

        if not inline:
            styled_text = self.apply_border(styled_text)
            styled_text = self.apply_margins(styled_text, inline)

        return styled_text

    fn copy(self) -> Self:
        return Self(
            renderer=self.renderer,
            rules=self.rules,
            value=self.value,
        )
