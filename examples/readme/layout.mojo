from external.gojo.strings import StringBuilder
from external.weave.ansi import printable_rune_width
from mog.join import join_vertical, join_horizontal
from mog.border import hidden_border, normal_border, rounded_border, Border
from mog.style import Style
from mog.size import get_width
from mog import position
from mog.whitespace import (
    place,
    with_whitespace_chars,
    with_whitespace_foreground,
)
import mog


alias width = 96
alias column_width = 30
alias subtle = mog.AdaptiveColor(light="#D9DCCF", dark="#383838")
alias highlight = mog.AdaptiveColor(light="#874BFD", dark="#7D56F4")
alias special = mog.AdaptiveColor(light="#43BF6D", dark="#73F59F")


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

    var tab_style = mog.new_style().border(tab_border).border_foreground(highlight).padding(0, 1)

    var active_tab = tab_style.copy().border(active_tab_border, True)

    var tab_gap = tab_style.copy().border_top(False).border_left(False).border_right(False)

    var row = join_horizontal(
        position.top,
        active_tab.render("Mog"),
        tab_style.render("Gojo"),
        tab_style.render("Lightbug"),
        tab_style.render("Basalt"),
        tab_style.render("Prism"),
    )
    var gap = tab_gap.render(String(" ") * max(0, width - get_width(row) - 2))
    return join_horizontal(position.bottom, row, gap)


fn build_description() -> String:
    var divider = mog.new_style().padding(0, 1).foreground(subtle).render("•")

    var url = mog.new_style().foreground(special)
    var desc_style = mog.new_style().margin_top(1)
    var info_style = mog.new_style().border(normal_border(), True, False, False, False).border_foreground(subtle)

    return join_vertical(
        position.left,
        desc_style.render("Style Definitions for Nice Terminal Layouts.\nInspired by charmbracelet/lipgloss"),
        info_style.render("From Mikhail" + divider + url.render("https://github.com/thatstoasty/mog")),
    )


fn build_dialog_box() -> String:
    var dialog_box_style = mog.new_style().alignment(position.center).border(rounded_border()).border_foreground(
        mog.Color("#874BFD")
    ).padding(1, 0)

    var button_style = mog.new_style().foreground(mog.Color("#FFF7DB")).background(mog.Color("#888B7E")).padding(
        0, 3
    ).margin_top(1)

    var active_button_style = button_style.copy().foreground(mog.Color("#FFF7DB")).background(
        mog.Color("#F25D94")
    ).margin_right(2).underline()

    var ok_button = active_button_style.render("Yes")
    var cancel_button = button_style.render("Maybe")

    var question = mog.new_style().width(50).alignment(position.center).render(
        "Are you sure you want to eat marmalade?"
    )

    var buttons = join_horizontal(position.top, ok_button, cancel_button)
    var ui = join_vertical(position.center, question, buttons)

    # TODO: Cannot handle unicode characters with a length greater than 1. For example: east asian characters like Kanji.
    return place(
        width,
        9,
        position.center,
        position.center,
        dialog_box_style.render(ui),
        with_whitespace_chars["⣾⣽⣻⢿⡿⣟⣯⣷"](),
        with_whitespace_foreground[subtle](),
    )


fn build_lists() -> String:
    var list_style = mog.new_style().border(normal_border(), False, True, False, False).border_foreground(
        subtle
    ).margin_right(2).height(8).width(column_width + 1)

    var list_header = mog.new_style().border(normal_border(), False, False, True, False).border_foreground(
        subtle
    ).margin_right(2)

    var list_item = mog.new_style().padding_left(2)

    var check_mark = mog.new_style().foreground(special).padding_right(1).render("✔")

    var list_done = mog.new_style().crossout().foreground(mog.AdaptiveColor(light="#969B86", dark="#696969"))

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
        .width(column_width)
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
        .width(column_width - 1)
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

    return join_horizontal(position.top, lists)


fn build_history() -> String:
    var history_style = mog.new_style().height(20).width(column_width).padding(1, 2).margin(1, 3, 0, 0).alignment(
        position.left
    ).foreground(mog.Color("#FFFDF5")).background(highlight)

    alias history_a = "The Romans learned from the Greeks that quinces slowly cooked with honey would “set” when cool. The Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum: Roman marmalade. Preserves of quince and lemon appear (along with rose, apple, plum and pear) in the Book of ceremonies of the Byzantine Emperor Constantine VII Porphyrogennetos."
    alias history_b = "Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac."
    alias history_c = "In 1524, Henry VIII, King of England, received a “box of marmalade” from Mr. Hull of Exeter. This was probably marmelada, a solid quince paste from Portugal, still made and sold in southern Europe today. It became a favourite treat of Anne Boleyn and her ladies in waiting."

    return join_horizontal(
        position.top,
        history_style.copy().alignment(position.right).render(history_a),
        history_style.copy().alignment(position.center).render(history_b),
        history_style.copy().margin_right(0).render(history_c),
    )


fn build_status_bar() -> String:
    var status_nugget_style = mog.new_style().foreground(mog.Color("#FFFDF5")).padding(0, 1)

    var status_bar_style = mog.new_style().foreground(mog.Color("#C1C6B2")).background(mog.Color("#353533"))

    var status_style = mog.new_style().foreground(mog.Color("#FFFDF5")).background(mog.Color("#FF5F87")).padding(0, 1)
    # .margin_right(1)

    var encoding_style = status_nugget_style.copy().background(mog.Color("#A550DF")).horizontal_alignment(
        position.right
    )

    var status_text_style = status_bar_style.copy().padding_left(1)
    var fish_cake_style = status_nugget_style.copy().background(mog.Color("#6124DF"))

    var status_key = status_style.render("STATUS")
    var encoding = encoding_style.render("UTF-8")
    var fish_cake = fish_cake_style.render("Fish Cake")
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

    return status_bar_style.width(width).render(bar)


fn main():
    # The page style
    var builder = StringBuilder()
    var doc_style = mog.new_style().padding(1, 2, 1, 2).border(rounded_border()).border_foreground(subtle)

    # Tabs.
    _ = builder.write_string(build_tabs())
    _ = builder.write_string("\n\n")

    # Title
    _ = builder.write_string(build_description())
    _ = builder.write_string("\n\n")

    # Dialog box
    _ = builder.write_string(build_dialog_box())
    _ = builder.write_string("\n\n")

    # List
    _ = builder.write_string(build_lists())
    _ = builder.write_string("\n")

    # History
    _ = builder.write_string(build_history())
    _ = builder.write_string("\n\n")

    # Status bar
    _ = builder.write_string(build_status_bar())

    # Render the final document with doc_style
    print(doc_style.render(builder.render()))
