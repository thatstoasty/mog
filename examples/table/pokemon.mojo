from external.string_dict import Dict
from mog.border import rounded_border
import mog
import mog.table


fn make_row(*strs: String) -> List[String]:
    var row = List[String](capacity=len(strs))
    for s in strs:
        row.append(s[])
    return row


fn capitalize_headers(inout data: List[String]) -> List[String]:
    for element in data:
        element[] = element[].upper()

    return data


fn style_func(row: Int, col: Int) raises -> mog.Style:
    var style = mog.Style()
    style.padding_top(1)
    style.padding_right(1)
    style.padding_bottom(1)
    style.padding_left(1)

    var header_style = style.copy()
    header_style.foreground("252")
    header_style.bold()
    var selected_style = style.copy()
    selected_style.foreground("#01BE85")
    selected_style.background("#00432F")

    var data = List[List[String]]()
    data.append(make_row("1", "Bulbasaur", "Grass", "Poison", "Bulbasaur"))
    data.append(make_row("2", "Ivysaur", "Grass", "Poison", "Ivysaur"))
    data.append(make_row("3", "Venusaur", "Grass", "Poison", "Venusaur"))
    data.append(make_row("4", "Charmander", "Fire", "", "Hitokage"))
    data.append(make_row("5", "Charmeleon", "Fire", "", "Lizardo"))

    var type_colors = Dict[String]()
    type_colors.put("Bug", "#D7FF87")
    type_colors.put("Electric", "#FDFF90")
    type_colors.put("Fire", "#FF7698")
    type_colors.put("Flying", "#FF87D7")
    type_colors.put("Grass", "#75FBAB")
    type_colors.put("Ground", "#FF875F")
    type_colors.put("Normal", "#929292")
    type_colors.put("Poison", "#7D5AFC")
    type_colors.put("Water", "#00E2C7")

    var dim_type_colors = Dict[String]()
    dim_type_colors.put("Bug", "#97AD64")
    dim_type_colors.put("Electric", "#FCFF5F")
    dim_type_colors.put("Fire", "#BA5F75")
    dim_type_colors.put("Flying", "#C97AB2")
    dim_type_colors.put("Grass", "#59B980")
    dim_type_colors.put("Ground", "#C77252")
    dim_type_colors.put("Normal", "#727272")
    dim_type_colors.put("Poison", "#634BD0")
    dim_type_colors.put("Water", "#439F8E")

    if row == 0:
        return header_style

    if data[row - 1][1] == "Pikachu":
        return selected_style

    var is_even = (row % 2 == 0)
    if col == 2 or col == 3:
        var colors = type_colors
        if is_even:
            colors = dim_type_colors

        var color = colors.get(data[row - 1][col], "#FFFFFF")
        var copy_style = style.copy()
        copy_style.foreground(color)
        return copy_style

    if is_even:
        var copy_style = style.copy()
        copy_style.foreground("245")
        return copy_style

    var copy_style = style.copy()
    copy_style.foreground("252")
    return copy_style


fn main() raises:
    var style = mog.Style()
    style.padding_top(1)
    style.padding_right(1)
    style.padding_bottom(1)
    style.padding_left(1)

    var header_style = style.copy()
    header_style.foreground("252")
    header_style.bold()
    var selected_style = style.copy()
    selected_style.foreground("#01BE85")
    selected_style.background("#00432F")

    var type_colors = Dict[String]()
    type_colors.put("Bug", "#D7FF87")
    type_colors.put("Electric", "#FDFF90")
    type_colors.put("Fire", "#FF7698")
    type_colors.put("Flying", "#FF87D7")
    type_colors.put("Grass", "#75FBAB")
    type_colors.put("Ground", "#FF875F")
    type_colors.put("Normal", "#929292")
    type_colors.put("Poison", "#7D5AFC")
    type_colors.put("Water", "#00E2C7")

    var dim_type_colors = Dict[String]()
    dim_type_colors.put("Bug", "#97AD64")
    dim_type_colors.put("Electric", "#FCFF5F")
    dim_type_colors.put("Fire", "#BA5F75")
    dim_type_colors.put("Flying", "#C97AB2")
    dim_type_colors.put("Grass", "#59B980")
    dim_type_colors.put("Ground", "#C77252")
    dim_type_colors.put("Normal", "#727272")
    dim_type_colors.put("Poison", "#634BD0")
    dim_type_colors.put("Water", "#439F8E")

    var headers = List[String]()
    headers.append("#")
    headers.append("Name")
    headers.append("Type 1")
    headers.append("Type 2")
    headers.append("Official Rom.")

    var data = List[List[String]]()
    data.append(make_row("1", "Bulbasaur", "Grass", "Poison", "Bulbasaur"))
    data.append(make_row("2", "Ivysaur", "Grass", "Poison", "Ivysaur"))
    data.append(make_row("3", "Venusaur", "Grass", "Poison", "Venusaur"))
    data.append(make_row("4", "Charmander", "Fire", "", "Hitokage"))
    data.append(make_row("5", "Charmeleon", "Fire", "", "Lizardo"))
    # data.append(make_row("6", "Charizard", "Fire", "Flying", "リザードン", "Lizardon"))
    # data.append(make_row("7", "Squirtle", "Water", "", "ゼニガメ", "Zenigame"))
    # data.append(make_row("8", "Wartortle", "Water", "", "カメール", "Kameil"))
    # data.append(make_row("9", "Blastoise", "Water", "", "カメックス", "Kamex"))
    # data.append(make_row("10", "Caterpie", "Bug", "", "キャタピー", "Caterpie"))
    # data.append(make_row("11", "Metapod", "Bug", "", "トランセル", "Trancell"))
    # data.append(make_row("12", "Butterfree", "Bug", "Flying", "バタフリー", "Butterfree"))
    # data.append(make_row("13", "Weedle", "Bug", "Poison", "ビードル", "Beedle"))
    # data.append(make_row("14", "Kakuna", "Bug", "Poison", "コクーン", "Cocoon"))
    # data.append(make_row("15", "Beedrill", "Bug", "Poison", "スピアー", "Spear"))
    # data.append(make_row("16", "Pidgey", "Normal", "Flying", "ポッポ", "Poppo"))
    # data.append(make_row("17", "Pidgeotto", "Normal", "Flying", "ピジョン", "Pigeon"))
    # data.append(make_row("18", "Pidgeot", "Normal", "Flying", "ピジョット", "Pigeot"))
    # data.append(make_row("19", "Rattata", "Normal", "", "コラッタ", "Koratta"))
    # data.append(make_row("20", "Raticate", "Normal", "", "ラッタ", "Ratta"))
    # data.append(make_row("21", "Spearow", "Normal", "Flying", "オニスズメ", "Onisuzume"))
    # data.append(make_row("22", "Fearow", "Normal", "Flying", "オニドリル", "Onidrill"))
    # data.append(make_row("23", "Ekans", "Poison", "", "アーボ", "Arbo"))
    # data.append(make_row("24", "Arbok", "Poison", "", "アーボック", "Arbok"))
    # data.append(make_row("25", "Pikachu", "Electric", "", "ピカチュウ", "Pikachu"))
    # data.append(make_row("26", "Raichu", "Electric", "", "ライチュウ", "Raichu"))
    # data.append(make_row("27", "Sandshrew", "Ground", "", "サンド", "Sand"))
    # data.append(make_row("28", "Sandslash", "Ground", "", "サンドパン", "Sandpan"))

    var border_style = mog.Style()
    border_style.foreground("238")
    var table = mog.new_table()
    # var table = mog.Table(
    #     style_function=mog.default_styles,
    #     border=rounded_border(),
    #     border_style=border_style,
    #     border_bottom=True,
    #     border_column=True,
    #     border_header=True,
    #     border_left=True,
    #     border_right=True,
    #     border_top=True,
    #     data=mog.new_string_data(),
    #     width=80,
    # )
    table.rows(data)
    table.width = 100
    table.border = rounded_border()
    table.set_headers(capitalize_headers(headers))
    # table.style_function = style_func
    print(table.render())
