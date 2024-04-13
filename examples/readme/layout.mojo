from math import max
from external.gojo.strings import StringBuilder
from external.weave.ansi import printable_rune_width
from mog.join import join_vertical, join_horizontal
from mog.border import hidden_border, normal_border, rounded_border, Border
from mog.style import Style
from mog.extensions import repeat
from mog.size import get_width
from mog import position
from mog.whitespace import place, with_whitespace_chars, with_whitespace_foreground
import mog


fn main() raises:
    # The page style
    var builder = StringBuilder()
    var doc_style = Style.new().padding(1, 2, 1, 2).border(rounded_border()).width(
        106
    ).border_foreground(mog.Color("#383838"))
    alias width = 96
    alias column_width = 30
    alias subtle = mog.AdaptiveColor(light="#D9DCCF", dark="#383838")
    alias highlight = mog.AdaptiveColor(light="#874BFD", dark="#7D56F4")
    alias special = mog.AdaptiveColor(light="#43BF6D", dark="#73F59F")

    # Tabs.
    var active_tab_border = Border(
        top="─",
        bottom=" ",
        left="│",
        right="│",
        top_left="╭",
        top_right="╮",
        bottom_left="┘",
        bottom_right="└",
    )

    var tab_border = Border(
        top="─",
        bottom="─",
        left="│",
        right="│",
        top_left="╭",
        top_right="╮",
        bottom_left="┴",
        bottom_right="┴",
    )

    var tab_style = Style.new().border(tab_border).border_foreground(
        mog.Color("#7D56F4")
    ).padding(0, 1)

    var active_tab = tab_style.copy().border(active_tab_border, True)

    var tab_gap = tab_style.copy().border_top(False).border_left(False).border_right(
        False
    )

    var row = join_horizontal(
        position.top,
        active_tab.render("Mog"),
        tab_style.render("Gojo"),
        tab_style.render("Lightbug"),
        tab_style.render("Basalt"),
        tab_style.render("Prism"),
    )
    var gap = tab_gap.render(repeat(" ", max(0, width - get_width(row) - 2)))
    _ = builder.write_string(join_horizontal(position.bottom, row, gap))
    _ = builder.write_string("\n\n")

    # Title
    var divider = Style.new().padding(0, 1).foreground(subtle).render("•")

    var url = Style.new().foreground(special)
    var desc_style = Style.new().margin_top(1)
    var info_style = Style.new().border(
        normal_border(), True, False, False, False
    ).border_foreground(subtle)

    var desc = join_vertical(
        position.left,
        desc_style.render(
            "Style Definitions for Nice Terminal Layouts.\nInspired by"
            " charmbracelet/lipgloss"
        ),
        info_style.render(
            "From Mikhail" + divider + url.render("https://github.com/thatstoasty/mog")
        ),
    )
    _ = builder.write_string(desc + "\n\n")

    # Dialog box
    # TODO: Temporarily the full length of the doc until the renderer funcs are added
    var dialog_box_style = Style.new().alignment(position.center).border(
        rounded_border()
    ).border_foreground(mog.Color("#874BFD")).padding(1, 0)

    var button_style = Style.new().foreground(mog.Color("#FFF7DB")).background(
        mog.Color("#888B7E")
    ).padding(0, 3).margin_top(1)

    var active_button_style = button_style.copy().foreground(
        mog.Color("#FFF7DB")
    ).background(mog.Color("#F25D94")).margin_right(2).underline()

    var ok_button = active_button_style.render("Yes")
    var cancel_button = button_style.render("Maybe")

    var question = Style.new().width(50).alignment(position.center).render(
        "Are you sure you want to eat marmalade?"
    )
    var buttons = join_horizontal(position.top, ok_button, cancel_button)
    var ui = join_vertical(position.center, question, buttons)

    var dialog = place(width,
        9,
        position.center,
        position.center,
        dialog_box_style.render(ui),
        with_whitespace_chars["猫咪"](),
        with_whitespace_foreground[subtle](),
    )

    _ = builder.write_string(dialog + "\n\n")

    # List
    var list_style = Style.new().border(
        normal_border(), False, True, False, False
    ).border_foreground(mog.Color("#383838")).margin_right(2).height(8).width(
        column_width + 3
    )

    var list_header = Style.new().border(
        normal_border(), False, False, True, False
    ).border_foreground(mog.Color("#383838")).margin_right(2)

    var list_item = Style.new().padding_left(2)

    var check_mark = Style.new().foreground(mog.Color("#73F59F")).padding_right(
        1
    ).render("✔")

    var list_done = Style.new().crossout().foreground(mog.Color("#696969"))

    var lists = join_horizontal(
        position.top,
        list_style.render(
            join_vertical(
                position.left,
                list_header.render("Citrus Fruits to Try"),
                check_mark + list_done.render("Grapefruit"),
                check_mark + list_done.render("Yuzu"),
                list_item.render("Citron"),
                list_item.render("Kumquat"),
                list_item.render("Pomelo"),
            ),
        ),
        list_style.copy()
        .width(column_width + 2)
        .render(
            join_vertical(
                position.left,
                list_header.render("Actual Lip Gloss Vendors"),
                list_item.render("Glossier"),
                list_item.render("Claire's Boutique"),
                check_mark + list_done.render("Nyx"),
                list_item.render("Mac"),
                check_mark + list_done.render("Milk"),
            ),
        ),
        list_style.copy()
        .width(column_width)
        .render(
            join_vertical(
                position.left,
                list_header.render("Programming Languages"),
                list_item.render("Mojo"),
                list_item.render("Rust"),
                check_mark + list_done.render("Python"),
                list_item.render("Gleam"),
                check_mark + list_done.render("Go"),
            ),
        ),
    )

    _ = builder.write_string(join_horizontal(position.top, lists))
    _ = builder.write_string("\n")

    # History
    var history_style = Style.new().height(20).width(column_width).padding(1, 2).margin(
        1, 3, 0, 0
    ).alignment(position.left).border(hidden_border()).background(mog.Color("#9846eb"))

    alias history_a = "The Romans learned from the Greeks that quinces slowly cooked with honey would “set” when cool. The Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum: Roman marmalade. Preserves of quince and lemon appear (along with rose, apple, plum and pear) in the Book of ceremonies of the Byzantine Emperor Constantine VII Porphyrogennetos."
    alias history_b = "Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac."
    alias history_c = "In 1524, Henry VIII, King of England, received a “box of marmalade” from Mr. Hull of Exeter. This was probably marmelada, a solid quince paste from Portugal, still made and sold in southern Europe today. It became a favourite treat of Anne Boleyn and her ladies in waiting."

    _ = builder.write_string(
        join_horizontal(
            position.top,
            history_style.copy().alignment(position.right).render(history_a),
            history_style.copy().alignment(position.center).render(history_b),
            history_style.copy().margin_right(0).render(history_c),
        )
    )
    _ = builder.write_string("\n\n")

    # Status bar
    var status_nugget_style = Style.new().foreground(mog.Color("#FFFDF5")).padding(0, 1)

    var status_bar_style = Style.new().foreground(mog.Color("#C1C6B2")).background(
        mog.Color("#353533")
    ).width(width)

    var status_style = Style.new().foreground(mog.Color("#FFFDF5")).background(
        mog.Color("#FF5F87")
    ).padding(0, 1)
    # .margin_right(1)

    var encoding_style = status_nugget_style.copy().background(
        mog.Color("#A550DF")
    ).horizontal_alignment(position.right)

    var status_text_style = status_bar_style.copy().padding_left(1)
    var fish_cake_style = status_nugget_style.copy().background(mog.Color("#6124DF"))

    var status_key = status_style.render("STATUS")
    var encoding = encoding_style.render("UTF-8")
    var fish_cake = fish_cake_style.render("🍥 Fish Cake")
    var status_val = status_text_style.copy().width(
        width - get_width(status_key) - get_width(encoding) - get_width(fish_cake)
    ).render("Ravishing")

    var bar = join_horizontal(
        position.top,
        status_key,
        status_val,
        encoding,
        fish_cake,
    )

    _ = builder.write_string(status_bar_style.width(width).render(bar))

    # Render the final document with doc_style
    print(doc_style.render(str(builder)))
