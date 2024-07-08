import mog


fn main():
    var type_colors = Dict[String, mog.Color]()
    type_colors["Bug"] = mog.Color(0xD7FF87)
    type_colors["Electric"] = mog.Color(0xFDFF90)
    type_colors["Fire"] = mog.Color(0xFF7698)
    type_colors["Flying"] = mog.Color(0xFF87D7)
    type_colors["Grass"] = mog.Color(0x75FBAB)
    type_colors["Ground"] = mog.Color(0xFF875F)
    type_colors["Normal"] = mog.Color(0x929292)
    type_colors["Poison"] = mog.Color(0x7D5AFC)
    type_colors["Water"] = mog.Color(0x00E2C7)

    var dim_type_colors = Dict[String, mog.Color]()
    dim_type_colors["Bug"] = mog.Color(0x97AD64)
    dim_type_colors["Electric"] = mog.Color(0xFCFF5F)
    dim_type_colors["Fire"] = mog.Color(0xBA5F75)
    dim_type_colors["Flying"] = mog.Color(0xC97AB2)
    dim_type_colors["Grass"] = mog.Color(0x59B980)
    dim_type_colors["Ground"] = mog.Color(0xC77252)
    dim_type_colors["Normal"] = mog.Color(0x727272)
    dim_type_colors["Poison"] = mog.Color(0x634BD0)
    dim_type_colors["Water"] = mog.Color(0x439F8E)

    var headers = List[String]("#", "Name", "Type 1", "Type 2", "Official Rom.")
    var data = List[List[String]](
        List[String]("1", "Bulbasaur", "Grass", "Poison", "Bulbasaur"),
        List[String]("2", "Ivysaur", "Grass", "Poison", "Ivysaur"),
        List[String]("3", "Venusaur", "Grass", "Poison", "Venusaur"),
        List[String]("4", "Charmander", "Fire", "", "Hitokage"),
        List[String]("5", "Charmeleon", "Fire", "", "Lizardo"),
    )

    var style = mog.Style().padding(1)
    var header_style = style.foreground(mog.Color(252)).bold()
    var selected_style = style.foreground(mog.Color(0x01BE85)).background(mog.Color(0x00432F))

    fn capitalize_headers(data: List[String]) -> List[String]:
        var upper = List[String]()
        for element in data:
            upper.append(element[].upper())

        return upper

    fn style_func(row: Int, col: Int) -> mog.Style:
        if row == 0:
            return header_style

        if data[row - 1][1] == "Pikachu":
            return selected_style

        var is_even = (row % 2 == 0)
        if col == 2 or col == 3:
            var colors = type_colors
            if is_even:
                colors = dim_type_colors

            var color = colors.get(data[row - 1][col], mog.Color(0xFFFFFF))
            return style.foreground(color)

        if is_even:
            return style.foreground(mog.Color(245))

        return style.foreground(mog.Color(252))

    var table = mog.Table(
        width=100,
        border=mog.ROUNDED_BORDER,
        border_style=mog.Style().foreground(mog.Color(238)),
        headers=capitalize_headers(headers),
        style_function=style_func,
    )
    table = table.rows(data)
    print(table.render())
