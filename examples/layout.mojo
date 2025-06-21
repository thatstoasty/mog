from mist.transform.ansi import printable_rune_width
from mog.join import join_vertical, join_horizontal
from mog.border import HIDDEN_BORDER, NORMAL_BORDER, ROUNDED_BORDER, Border
from mog.style import Style
from mog.size import get_width
from mog import Position
from mog.whitespace import WhitespaceRenderer
from mog.renderer import Renderer
from mog._properties import Alignment
import mog
import mist._hue as hue

alias width = 96
alias column_width = 30
alias subtle = mog.AdaptiveColor(light=0xD9DCCF, dark=0x383838)
alias highlight = mog.AdaptiveColor(light=0x874BFD, dark=0xFF713C)
alias special = mog.AdaptiveColor(light=0x43BF6D, dark=0x73F59F)


fn color_grid(x_steps: Int, y_steps: Int) -> List[List[hue.Color]]:
    alias x0y0 = hue.Color(0xF25D94)
    alias x1y0 = hue.Color(0xEDFF82)
    alias x0y1 = hue.Color(0x643AFF)
    alias x1y1 = hue.Color(0x14F9D5)

    var x0: List[hue.Color] = [x0y0.blend_luv(x0y1, Float64(i)/Float64(y_steps)) for i in range(y_steps)]
    var x1: List[hue.Color] = [x1y0.blend_luv(x1y1, Float64(i)/Float64(y_steps)) for i in range(y_steps)]

    var grid = List[List[hue.Color]](capacity=y_steps)
    var x = 0
    while x < y_steps:
        var y0 = x0[x]
        grid.append(List[hue.Color](capacity=x_steps))
        var y = 0
        while y < x_steps:
            grid[x].append(y0.blend_luv(x1[x], Float64(y)/Float64(x_steps)))
            y += 1
        x += 1
    return grid^


fn build_tabs() -> String:
    alias active_tab_border = Border(
        top="─",
        bottom=" ",
        left="│",
        right="│",
        top_left="╭",
        top_right="╮",
        bottom_left="┘",
        bottom_right="└",
    )

    alias tab_border = Border(
        top="─",
        bottom="─",
        left="│",
        right="│",
        top_left="╭",
        top_right="╮",
        bottom_left="┴",
        bottom_right="┴",
    )

    alias tab_color = mog.AdaptiveColor(light=0x874BFD, dark=0xFF713C)
    var tab_style = mog.Style().border(tab_border).border_foreground(tab_color).padding(0, 1)
    var active_tab = tab_style.border(active_tab_border, True)
    var tab_gap = tab_style.border_top(False).border_left(False).border_right(False).border_bottom(True)

    var row = join_horizontal(
        Position.TOP,
        active_tab.render("Mog"),
        tab_style.render("Gojo"),
        tab_style.render("Lightbug"),
        tab_style.render("Basalt"),
        tab_style.render("Prism"),
    )
    var gap = tab_gap.render(" " * max(0, width - get_width(row) - 2))
    return join_horizontal(Position.BOTTOM, row, gap)


fn build_description() -> String:
    var colors = color_grid(1, 5)
    var title = String()
    var title_style = mog.Style(value="Mog").margin_left(1).margin_right(5).padding(0, 1).italic(True).foreground(mog.Color(0xFFFDF5))

    for i in range(len(colors)):
        var offset = 2
        var c = mog.Color(colors[i][0].hex())
        title.write(title_style.margin_left(i * offset).background(c).render())
        if i < len(colors) - 1:
            title.write("\n")

    var divider = mog.Style().padding(0, 1).foreground(subtle).render("•")
    var url = mog.Style().foreground(special)
    var desc_style = mog.Style().margin_top(1)
    var info_style = mog.Style().border(NORMAL_BORDER, True, False, False, False).border_foreground(subtle)

    var description = join_vertical(
        Position.LEFT,
        desc_style.render("Style Definitions for Nice Terminal Layouts.\nInspired by charmbracelet/lipgloss"),
        info_style.render("From Mikhail" + divider + url.render("https://github.com/thatstoasty/mog")),
    )
    return join_horizontal(Position.TOP, title, description)


fn build_dialog_box() -> String:
    var dialog_box_style = mog.Style().alignment(Position.CENTER).border(ROUNDED_BORDER).border_foreground(
        mog.Color(0xFF713C)
    ).padding(1, 0)

    var button_style = mog.Style().foreground(mog.Color(0xFFF7DB)).background(mog.Color(0x888B7E)).padding(
        0, 3
    ).margin_top(1)

    var active_button_style = button_style.foreground(mog.Color(0xFFF7DB)).background(mog.Color(0xF25D94)).margin_right(
        2
    ).underline()

    var ok_button = active_button_style.render("Yes")
    var cancel_button = button_style.render("No")

    var question = mog.Style().width(50).alignment(Position.CENTER).render("Are you sure you want to deploy?")

    var buttons = join_horizontal(Position.TOP, ok_button, cancel_button)
    var ui = join_vertical(Position.CENTER, question, buttons)

    return WhitespaceRenderer(style=mog.Style().foreground(subtle), chars="⣾⣽⣻⢿⡿⣟⣯⣷").place(
        width,
        9,
        Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        dialog_box_style.render(ui),
    )


fn build_lists() -> String:
    var list_style = mog.Style().border(NORMAL_BORDER, False, True, False, False).border_foreground(
        subtle
    ).margin_right(2).height(8).width(column_width + 1)

    var list_header = mog.Style().border(NORMAL_BORDER, False, False, True, False).border_foreground(
        subtle
    ).margin_right(2)

    var list_item = mog.Style().padding_left(2)
    var check_mark = mog.Style().foreground(special).padding_right(1).render("✔")
    var list_done = mog.Style().strikethrough().foreground(mog.AdaptiveColor(light=0x969B86, dark=0x696969))

    var colors = color_grid(14, 8)
    var color_style = mog.Style(value="  ")
    var builder = String()

    for i in range(len(colors)):
        for j in range(len(colors[i])):
            builder.write(color_style.background(mog.Color(colors[i][j].hex())).render())
        builder.write("\n")

    var lists = join_horizontal(
        Position.TOP,
        list_style.render(
            join_vertical(
                Position.LEFT,
                list_header.render("Citrus Fruits to Try"),
                check_mark + list_done.render("Grapefruit"),
                check_mark + list_done.render("Yuzu"),
                list_item.render("Citron"),
                list_item.render("Kumquat"),
                list_item.render("Pomelo"),
            ),
        ),
        list_style.width(column_width - 1).render(
            join_vertical(
                Position.LEFT,
                list_header.render("Programming Languages"),
                list_item.render("Mojo"),
                list_item.render("Rust"),
                check_mark + list_done.render("Python"),
                list_item.render("Gleam"),
                check_mark + list_done.render("Go"),
            ),
        ),
    )

    return join_horizontal(Position.TOP, lists, builder)


fn build_history() -> String:
    var history_style = mog.Style().height(20).width(column_width).padding(1, 2).margin(1, 3, 0, 0).alignment(
        Position.LEFT
    ).foreground(mog.Color(0xFFFDF5)).background(highlight)

    alias history_a = "The Romans learned from the Greeks that quinces slowly cooked with honey would 'set' when cool. The Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum: Roman marmalade. Preserves of quince and lemon appear (along with rose, apple, plum and pear) in the Book of ceremonies of the Byzantine Emperor Constantine VII Porphyrogennetos."
    alias history_b = "Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac."
    alias history_c = "In 1524, Henry VIII, King of England, received a 'box of marmalade' from Mr. Hull of Exeter. This was probably marmelada, a solid quince paste from Portugal, still made and sold in southern Europe today. It became a favourite treat of Anne Boleyn and her ladies in waiting."

    return join_horizontal(
        Position.TOP,
        history_style.alignment(Position.RIGHT).render(history_a),
        history_style.alignment(Position.CENTER).render(history_b),
        history_style.margin_right(0).render(history_c),
    )


fn build_status_bar() -> String:
    var status_nugget_style = mog.Style().foreground(mog.Color(0xFFFDF5)).padding(0, 1)
    var status_bar_style = mog.Style().foreground(mog.Color(0xC1C6B2)).background(mog.Color(0x353533))
    var status_style = mog.Style().foreground(mog.Color(0xFFFDF5)).background(mog.Color(0xFF5F87)).padding(0, 1)

    var encoding_style = status_nugget_style.background(mog.Color(0xA550DF)).horizontal_alignment(Position.RIGHT)
    var status_text_style = status_bar_style.padding_left(1)
    var fish_cake_style = status_nugget_style.background(mog.Color(0x6124DF))

    var status_key = status_style.render("STATUS")
    var encoding = encoding_style.render("UTF-8")
    var fish_cake = fish_cake_style.render("🍥 Fish Cake")
    var status_val = status_text_style.width(
        width - get_width(status_key) - get_width(encoding) - get_width(fish_cake)
    ).render("Ravishing")

    var bar = join_horizontal(
        Position.TOP,
        status_key,
        status_val,
        encoding,
        fish_cake,
    )

    return status_bar_style.width(width).render(bar)


fn main():
    # The page style
    var builder = String(capacity=4096)
    var doc_style = mog.Style().padding(1, 2, 1, 2)

    # Tabs.
    builder.write(build_tabs())
    builder.write("\n\n")

    # Title
    builder.write(build_description())
    builder.write("\n\n")

    # Dialog box
    builder.write(build_dialog_box())
    builder.write("\n\n")

    # List
    builder.write(build_lists())
    builder.write("\n")

    # History
    builder.write(build_history())
    builder.write("\n\n")

    # Status bar
    builder.write(build_status_bar())

    # Render the final document with doc_style
    print(doc_style.render(builder))
