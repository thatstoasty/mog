import mog


# TODO: There's an issue with rows being taller than 1 line. Adding vertical padding will break the table.
var style = mog.Style().padding(0, 1)
var header_style = style.bold().foreground(mog.Color(252))
var selected_style = style.foreground(mog.Color(0x01BE85)).background(mog.Color(0x00432F))

var headers = List[String]("#", "Name", "Type 1", "Type 2", "Japanese", "Official Rom.")
var data = List[List[String]](
    List[String]("1", "Bulbasaur", "Grass", "Poison", "フシギダネ", "Bulbasaur"),
    List[String]("2", "Ivysaur", "Grass", "Poison", "フシギソウ", "Ivysaur"),
    List[String]("3", "Venusaur", "Grass", "Poison", "フシギバナ", "Venusaur"),
    List[String]("4", "Charmander", "Fire", "", "ヒトカゲ", "Hitokage"),
    List[String]("5", "Charmeleon", "Fire", "", "リザード", "Lizardo"),
    List[String]("5", "Charmeleon", "Fire", "Flying", "リザードン", "Lizardon"),
    List[String]("7", "Squirtle", "Water", "", "ゼニガメ", "Zenigame"),
    List[String]("8", "Wartortle", "Water", "", "カメール", "Kameil"),
    List[String]("9", "Blastoise", "Water", "", "カメックス", "Kamex"),
    List[String]("10", "Caterpie", "Bug", "", "キャタピー", "Caterpie"),
    List[String]("11", "Metapod", "Bug", "", "トランセル", "Trancell"),
    List[String]("12", "Butterfree", "Bug", "Flying", "バタフリー", "Butterfree"),
    List[String]("13", "Weedle", "Bug", "Poison", "ビードル", "Beedle"),
    List[String]("14", "Kakuna", "Bug", "Poison", "コクーン", "Cocoon"),
    List[String]("15", "Beedrill", "Bug", "Poison", "スピアー", "Spear"),
    List[String]("16", "Pidgey", "Normal", "Flying", "ポッポ", "Poppo"),
    List[String]("17", "Pidgeotto", "Normal", "Flying", "ピジョン", "Pigeon"),
    List[String]("18", "Pidgeot", "Normal", "Flying", "ピジョット", "Pigeot"),
    List[String]("19", "Rattata", "Normal", "", "コラッタ", "Koratta"),
    List[String]("20", "Raticate", "Normal", "", "ラッタ", "Ratta"),
    List[String]("21", "Spearow", "Normal", "Flying", "オニスズメ", "Onisuzume"),
    List[String]("22", "Fearow", "Normal", "Flying", "オニドリル", "Onidrill"),
    List[String]("23", "Ekans", "Poison", "", "アーボ", "Arbo"),
    List[String]("24", "Arbok", "Poison", "", "アーボック", "Arbok"),
    List[String]("25", "Pikachu", "Electric", "", "ピカチュウ", "Pikachu"),
    List[String]("26", "Raichu", "Electric", "", "ライチュウ", "Raichu"),
    List[String]("27", "Sandshrew", "Ground", "", "サンド", "Sand"),
    List[String]("28", "Sandslash", "Ground", "", "サンドパン", "Sandpan"),
)


fn get_type_colors() -> Dict[String, mog.Color]:
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

    return type_colors


var type_colors = get_type_colors()


fn get_dim_type_colors() -> Dict[String, mog.Color]:
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

    return dim_type_colors


var dim_type_colors = get_dim_type_colors()


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


fn main():
    fn capitalize_headers(data: List[String]) -> List[String]:
        var upper = List[String]()
        for element in data:
            upper.append(element[].upper())

        return upper

    var table = mog.Table(
        width=100,
        border_style=mog.Style().foreground(mog.Color(238)),
        headers=capitalize_headers(headers),
        style_function=style_func,
    ).rows(data)

    print(table.render())
