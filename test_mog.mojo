# from mog.style import Style
# import mog.position
from mog.join import join_vertical, join_horizontal
from mog.table import new_table, new_string_data
from mog.border import ascii_border, Border
from mog.style import Style
from mog import position


fn test_style_func(row: Int, col: Int) raises -> Style:
    var style = Style()
    # style.padding(0, 1)
    if row == 0:
        style.horizontal_alignment(position.center)
        style.vertical_alignment(position.center)
        return style
    elif row % 2 == 0:
        return style
    else:
        return style


fn main() raises:
    var table = new_table()
    var border = ascii_border()
    # table.border(border)
    # table.style_function(test_style_func)
    table.row("French", "Bonjour", "Salut")
    table.row("Russian", "Zdravstvuyte", "Privet")
    # for i in range(table.data.rows()):
    #     for j in range(table.data.columns()):
    #         print(table.data.at(i, j))
    # print(table.data.columns())
    print(table.render())
    table.set_headers("LANGUAGE", "FORMAL", "INFORMAL")
    print(table.render())
    
    # var t = DynamicVector[String]()
    # t.append("Hello")
    # t.append("World")
    # let a: String = "Hello World!\nThis is an example."
    # let b: String = "I could be more creative.\nBut, I'm out of ideas."

    # print(join_vertical(position.center, a, b))
    # print(join_horizontal(position.bottom, a, b))


# fn main() raises:
#     var style = Style()
#     style.bold()
#     style.width(50)
#     style.padding_top(1)
#     style.padding_right(1)
#     style.padding_bottom(1)
#     style.padding_left(1)

#     style.horizontal_alignment(position.center)
#     style.border("ascii_border")
#     style.foreground("#c9a0dc")
#     # style.background("#2d2d2d")
#     print(style.render("Hello World!\nThis is a test of the stormlight style system. Which can wrap lines that are longer than the limit.\n\nYep."))