from mog.join import join_vertical, join_horizontal
from mog.table import new_table, Table, StringData
from mog.table.table import default_styles
from mog.border import (
    STAR_BORDER,
    ASCII_BORDER,
    Border,
    ROUNDED_BORDER,
    HIDDEN_BORDER,
)
from mog.style import Style
from mog import position
import mog
from time import now


fn dummy_style_func(row: Int, col: Int) -> Style:
    var style = mog.Style().horizontal_alignment(position.center).vertical_alignment(position.center).padding(0, 1)
    if row == 0:
        style = style.foreground(mog.Color(0xC9A0DC))
        return style
    elif row % 2 == 0:
        style = style.foreground(mog.Color(0xE58006))
        return style
    else:
        return style


def test_table():
    var border_style = mog.Style().foreground(mog.Color(0x39E506))

    var table = Table(
        style_function=default_styles,
        border=ROUNDED_BORDER,
        border_style=border_style,
        border_bottom=True,
        border_column=True,
        border_header=True,
        border_left=True,
        border_right=True,
        border_top=True,
        data=StringData(),
        width=50,
    )
    table.style_function = dummy_style_func
    table = table.row("French", "Bonjour", "Salut").row("Russian", "Zdravstvuyte", "Privet")

    var headerless_start_time = now()
    print(table.render())
    var headerless_execution_time = now() - headerless_start_time

    table = table.set_headers("LANGUAGE", "FORMAL", "INFORMAL")
    var headered_start_time = now()
    print(table.render())
    var headered_execution_time = now() - headerless_start_time

    print(
        "Headerless Execution Time: ",
        headerless_execution_time,
        headerless_execution_time / 1e9,
    )
    print(
        "Headered Execution Time: ",
        headered_execution_time,
        headered_execution_time / 1e9,
    )


def test_horizontal_joined_paragraphs():
    var style_build_start = now()
    var style = mog.Style().bold().width(50).padding(1, 1, 1, 1).horizontal_alignment(position.center).border(
        ROUNDED_BORDER
    ).foreground(mog.Color(0xC9A0DC)).border_foreground(mog.Color(0x39E506))
    var style_build_duration = now() - style_build_start
    print("Style build duration: ", style_build_duration, style_build_duration / 1e9)
    var start_time = now()

    print(style.render("You should be able to join blocks of different heights"))
    print(
        join_horizontal(
            position.top,
            style.render("You should be able to join blocks of different heights"),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
    print(
        join_horizontal(
            position.bottom,
            style.render("You should be able to join blocks of different heights"),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
    print(
        join_horizontal(
            position.center,
            style.render("You should be able to join blocks of different heights"),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
    var execution_time = now() - start_time
    print("Block execution time: ", execution_time, execution_time / 1e9)


def test_borderless_paragraph():
    var borderless_style = mog.Style().width(50).padding(1, 2).horizontal_alignment(position.center).border(
        HIDDEN_BORDER
    ).background(mog.Color(0xC9A0DC))

    print(
        join_horizontal(
            position.center,
            borderless_style.render("You should be able to join blocks of different heights"),
            borderless_style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            borderless_style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
