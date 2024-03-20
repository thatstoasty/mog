from tests.wrapper import MojoTest
from mog.join import join_vertical, join_horizontal
from mog.table import new_table, new_string_data, Table
from mog.table.table import default_styles
from mog.border import star_border, ascii_border, Border, rounded_border
from mog.style import Style
from mog import position
from time import now


fn dummy_style_func(row: Int, col: Int) raises -> Style:
    var style = Style()
    style.horizontal_alignment(position.center)
    style.vertical_alignment(position.center)
    # style.padding(0, 1)
    if row == 0:
        style.foreground("#c9a0dc")
        return style
    elif row % 2 == 0:
        style.foreground("#e58006")
        return style
    else:
        return style


fn test_table() raises:
    var test = MojoTest("Testing table creation with and without headers")
    var border_style = Style()
    border_style.foreground("#39E506")

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


fn test_styling() raises:
    var test = MojoTest("Testing Style rendering")
    var style = Style()
    style.bold()
    style.width(50)
    style.padding_top(1)
    style.padding_right(1)
    style.padding_bottom(1)
    style.padding_left(1)

    style.horizontal_alignment(position.center)
    style.border("rounded_border")
    style.foreground("#c9a0dc")
    style.border_foreground("#39E506")

    var start_time = now()

    # TODO: Joining blocks of different height does not work
    print(style.render("You should be able to join blocks of different heights"))
    print(
        join_horizontal(
            position.center,
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which can wrap lines"
                " that are longer than the limit.\n\nYep."
            ),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which can wrap lines"
                " that are longer than the limit.\n\nYep."
            ),
        )
    )
    var execution_time = now() - start_time
    print("Headered Execution Time: ", execution_time, execution_time / 1e9)


fn main() raises:
    test_styling()
    test_table()
