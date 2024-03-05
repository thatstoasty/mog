# from mog.style import Style
# import mog.position
from mog.join import join_vertical, join_horizontal
from mog.table import new_table, new_string_data, Table
from mog.table.table import default_styles
from mog.border import star_border, ascii_border, Border
from mog.style import Style
from mog import position
from time import now


fn test_style_func(row: Int, col: Int) raises -> Style:
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
    var border_style = Style()
    border_style.foreground("#39E506")

    var table = Table(
        style_function=default_styles,
        border=ascii_border(),
        border_style=border_style,
        border_bottom=True,
        border_column=True,
        border_header=True,
        border_left=True,
        border_right=True,
        border_top=True,
        data=new_string_data(),
        width=50
    )
    # table.border(border)
    table.style_function = test_style_func
    table.row("French", "Bonjour", "Salut")
    table.row("Russian", "Zdravstvuyte", "Privet")
    # for i in range(table.data.rows()):
    #     for j in range(table.data.columns()):
    #         print(table.data.at(i, j))
    # print(table.data.columns())

    var headerless_start_time = now()
    print(table.render())
    var headerless_execution_time = now() - headerless_start_time

    table.set_headers("LANGUAGE", "FORMAL", "INFORMAL")
    var headered_start_time = now()
    print(table.render())
    var headered_execution_time = now() - headerless_start_time

    print("Headerless Execution Time: ", headerless_execution_time, headerless_execution_time / 1e9)
    print("Headered Execution Time: ", headered_execution_time, headered_execution_time / 1e9)
    # var t = DynamicVector[String]()
    # t.append("Hello")
    # t.append("World")
    # let a: String = "Hello World!\nThis is an example."
    # let b: String = "I could be more creative.\nBut, I'm out of ideas."

    # print(join_vertical(position.center, a, b))
    # print(join_horizontal(position.bottom, a, b))


fn test_styling() raises:
    var border_style = Style()
    border_style.foreground("#39E506")

    var style = Style()
    style.bold()
    style.width(50)
    style.padding_top(1)
    style.padding_right(1)
    style.padding_bottom(1)
    style.padding_left(1)

    style.horizontal_alignment(position.center)
    style.border("ascii_border")
    style.foreground("#c9a0dc")

    var start_time = now()
    print(style.render("Hello World!\nThis is a test of the mog style system. Which can wrap lines that are longer than the limit.\n\nYep."))
    var execution_time = now() - start_time
    print("Headered Execution Time: ", execution_time, execution_time / 1e9)


fn main() raises:
    test_styling()
    test_table()