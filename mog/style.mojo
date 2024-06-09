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


alias TRUTHY_VALUES = List[String]("True", "true", "TRUE", "1")


@always_inline
fn to_bool(s: String) -> Bool:
    return s in TRUTHY_VALUES


fn str_to_float(s: String) raises -> Float64:
    try:
        var dot_pos = s.find(".")
        var int_str = s[0:dot_pos]
        var num_str = s[dot_pos + 1 : len(s)]
        var numerator = atol(num_str)
        var denom_str = String("")
        for _ in range(len(num_str)):
            denom_str += "0"
        var denominator = atol("1" + denom_str)
        var frac = numerator / denominator

        # return the number as a Float64
        var result: Float64 = atol(int_str) + frac
        return result
    except:
        raise Error("Failed to convert " + s + " to a float.")


# Apply left padding.
fn pad_left(text: String, n: Int, style: mist.TerminalStyle) -> String:
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
fn pad_right(text: String, n: Int, style: mist.TerminalStyle) -> String:
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


@value
struct Style:
    """Terminal styler.

    More documentation to come."""

    var renderer: Renderer
    var rules: Dict[Rule]
    var value: String

    fn __init__(inout self, value: String = ""):
        """Initialize a new Style object.

        Args:
            value: Internal string value to apply the style to. Not required, but useful for reusing some string you want to format multiple times.
        """
        self.renderer = Renderer()
        self.rules = Dict[Rule]()
        self.value = value

    @staticmethod
    fn new() -> Self:
        """Create a new Style object. Use this instead of init."""
        return Self()

    fn get_as_bool(self, key: String, default: Bool = False) -> Bool:
        """Get a rule as a boolean value.

        Args:
            key: The key to get.
            default: The default value to return if the rule is not set.

        Returns:
            The boolean value.
        """
        var result = self.rules.get(key, default)
        if result.isa[Bool]():
            var val = result[Bool]
            return val

        return default

    fn get_as_color(self, key: String, default: AnyTerminalColor) -> AnyTerminalColor:
        """Get a rule as an AnyColor value.

        Args:
            key: The key to get.
            default: The default value to return if the rule is not set.

        Returns:
            The color value.
        """
        var result = self.rules.get(key, default)
        if result.isa[AnyTerminalColor]():
            return result[AnyTerminalColor]

        return default

    fn get_as_int(self, key: String, default: Int = 0) -> Int:
        """Get a rule as an integer value.

        Args:
            key: The key to get.
            default: The default value to return if the rule is not set.

        Returns:
            The integer value.
        """
        var result = self.rules.get(key, default)
        if result.isa[Int]():
            var val = result[Int]
            return val

        return default

    fn get_as_position(self, key: String, default: Position = 0) -> Position:
        """Get a rule as a Position value.

        Args:
            key: The key to get.
            default: The default value to return if the rule is not set.

        Returns:
            The Position value.
        """
        var result = self.rules.get(key, default)
        if result.isa[Position]():
            var val = result[Position]
            return val

        return default

    fn get_border_style(self, default: Border = Border()) -> Border:
        """Get the Border style rule.

        Args:
            default: The default value to return if the rule is not set.

        Returns:
            The Border style.
        """
        var result = self.rules.get(str(BORDER_STYLE_KEY), default)
        if result.isa[Border]():
            var val = result[Border]
            return val

        return default

    fn is_set(self, key: PropertyKey) -> Bool:
        """Check if a rule is set on the style.

        Args:
            key: The key to check.

        Returns:
            True if the rule is set, False otherwise.
        """
        for i in range(len(self.rules.keys)):
            if str(self.rules.keys[i]) == str(key):
                return True

        return False

    fn set_renderer(self, renderer: Renderer) -> Style:
        """Set the renderer for the style.

        Args:
            renderer: The renderer to set.

        Returns:
            A new Style object with the renderer set.
        """
        var new_style = self.copy()
        new_style.renderer = renderer
        return new_style

    fn set_string(self, value: String) -> Style:
        """Set the string value for the style.

        Args:
            value: The string value to set.

        Returns:
            A new Style object with the string value set.
        """
        var new_style = self.copy()
        new_style.value = value
        return new_style

    fn _set_rule(self, key: PropertyKey, value: Rule) -> Style:
        """Set a rule on the style.

        Args:
            key: The key to set.
            value: The value to set.

        Returns:
            A new Style object with the rule set.
        """
        var new_style = self.copy()
        new_style.rules.put(str(key), value)
        return new_style

    fn _unset_rule(self, key: PropertyKey) -> Style:
        """Unset a rule on the style.

        Args:
            key: The key to unset.

        Returns:
            A new Style object with the rule unset.
        """
        var new_style = self.copy()
        new_style.rules.delete(str(key))
        return new_style

    fn tab_width(self, width: Int) -> Style:
        """Aets the number of spaces that a tab (/t) should be rendered as.
        When set to 0, tabs will be removed. To disable the replacement of tabs with
        spaces entirely, set this to [NO_TAB_CONVERSION].

        By default, tabs will be replaced with 4 spaces.

        Args:
            width: The tab width to apply.

        Returns:
            A new Style object with the tab width rule set.
        """
        return self._set_rule(TAB_WIDTH_KEY, width)

    fn unset_tab_width(self) -> Style:
        """Unset the tab width of the text.

        Returns:
            A new Style object with the tab width rule unset.
        """
        return self._unset_rule(TAB_WIDTH_KEY)

    fn underline_spaces(self, value: Bool = True) -> Style:
        """Determines whether to underline spaces between words.
        Spaces can also be underlined without underlining the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the crossout rule set.
        """
        return self._set_rule(UNDERLINE_SPACES_KEY, value)

    fn unset_underline_spaces(self) -> Style:
        """Unset the underline spaces rule.

        Returns:
            A new Style object with the underline spaces rule unset.
        """
        return self._unset_rule(UNDERLINE_SPACES_KEY)

    fn crossout_spaces(self, value: Bool = True) -> Style:
        """Determines whether to crossout spaces between words. Spaces can also be
        crossed out without crossout on the text itself.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the crossout rule set.
        """
        return self._set_rule(CROSSOUT_SPACES_KEY, value)

    fn unset_crossout_spaces(self) -> Style:
        """Unset the crossout spaces rule.

        Returns:
            A new Style object with the crossout spaces rule unset.
        """
        return self._unset_rule(CROSSOUT_SPACES_KEY)

    fn color_whitespace(self, value: Bool = True) -> Style:
        """Determines whether to color whitespace.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the color whitespace rule set.
        """
        return self._set_rule(COLOR_WHITESPACE_KEY, value)

    fn unset_color_whitespace(self) -> Style:
        """Unset the color whitespace rule.

        Returns:
            A new Style object with the color whitespace rule unset.
        """
        return self._unset_rule(COLOR_WHITESPACE_KEY)

    fn inline(self, value: Bool = True) -> Style:
        """Makes rendering output one line and disables the rendering of
        margins, padding and borders. This is useful when you need a style to apply
        only to font rendering and don't want it to change any physical dimensions.
        It works well with Style.max_width.

        Because this in intended to be used at the time of render, this method will
        not mutate the style and instead return a copy.

        Example:

            var: String = "..."
            var user_style = Style.new().inline(True)
            print(user_style.render(user_input))

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the bold rule set.
        """
        return self._set_rule(INLINE_KEY, value)

    fn unset_inline(self) -> Style:
        """Unset the inline rule.

        Returns:
            A new Style object with the inline rule unset.
        """
        return self._unset_rule(INLINE_KEY)

    fn bold(self, value: Bool = True) -> Style:
        """Set the text to be bold.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the bold rule set.
        """
        return self._set_rule(BOLD_KEY, value)

    fn italic(self, value: Bool = True) -> Style:
        """Set the text to be italic.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the italic rule set.
        """
        return self._set_rule(ITALIC_KEY, value)

    fn underline(self, value: Bool = True) -> Style:
        """Set the text to be underline.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the underline rule set.
        """
        return self._set_rule(UNDERLINE_KEY, value)

    fn crossout(self, value: Bool = True) -> Style:
        """Set the text to be crossed out.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the crossout rule set.
        """
        return self._set_rule(CROSSOUT_KEY, value)

    fn reverse(self, value: Bool = True) -> Style:
        """Set the text have the foreground and background colors reversed.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the reverse rule set.
        """
        return self._set_rule(REVERSE_KEY, value)

    fn blink(self, value: Bool = True) -> Style:
        """Set the text to blink.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the blink rule set.
        """
        return self._set_rule(BLINK_KEY, value)

    fn faint(self, value: Bool = True) -> Style:
        """Set the text to be faint.

        Args:
            value: Value to set the rule to.

        Returns:
            A new Style object with the faint rule set.
        """
        return self._set_rule(FAINT_KEY, value)

    fn unset_bold(self) -> Style:
        """Unset the bold rule.

        Returns:
            A new Style object with the bold rule unset.
        """
        return self._unset_rule(BOLD_KEY)

    fn unset_italic(self) -> Style:
        """Unset the italic rule.

        Returns:
            A new Style object with the italic rule unset.
        """
        return self._unset_rule(ITALIC_KEY)

    fn unset_underline(self) -> Style:
        """Unset the text to be underline.

        Returns:
            A new Style object with the underline rule set.
        """
        return self._unset_rule(UNDERLINE_KEY)

    fn unset_crossout(self) -> Style:
        """Unset the crossout rule.

        Returns:
            A new Style object with the crossout rule unset.
        """
        return self._unset_rule(CROSSOUT_KEY)

    fn unset_reverse(self) -> Style:
        """Unset the reverse rule.

        Returns:
            A new Style object with the reverse rule unset.
        """
        return self._unset_rule(REVERSE_KEY)

    fn unset_blink(self) -> Style:
        """Unset the blink rule.

        Returns:
            A new Style object with the blink rule unset.
        """
        return self._unset_rule(BLINK_KEY)

    fn unset_faint(self) -> Style:
        """Unset the text to be faint.

        Returns:
            A new Style object with the faint rule unset.
        """
        return self._unset_rule(FAINT_KEY)

    fn width(self, width: Int) -> Style:
        """Set the width of the text.

        Args:
            width: The width to apply.

        Returns:
            A new Style object with the width rule set.
        """
        return self._set_rule(WIDTH_KEY, width)

    fn unset_width(self) -> Style:
        """Unset the width of the text.

        Returns:
            A new Style object with the width rule unset.
        """
        return self._unset_rule(WIDTH_KEY)

    fn height(self, height: Int) -> Style:
        """Set the height of the text.

        Args:
            height: The height to apply.

        Returns:
            A new Style object with the height rule set.
        """
        return self._set_rule(HEIGHT_KEY, height)

    fn unset_height(self) -> Style:
        """Unset the height of the text.

        Returns:
            A new Style object with the height rule unset.
        """
        return self._unset_rule(HEIGHT_KEY)

    fn max_width(self, width: Int) -> Style:
        """Applies a max width to a given style. This is useful in enforcing
        a certain width at render time, particularly with arbitrary strings and
        styles.

        Because this in intended to be used at the time of render, this method will
        not mutate the style and instead return a copy.

        Example:
            var: String = "..."
            var user_style = Style.new().max_width(16)
            print(user_style.render(user_input))

        Args:
            width: The maximum height to apply.

        Returns:
            A new Style object with the maximum width rule set.
        """
        return self._set_rule(MAX_WIDTH_KEY, width)

    fn unset_max_width(self) -> Style:
        """Unset the max width of the text.

        Returns:
            A new Style object with the max width rule unset.
        """
        return self._unset_rule(MAX_WIDTH_KEY)

    fn max_height(self, height: Int) -> Style:
        """Set the maximum height of the text.

        Args:
            height: The maximum height to apply.

        Returns:
            A new Style object with the maximum height rule set.
        """
        return self._set_rule(MAX_HEIGHT_KEY, height)

    fn unset_max_height(self) -> Style:
        """Unset the max height of the text.

        Returns:
            A new Style object with the max height rule unset.
        """
        return self._unset_rule(MAX_HEIGHT_KEY)

    fn horizontal_alignment(self, align: Position) -> Style:
        """Set the horizontal alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style object with the alignment rule set.
        """
        return self._set_rule(HORIZONTAL_ALIGNMENT_KEY, align)

    fn unset_horizontal_alignment(self) -> Style:
        """Unset the horizontal alignment of the text.

        Returns:
            A new Style object with the horizontal alignment rule unset.
        """
        return self._unset_rule(HORIZONTAL_ALIGNMENT_KEY)

    fn vertical_alignment(self, align: Position) -> Style:
        """Set the vertical alignment of the text.

        Args:
            align: The alignment value to apply.

        Returns:
            A new Style object with the alignment rule set.
        """
        return self._set_rule(VERTICAL_ALIGNMENT_KEY, align)

    fn unset_vertical_alignment(self) -> Style:
        """Unset the vertical alignment of the text.

        Returns:
            A new Style object with the vertical alignment rule unset.
        """
        return self._unset_rule(VERTICAL_ALIGNMENT_KEY)

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
        var new_style = self.copy()

        if len(align) > 0:
            new_style.rules.put(str(HORIZONTAL_ALIGNMENT_KEY), align[0])
        if len(align) > 1:
            new_style.rules.put(str(VERTICAL_ALIGNMENT_KEY), align[1])
        return new_style

    fn foreground(self, color: AnyTerminalColor) -> Style:
        """Set the foreground color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the foreground color rule set.
        """
        return self._set_rule(FOREGROUND_KEY, color)

    fn unset_foreground(self) -> Style:
        """Unset the foreground color of the text.

        Returns:
            A new Style object with the foreground color rule unset.
        """
        return self._unset_rule(FOREGROUND_KEY)

    fn background(self, color: AnyTerminalColor) -> Style:
        """Set the background color of the text.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the background color rule set.
        """
        return self._set_rule(BACKGROUND_KEY, color)

    fn unset_background(self) -> Style:
        """Unset the background color of the text.

        Returns:
            A new Style object with the background color rule unset.
        """
        return self._unset_rule(BACKGROUND_KEY)

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
        var new_style = self.copy()
        new_style.rules.put(str(BORDER_STYLE_KEY), border)

        if top:
            new_style.rules.put(str(BORDER_TOP_KEY), True)
        if right:
            new_style.rules.put(str(BORDER_RIGHT_KEY), True)
        if bottom:
            new_style.rules.put(str(BORDER_BOTTOM_KEY), True)
        if left:
            new_style.rules.put(str(BORDER_LEFT_KEY), True)

        return new_style

    fn border_top(self, top: Bool) -> Style:
        """Sets the top border to be rendered or not.

        Args:
            top: Whether to apply the border to the top side.

        Returns:
            A new Style object with the border rule set.
        """
        return self._set_rule(BORDER_TOP_KEY, top)

    fn unset_border_top(self) -> Style:
        """Unsets the top border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        return self._unset_rule(BORDER_TOP_KEY)

    fn border_bottom(self, bottom: Bool) -> Style:
        """Sets the bottom border to be rendered or not.

        Args:
            bottom: Whether to apply the border to the bottom side.

        Returns:
            A new Style object with the border rule set.
        """
        return self._set_rule(BORDER_BOTTOM_KEY, bottom)

    fn unset_border_bottom(self) -> Style:
        """Unsets the bottom border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        return self._unset_rule(BORDER_BOTTOM_KEY)

    fn border_left(self, left: Bool) -> Style:
        """Sets the left border to be rendered or not.

        Args:
            left: Whether to apply the border to the left side.

        Returns:
            A new Style object with the border rule set.
        """
        return self._set_rule(BORDER_LEFT_KEY, left)

    fn unset_border_left(self) -> Style:
        """Unsets the left border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        return self._unset_rule(BORDER_LEFT_KEY)

    fn border_right(self, right: Bool) -> Style:
        """Sets the right border to be rendered or not.

        Args:
            right: Whether to apply the border to the right side.

        Returns:
            A new Style object with the border rule set.
        """
        return self._set_rule(BORDER_RIGHT_KEY, right)

    fn unset_border_right(self) -> Style:
        """Unsets the right border rule.

        Returns:
            A new Style object with the border rule unset.
        """
        return self._unset_rule(TAB_WIDTH_KEY)

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
            new_style.border_top_foreground(top)
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
        return self._set_rule(BORDER_TOP_FOREGROUND_KEY, color)

    fn unset_border_top_foreground(self) -> Style:
        """Unsets the top border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        return self._unset_rule(BORDER_TOP_FOREGROUND_KEY)

    fn border_right_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the right border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        return self._set_rule(BORDER_RIGHT_FOREGROUND_KEY, color)

    fn unset_border_right_foreground(self) -> Style:
        """Unsets the right border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        return self._unset_rule(BORDER_RIGHT_FOREGROUND_KEY)

    fn border_left_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the left border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        return self._set_rule(BORDER_LEFT_FOREGROUND_KEY, color)

    fn unset_border_left_foreground(self) -> Style:
        """Unsets the left border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        return self._unset_rule(BORDER_LEFT_FOREGROUND_KEY)

    fn border_bottom_foreground(self, color: AnyTerminalColor) -> Style:
        """Set the bottom border foreground color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border foreground color rule set.
        """
        return self._set_rule(BORDER_BOTTOM_FOREGROUND_KEY, color)

    fn unset_border_bottom_foreground(self) -> Style:
        """Unsets the bottom border foreground rule.

        Returns:
            A new Style object with the border foreground rule unset.
        """
        return self._unset_rule(BORDER_BOTTOM_FOREGROUND_KEY)

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
        return self._set_rule(BORDER_TOP_BACKGROUND_KEY, color)

    fn unset_border_top_background(self) -> Style:
        """Unsets the top border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        return self._unset_rule(BORDER_TOP_BACKGROUND_KEY)

    fn border_right_background(self, color: AnyTerminalColor) -> Style:
        """Set the right border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        return self._set_rule(BORDER_RIGHT_BACKGROUND_KEY, color)

    fn unset_border_right_background(self) -> Style:
        """Unsets the right border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        return self._unset_rule(BORDER_RIGHT_BACKGROUND_KEY)

    fn border_left_background(self, color: AnyTerminalColor) -> Style:
        """Set the left border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        return self._set_rule(BORDER_LEFT_BACKGROUND_KEY, color)

    fn unset_border_left_background(self) -> Style:
        """Unsets the left border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        return self._unset_rule(BORDER_LEFT_BACKGROUND_KEY)

    fn border_bottom_background(self, color: AnyTerminalColor) -> Style:
        """Set the bottom border background color.

        Args:
            color: The color to apply.

        Returns:
            A new Style object with the border background color rule set.
        """
        return self._set_rule(BORDER_BOTTOM_BACKGROUND_KEY, color)

    fn unset_border_bottom_background(self) -> Style:
        """Unsets the bottom border background rule.

        Returns:
            A new Style object with the border background rule unset.
        """
        return self._unset_rule(BORDER_BOTTOM_BACKGROUND_KEY)

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
        var new_style = self.copy()
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
            return new_style

        new_style = new_style.padding_top(top).padding_right(right).padding_bottom(bottom).padding_left(left)
        return new_style

    fn padding_top(self, width: Int) -> Style:
        """Set the padding on the top side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding top rule set.
        """
        return self._set_rule(PADDING_TOP_KEY, width)

    fn unset_padding_top(self) -> Style:
        """Unset the padding top rule.

        Returns:
            A new Style object with the padding top rule unset.
        """
        return self._unset_rule(PADDING_TOP_KEY)

    fn padding_right(self, width: Int) -> Style:
        """Set the padding on the right side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding right rule set.
        """
        return self._set_rule(PADDING_RIGHT_KEY, width)

    fn unset_padding_right(self) -> Style:
        """Unset the padding right rule.

        Returns:
            A new Style object with the padding right rule unset.
        """
        return self._unset_rule(PADDING_RIGHT_KEY)

    fn padding_bottom(self, width: Int) -> Style:
        """Set the padding on the bottom side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding bottom rule set.
        """
        return self._set_rule(PADDING_BOTTOM_KEY, width)

    fn unset_padding_bottom(self) -> Style:
        """Unset the padding bottom rule.

        Returns:
            A new Style object with the padding bottom rule unset.
        """
        return self._unset_rule(PADDING_BOTTOM_KEY)

    fn padding_left(self, width: Int) -> Style:
        """Set the padding on the left side.

        Args:
            width: The padding width to apply.

        Returns:
            A new Style object with the padding left rule set.
        """
        return self._set_rule(PADDING_LEFT_KEY, width)

    fn unset_padding_left(self) -> Style:
        """Unset the padding left rule.

        Returns:
            A new Style object with the padding left rule unset.
        """
        return self._unset_rule(PADDING_LEFT_KEY)

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
        var new_style = self.copy()
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
            return new_style

        new_style = new_style.margin_top(top).margin_right(right).margin_bottom(bottom).margin_left(left)
        return new_style

    fn margin_top(self, width: Int) -> Style:
        """Set the margin on the top side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin top rule set.
        """
        return self._set_rule(MARGIN_TOP_KEY, width)

    fn unset_margin_top(self) -> Style:
        """Unset the margin top rule.

        Returns:
            A new Style object with the margin top rule unset.
        """
        return self._unset_rule(MARGIN_TOP_KEY)

    fn margin_right(self, width: Int) -> Style:
        """Set the margin on the right side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin right rule set.
        """
        return self._set_rule(MARGIN_RIGHT_KEY, width)

    fn unset_margin_right(self) -> Style:
        """Unset the margin right rule.

        Returns:
            A new Style object with the margin right rule unset.
        """
        return self._unset_rule(MARGIN_RIGHT_KEY)

    fn margin_bottom(self, width: Int) -> Style:
        """Set the margin on the bottom side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin bottom rule set.
        """
        return self._set_rule(MARGIN_BOTTOM_KEY, width)

    fn unset_margin_bottom(self) -> Style:
        """Unset the margin bottom rule.

        Returns:
            A new Style object with the margin bottom rule unset.
        """
        return self._unset_rule(MARGIN_BOTTOM_KEY)

    fn margin_left(self, width: Int) -> Style:
        """Set the margin on the left side.

        Args:
            width: The margin width to apply.

        Returns:
            A new Style object with the margin left rule set.
        """
        return self._set_rule(MARGIN_LEFT_KEY, width)

    fn unset_margin_left(self) -> Style:
        """Unset the margin left rule.

        Returns:
            A new Style object with the margin left rule unset.
        """
        return self._unset_rule(MARGIN_LEFT_KEY)

    fn margin_background(self, color: AnyTerminalColor) -> Style:
        """Set the margin on the background color.

        Args:
            color: The margin width to apply.

        Returns:
            A new Style object with the margin background rule set.
        """
        return self._set_rule(MARGIN_BACKGROUND_KEY, color)

    fn unset_margin_background(self) -> Style:
        """Unset the margin background rule.

        Returns:
            A new Style object with the margin background rule unset.
        """
        return self._unset_rule(MARGIN_BACKGROUND_KEY)

    fn maybe_convert_tabs(self, text: String) -> String:
        """Convert tabs to spaces if the tab width is set.

        Args:
            text: The text to convert tabs in.

        Returns:
            The text with tabs converted to spaces.
        """
        var DEFAULT_TAB_WIDTH = TAB_WIDTH
        if self.is_set(TAB_WIDTH_KEY):
            DEFAULT_TAB_WIDTH = self.get_as_int(str(TAB_WIDTH_KEY), DEFAULT_TAB_WIDTH)

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

        var styler = mist.TerminalStyle.new()

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
        var has_top = self.get_as_bool(str(BORDER_TOP_KEY), False)
        var has_right = self.get_as_bool(str(BORDER_RIGHT_KEY), False)
        var has_bottom = self.get_as_bool(str(BORDER_BOTTOM_KEY), False)
        var has_left = self.get_as_bool(str(BORDER_LEFT_KEY), False)

        # FG Colors
        var top_fg = self.get_as_color(str(BORDER_TOP_FOREGROUND_KEY), NoColor())
        var right_fg = self.get_as_color(str(BORDER_RIGHT_FOREGROUND_KEY), NoColor())
        var bottom_fg = self.get_as_color(str(BORDER_BOTTOM_FOREGROUND_KEY), NoColor())
        var left_fg = self.get_as_color(str(BORDER_LEFT_FOREGROUND_KEY), NoColor())

        # BG Colors
        var top_bg = self.get_as_color(str(BORDER_TOP_BACKGROUND_KEY), NoColor())
        var right_bg = self.get_as_color(str(BORDER_RIGHT_BACKGROUND_KEY), NoColor())
        var bottom_bg = self.get_as_color(str(BORDER_BOTTOM_BACKGROUND_KEY), NoColor())
        var left_bg = self.get_as_color(str(BORDER_LEFT_BACKGROUND_KEY), NoColor())

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
        var top_margin = self.get_as_int(str(MARGIN_TOP_KEY))
        var right_margin = self.get_as_int(str(MARGIN_RIGHT_KEY))
        var bottom_margin = self.get_as_int(str(MARGIN_BOTTOM_KEY))
        var left_margin = self.get_as_int(str(MARGIN_LEFT_KEY))

        var styler = mist.TerminalStyle.new(self.renderer.color_profile)

        var bgc = self.get_as_color(str(MARGIN_BACKGROUND_KEY), NoColor())

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
        var term_style = mist.TerminalStyle(p)
        var term_style_space = mist.TerminalStyle(p)
        var term_style_whitespace = mist.TerminalStyle(p)

        var bold: Bool = self.get_as_bool(str(BOLD_KEY), False)
        var italic: Bool = self.get_as_bool(str(ITALIC_KEY), False)
        var underline: Bool = self.get_as_bool(str(UNDERLINE_KEY), False)
        var crossout: Bool = self.get_as_bool(str(CROSSOUT_KEY), False)
        var reverse: Bool = self.get_as_bool(str(REVERSE_KEY), False)
        var blink: Bool = self.get_as_bool(str(BLINK_KEY), False)
        var faint: Bool = self.get_as_bool(str(FAINT_KEY), False)

        var fg = self.get_as_color(str(FOREGROUND_KEY), NoColor())
        var bg = self.get_as_color(str(BACKGROUND_KEY), NoColor())

        var width: Int = self.get_as_int(str(WIDTH_KEY))
        var height: Int = self.get_as_int(str(HEIGHT_KEY))
        var top_padding: Int = self.get_as_int(str(PADDING_TOP_KEY))
        var right_padding: Int = self.get_as_int(str(PADDING_RIGHT_KEY))
        var bottom_padding: Int = self.get_as_int(str(PADDING_BOTTOM_KEY))
        var left_padding: Int = self.get_as_int(str(PADDING_LEFT_KEY))

        var horizontal_align: Position = self.get_as_position(str(HORIZONTAL_ALIGNMENT_KEY))
        var vertical_align: Position = self.get_as_position(str(VERTICAL_ALIGNMENT_KEY))

        var color_whitespace: Bool = self.get_as_bool(str(COLOR_WHITESPACE_KEY), True)
        var inline: Bool = self.get_as_bool(str(INLINE_KEY), False)
        var max_width: Int = self.get_as_int(str(MAX_WIDTH_KEY))
        var max_height: Int = self.get_as_int(str(MAX_HEIGHT_KEY))

        var underline_spaces = underline and self.get_as_bool(str(UNDERLINE_SPACES_KEY), True)
        var crossout_spaces = crossout and self.get_as_bool(str(CROSSOUT_SPACES_KEY), True)

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
                var style = mist.TerminalStyle(self.renderer.color_profile)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                styled_text = pad_left(styled_text, left_padding, style)

            if right_padding > 0:
                var style = mist.TerminalStyle(self.renderer.color_profile)
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
            var style = mist.TerminalStyle(self.renderer.color_profile)
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
