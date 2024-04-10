from math import max, min
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
from .size import rune_count_in_string
from .extensions import repeat, join, contains
from .align import align_text_horizontal, align_text_vertical
from external.weave import wrap, wordwrap, truncate
from external.weave.ansi.ansi import len_without_ansi
from external.mist.color import (
    Color,
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
)
from external.mist import TerminalStyle
from external.gojo.strings import StringBuilder


alias tab_width: Int = 4


fn get_lines(s: String) raises -> (List[String], Int):
    """Split a string into lines, additionally returning the size of the widest line.

    Args:
        s: The string to split.
    """
    var lines = s.split("\n")
    var widest: Int = 0
    for i in range(len(lines)):
        # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
        if rune_count_in_string(lines[i]) > widest:
            widest = rune_count_in_string(lines[i])

    return lines, widest


fn to_bool(s: String) -> Bool:
    var truthy_values: List[String] = List[String]()
    truthy_values.append("true")
    truthy_values.append("True")
    truthy_values.append("TRUE")
    truthy_values.append("1")

    if contains(truthy_values, s):
        return True

    return False


fn str_to_float(s: String) raises -> Float64:
    try:
        # locate decimal point
        var dot_pos = s.find(".")
        # grab the integer part of the number
        var int_str = s[0:dot_pos]
        # grab the decimal part of the number
        var num_str = s[dot_pos + 1 : len(s)]
        # set the numerator to be the integer equivalent
        var numerator = atol(num_str)
        # construct denom_str to be "1" + "0"s for the length of the fraction
        var denom_str = String()
        for _ in range(len(num_str)):
            denom_str += "0"
        var denominator = atol("1" + denom_str)
        # school-level maths here :)
        var frac = numerator / denominator

        # return the number as a Float64
        var result: Float64 = atol(int_str) + frac
        return result
    except:
        raise Error("Failed to convert " + s + " to a float.")


alias TransformFunction = fn (s: String) -> String


# Apply left padding.
fn pad_left(text: String, n: Int, style: TerminalStyle) raises -> String:
    if n == 0:
        return text
    var sp = repeat(" ", n)

    sp = style.render(sp)

    var padded_text: String = ""
    var lines = text.split("\n")

    for i in range(len(lines)):
        padded_text += sp
        padded_text += lines[i]
        if i != len(lines) - 1:
            padded_text += "\n"

    return padded_text


# Apply right padding.
fn pad_right(text: String, n: Int, style: TerminalStyle) raises -> String:
    if n == 0 or text == "":
        return text

    var sp = repeat(" ", n)

    sp = style.render(sp)

    var padded_text: String = ""
    var lines = text.split("\n")

    for i in range(len(lines)):
        padded_text += lines[i]
        padded_text += sp
        if i != len(lines) - 1:
            padded_text += "\n"

    return padded_text


@value
struct Style:
    var renderer: Renderer
    var rules: Dict[String]

    fn __init__(
        inout self,
        renderer: Renderer = Renderer(),
        rules: Dict[String] = Dict[String](),
    ):
        self.renderer = Renderer()
        self.rules = Dict[String]()

    @staticmethod
    fn new(
        renderer: Renderer = Renderer(),
        rules: Dict[String] = Dict[String](),
    ) -> Self:
        return Self(renderer, rules)

    fn get_as_bool(self, key: String, default: Bool) -> Bool:
        var result = self.rules.get(key, String(default))
        if result == String(default):
            return default

        return to_bool(result)

    fn get_as_color(self, key: String) -> String:
        return self.rules.get(key, "")
        # var result = self.rules.get(key, "")
        # if result == "":
        #     return NoColor()

        # if result[0] == "#":
        #     return RGBColor(result)

        # var ansi_code = atol(result)
        # if ansi_code > 16:
        #     return ANSI256Color(ansi_code)
        # else:
        #     return ANSIColor(ansi_code)

    fn get_as_int(self, key: String, default: Int = 0) raises -> Int:
        var result = self.rules.get(key, String(default))
        if result == String(default):
            return default

        return atol(result)

    fn get_as_position(self, key: String) raises -> Position:
        var result = self.rules.get(key, "")
        if result == "":
            return Position(0)

        return Position(str_to_float(result))

    fn get_border_style(self) raises -> Border:
        var val = self.rules.get("border_style", "")
        if val == "":
            return no_border()

        if val == "no_border":
            return no_border()
        elif val == "hidden_border":
            return hidden_border()
        elif val == "double_border":
            return double_border()
        elif val == "rounded_border":
            return rounded_border()
        elif val == "normal_border":
            return normal_border()
        elif val == "block_border":
            return block_border()
        elif val == "inner_half_block_border":
            return inner_half_block_border()
        elif val == "outer_half_block_border":
            return outer_half_block_border()
        elif val == "thick_border":
            return thick_border()
        elif val == "ascii_border":
            return ascii_border()
        elif val == "star_border":
            return star_border()
        elif val == "plus_border":
            return plus_border()
        else:
            return no_border()

    fn is_set(self, key: String) -> Bool:
        for i in range(len(self.rules.keys)):
            if String(self.rules.keys[i]) == key:
                return True

        return False

    # fn get_as_transform(self, key: String) raises -> TransformFunction:
    #     var val = self.rules.get(key, "0")
    #     return val

    fn set_rule(inout self, key: String, value: String):
        self.rules.put(key, value)

    fn bold(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("bold", "True")
        return new_style

    fn italic(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("italic", "True")
        return new_style

    fn underline(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("underline", "True")
        return new_style

    fn crossout(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("crossout", "True")
        return new_style

    fn reverse(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("reverse", "True")
        return new_style

    fn blink(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("blink", "True")
        return new_style

    fn faint(self) -> Style:
        var new_style = self.copy()
        new_style.set_rule("faint", "True")
        return new_style

    fn width(self, width: Int) -> Style:
        var new_style = self.copy()
        new_style.set_rule("width", width)
        return new_style

    fn height(self, height: Int) -> Style:
        var new_style = self.copy()
        new_style.set_rule("height", height)
        return new_style

    fn max_width(self, width: Int) -> Style:
        var new_style = self.copy()
        new_style.set_rule("max_width", width)
        return new_style

    fn max_height(self, height: Int) -> Style:
        var new_style = self.copy()
        new_style.set_rule("max_height", height)
        return new_style

    fn horizontal_alignment(self, align: Position) -> Style:
        var new_style = self.copy()
        new_style.set_rule("horizontal_alignment", String(align))
        return new_style

    fn vertical_alignment(self, align: Position) -> Style:
        var new_style = self.copy()
        new_style.set_rule("vertical_alignment", String(align))
        return new_style

    fn foreground(self, color: String) -> Style:
        var new_style = self.copy()
        new_style.set_rule("foreground", color)
        return new_style

    fn background(self, color: String) -> Style:
        var new_style = self.copy()
        new_style.set_rule("background", color)
        return new_style

    fn border(
        self,
        border: String,
        top: Bool = True,
        right: Bool = True,
        bottom: Bool = True,
        left: Bool = True,
    ) -> Style:
        var new_style = self.copy()
        new_style.set_rule("border_style", border)

        if top:
            new_style.set_rule("border_top_key", "True")
        if right:
            new_style.set_rule("border_right_key", "True")
        if bottom:
            new_style.set_rule("border_bottom_key", "True")
        if left:
            new_style.set_rule("border_left_key", "True")

        return new_style

    fn border_foreground(self, color: String) -> Style:
        var new_style = self.copy()
        new_style.set_rule("border_top_foreground_key", color)
        new_style.set_rule("border_right_foreground_key", color)
        new_style.set_rule("border_bottom_foreground_key", color)
        new_style.set_rule("border_left_foreground_key", color)
        return new_style

    fn border_background(self, color: String) -> Style:
        var new_style = self.copy()
        new_style.set_rule("border_top_background_key", color)
        new_style.set_rule("border_right_background_key", color)
        new_style.set_rule("border_bottom_background_key", color)
        new_style.set_rule("border_left_background_key", color)
        return new_style

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

        new_style = new_style.padding_top(top) \
        .padding_right(right) \
        .padding_bottom(bottom) \
        .padding_left(left)
        return new_style

    fn padding_top(self, width: UInt8) -> Style:
        var new_style = self.copy()
        new_style.set_rule("padding_top", String(width))
        return new_style

    fn padding_right(self, width: UInt8) -> Style:
        var new_style = self.copy()
        new_style.set_rule("padding_right", String(width))
        return new_style

    fn padding_bottom(self, width: UInt8) -> Style:
        var new_style = self.copy()
        new_style.set_rule("padding_bottom", String(width))
        return new_style

    fn padding_left(self, width: UInt8) -> Style:
        var new_style = self.copy()
        new_style.set_rule("padding_left", String(width))
        return new_style

    fn maybe_convert_tabs(self, text: String) raises -> String:
        var default_tab_width: Int = tab_width
        if self.is_set("tab_width"):
            default_tab_width = self.get_as_int("tab_width", default_tab_width)

        if default_tab_width == -1:
            return text
        if default_tab_width == 0:
            return text.replace("\t", "")
        else:
            return text.replace("\t", repeat(" ", default_tab_width))

    fn style_border(self, border: String, fg: String, bg: String) -> String:
        var styler = TerminalStyle.new(self.renderer.color_profile).foreground(
            fg
        ).background(bg)

        return styler.render(border)

    fn apply_border(self, text: String) raises -> String:
        var top_set = self.is_set("border_top_key")
        var right_set = self.is_set("border_right_key")
        var bottom_set = self.is_set("border_bottom_key")
        var left_set = self.is_set("border_left_key")

        var border = self.get_border_style()
        var has_top = self.get_as_bool("border_top_key", False)
        var has_right = self.get_as_bool("border_right_key", False)
        var has_bottom = self.get_as_bool("border_bottom_key", False)
        var has_left = self.get_as_bool("border_left_key", False)

        # FG Colors
        var top_fg = self.get_as_color("border_top_foreground_key")
        var right_fg = self.get_as_color("border_right_foreground_key")
        var bottom_fg = self.get_as_color("border_bottom_foreground_key")
        var left_fg = self.get_as_color("border_left_foreground_key")

        # BG Colors
        var top_bg = self.get_as_color("border_top_background_key")
        var right_bg = self.get_as_color("border_right_background_key")
        var bottom_bg = self.get_as_color("border_bottom_background_key")
        var left_bg = self.get_as_color("border_left_background_key")

        # If a border is set and no sides have been specifically turned on or off
        # render borders on all sideself.
        var borderless = no_border()
        if border != borderless and not (
            top_set or right_set or bottom_set or left_set
        ):
            has_top = True
            has_right = True
            has_bottom = True
            has_left = True

        # If no border is set or all borders are been disabled, abort.
        if border == borderless or (
            not has_top and not has_right and not has_bottom and not has_left
        ):
            return text

        var lines = text.split("\n")

        var width: Int = 0
        for i in range(len(lines)):
            var rune_count = len_without_ansi(lines[i])
            if rune_count > width:
                width = rune_count

        if has_left:
            if border.left == "":
                border.left = " "

            width += rune_count_in_string(border.left)

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

        var builder = StringBuilder()

        # Render top
        if has_top:
            var top = render_horizontal_edge(
                border.top_left, border.top, border.top_right, width
            )
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

        # TODO: Do the ansi characters here impact the len of left and right runes? Need to check
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

                _ = builder.write_string(
                    self.style_border(r, right_fg, right_bg)
                )

            if i < len(lines) - 1:
                _ = builder.write_string("\n")

        # Render bottom
        if has_bottom:
            var bottom = render_horizontal_edge(
                border.bottom_left, border.bottom, border.bottom_right, width
            )
            bottom = self.style_border(bottom, bottom_fg, bottom_bg)
            _ = builder.write_string("\n")
            _ = builder.write_string(bottom)

        return str(builder)

    fn apply_margins(self, text: String, inline: Bool) raises -> String:
        var padded_text: String = text
        var top_margin = self.get_as_int("margin_top_key")
        var right_margin = self.get_as_int("margin_right_key")
        var bottom_margin = self.get_as_int("margin_bottom_key")
        var left_margin = self.get_as_int("margin_left_key")

        var styler: TerminalStyle = TerminalStyle(self.renderer.color_profile)

        var bgc = self.get_as_color("margin_background_key")

        # if not bgc.isa[NoColor]():
        if bgc != "":
            styler = styler.background(bgc)

        # Add left and right margin
        padded_text = pad_left(padded_text, left_margin, styler)
        padded_text = pad_right(padded_text, right_margin, styler)

        # Top/bottom margin
        if not inline:
            var lines = text.split("\n")
            var width: Int = 0
            for i in range(len(lines)):
                # TODO: Should be rune length instead of str length. Some runes are longer than 1 char.
                if len(lines[i]) > width:
                    width = len(lines[i])

            var spaces = repeat(" ", width)

            if top_margin > 0:
                padded_text = repeat("\n", top_margin) + padded_text
            if bottom_margin > 0:
                padded_text += repeat("\n", bottom_margin)

        return padded_text

    fn render(self, text: String) raises -> String:
        var input_text: String = text

        var p = self.renderer.color_profile
        var term_style = TerminalStyle(p)
        var term_style_space = TerminalStyle(p)
        var term_style_whitespace = TerminalStyle(p)

        var bold: Bool = self.get_as_bool("bold", False)
        var italic: Bool = self.get_as_bool("italic", False)
        var underline: Bool = self.get_as_bool("underline", False)
        var crossout: Bool = self.get_as_bool("crossout", False)
        var reverse: Bool = self.get_as_bool("reverse", False)
        var blink: Bool = self.get_as_bool("blink", False)
        var faint: Bool = self.get_as_bool("faint", False)

        var fg = self.get_as_color("foreground")
        var bg = self.get_as_color("background")

        var width: Int = self.get_as_int("width")
        var height: Int = self.get_as_int("height")
        var top_padding: Int = self.get_as_int("padding_top")
        var right_padding: Int = self.get_as_int("padding_right")
        var bottom_padding: Int = self.get_as_int("padding_bottom")
        var left_padding: Int = self.get_as_int("padding_left")

        var horizontal_align: Position = self.get_as_position(
            "horizontal_alignment"
        )
        var vertical_align: Position = self.get_as_position(
            "vertical_alignment"
        )

        var color_whitespace: Bool = self.get_as_bool("color_whitespace", True)
        var inline: Bool = self.get_as_bool("inline", False)
        var max_width: Int = self.get_as_int("max_width")
        var max_height: Int = self.get_as_int("max_height")

        var underline_spaces = underline and self.get_as_bool(
            "underline_spaces", True
        )
        var crossout_spaces = crossout and self.get_as_bool(
            "crossout_spaces", True
        )

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

        if fg != "":
            term_style = term_style.foreground(fg)
            if use_space_styler:
                term_style_space = term_style_space.foreground(fg)
            if use_whitespace_styler:
                term_style_whitespace = term_style_whitespace.foreground(fg)
        if bg != "":
            term_style = term_style.background(bg)
            if use_space_styler:
                term_style_space = term_style_space.background(bg)
            if color_whitespace:
                term_style_whitespace = term_style_whitespace.background(bg)

        if underline_spaces:
            term_style = term_style_space.underline()
        if crossout_spaces:
            term_style = term_style_space.crossout()

        if inline:
            input_text = input_text.replace("\n", "")

        # Word wrap
        if (not inline) and (width > 0):
            var wrap_at = width - left_padding - right_padding
            input_text = wordwrap.apply_wordwrap(input_text, wrap_at)
            input_text = wrap.apply_wrap(
                input_text, wrap_at
            )  # force-wrap long strings

        input_text = self.maybe_convert_tabs(input_text)

        var builder = StringBuilder()
        var lines = input_text.split("\n")
        for i in range(len(lines)):
            var line = lines[i]
            if use_space_styler:
                # Look for spaces and apply a different styler
                for i in range(len_without_ansi(line)):
                    var character = line[i]
                    if character == " ":
                        _ = builder.write_string(
                            term_style_space.render(character)
                        )
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
                var style = TerminalStyle(self.renderer.color_profile)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                styled_text = pad_left(styled_text, left_padding, style)

            if right_padding > 0:
                var style = TerminalStyle(self.renderer.color_profile)
                if color_whitespace or use_whitespace_styler:
                    style = term_style_whitespace
                styled_text = pad_right(styled_text, right_padding, style)

            if top_padding > 0:
                styled_text = repeat("\n", top_padding) + styled_text

            if bottom_padding > 0:
                styled_text += repeat("\n", bottom_padding)

        # Alignment
        if height > 0:
            styled_text = align_text_vertical(
                styled_text, vertical_align, height
            )

        # Truncate according to max_width
        if max_width > 0:
            var lines = styled_text.split("\n")

            for i in range(len(lines)):
                lines[i] = truncate.apply_truncate(lines[i], max_width)

            styled_text = join("\n", lines)

        # Truncate according to max_height
        if max_height > 0:
            var lines = styled_text.split("\n")
            var truncated_lines = lines[0 : min(max_height, len(lines))]
            styled_text = join("\n", truncated_lines)

        # if transform:
        #     return transform(styled_text)

        # Apply border at the end
        var number_of_lines = len(styled_text.split("\n"))
        if not (number_of_lines == 0 and width == 0):
            var style = TerminalStyle(self.renderer.color_profile)
            if color_whitespace or use_whitespace_styler:
                style = term_style_whitespace
            styled_text = align_text_horizontal(
                styled_text, horizontal_align, width, style
            )

        if not inline:
            styled_text = self.apply_border(styled_text)
            styled_text = self.apply_margins(styled_text, inline)

        return styled_text

    fn copy(self) -> Self:
        return Self(
            renderer=self.renderer,
            rules=self.rules,
        )
