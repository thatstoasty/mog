from mog import Style, Border, Table, center, default_styles, new_string_data


fn dummy_style_func(row: Int, col: Int) raises -> Style:
    var style = Style.new().horizontal_alignment(center).vertical_alignment(
        center
    ).padding(0, 1)
    if row == 0:
        style = style.foreground(mog.Color("#c9a0dc"))
        return style
    elif row % 2 == 0:
        style = style.foreground(mog.Color("#e58006"))
        return style
    else:
        return style


fn main() raises:
    var border_style = Style().foreground(mog.Color("#39E506"))
    var fire_border = Border(
        top="🔥",
        bottom="🔥",
        left="🔥",
        right="🔥",
        top_left="🔥",
        top_right="🔥",
        bottom_left="🔥",
        bottom_right="🔥",
        middle_left="🔥",
        middle_right="🔥",
        middle="🔥",
        middle_top="🔥",
    )

    var table = Table(
        style_function=default_styles,
        border=fire_border,
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

    print(table.render())

    table.set_headers("LANGUAGE", "FORMAL", "INFORMAL")
    print(table.render())
