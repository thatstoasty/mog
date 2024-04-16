from tests.wrapper import MojoTest
from mog.join import join_vertical, join_horizontal
from mog.table import new_table, new_string_data, Table
from mog.table.table import default_styles
from mog.border import (
    star_border,
    ascii_border,
    Border,
    rounded_border,
    hidden_border,
)
from mog.style import Style
from mog import position
import mog
from time import now


fn dummy_style_func(row: Int, col: Int) raises -> Style:
    var style = Style.new().horizontal_alignment(position.center).vertical_alignment(position.center).padding(0, 1)
    if row == 0:
        style = style.foreground(mog.Color("#c9a0dc"))
        return style
    elif row % 2 == 0:
        style = style.foreground(mog.Color("#e58006"))
        return style
    else:
        return style


fn test_table() raises:
    var test = MojoTest("Testing table creation with and without headers")
    var border_style = Style.new().foreground(mog.Color("#39E506"))

    var table = Table(
        style_function=default_styles,
        border=rounded_border(),
        border_style=border_style,
        border_bottom=True,
        border_column=True,
        border_header=True,
        border_left=True,
        border_right=True,
        border_top=True,
        data=new_string_data(),
        width=50,
    )
    table.style_function = dummy_style_func
    table.row("French", "Bonjour", "Salut")
    table.row("Russian", "Zdravstvuyte", "Privet")

    var headerless_start_time = now()
    print(table.render())
    var headerless_execution_time = now() - headerless_start_time

    table.set_headers("LANGUAGE", "FORMAL", "INFORMAL")
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


fn test_horizontal_joined_paragraphs() raises:
    var test = MojoTest("Testing Style rendering")
    var style = Style.new().bold().width(50).padding(1, 1, 1, 1).horizontal_alignment(position.center).border(
        rounded_border()
    ).foreground(mog.Color("#c9a0dc")).border_foreground(mog.Color("#39E506"))
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
    print("Headered Execution Time: ", execution_time, execution_time / 1e9)


fn test_borderless_paragraph() raises:
    var borderless_style = Style.new().width(50).padding(1, 2).horizontal_alignment(position.center).border(
        hidden_border()
    ).background(mog.Color("#c9a0dc"))

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


fn main() raises:
    test_horizontal_joined_paragraphs()
    test_borderless_paragraph()
    test_table()
