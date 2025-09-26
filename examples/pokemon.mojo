from collections import Dict

import mog


# TODO: There's an issue with rows being taller than 1 line. Adding vertical padding will break the table.
alias style = mog.Style(mog.Profile.TRUE_COLOR).padding(0, 1)
alias header_style = style.bold().foreground(mog.Color(252))
alias selected_style = style.foreground(mog.Color(0x01BE85)).background(mog.Color(0x00432F))


alias TYPE_COLORS: Dict[String, mog.Color] = {
    "Bug": mog.Color(0xD7FF87),
    "Electric": mog.Color(0xFDFF90),
    "Fire": mog.Color(0xFF7698),
    "Flying": mog.Color(0xFF87D7),
    "Grass": mog.Color(0x75FBAB),
    "Ground": mog.Color(0xFF875F),
    "Normal": mog.Color(0x929292),
    "Poison": mog.Color(0x7D5AFC),
    "Water": mog.Color(0x00E2C7),
}


alias DIM_TYPE_COLORS: Dict[String, mog.Color] = {
    "Bug": mog.Color(0x97AD64),
    "Electric": mog.Color(0xFCFF5F),
    "Fire": mog.Color(0xBA5F75),
    "Flying": mog.Color(0xC97AB2),
    "Grass": mog.Color(0x59B980),
    "Ground": mog.Color(0xC77252),
    "Normal": mog.Color(0x727272),
    "Poison": mog.Color(0x634BD0),
    "Water": mog.Color(0x439F8E),
}

fn style_func(data: mog.Data, row: Int, col: Int) -> mog.Style:
    if row == 0:
        return header_style

    if data[row - 1, 1] == "Pikachu":
        return selected_style

    var is_even = (row % 2 == 0)
    if col == 2 or col == 3:
        if is_even:
            return style.foreground(materialize[DIM_TYPE_COLORS]().get(data[row - 1, col], mog.Color(0xFFFFFF)))
        else:
            return style.foreground(materialize[TYPE_COLORS]().get(data[row - 1, col], mog.Color(0xFFFFFF)))

    if is_even:
        return style.foreground(mog.Color(245))

    return style.foreground(mog.Color(252))


fn main():
    var headers: List[StaticString] = ["#", "Name", "Type 1", "Type 2", "Japanese", "Official Rom."]

    fn capitalize_headers(data: List[StaticString]) -> List[String]:
        var upper = List[String]()
        for element in data:
            upper.append(element.upper())

        return upper^

    var table = mog.Table(
        width=100,
        border_style=mog.Style().foreground(mog.Color(238)),
        headers=capitalize_headers(headers),
        data=mog.Data(
            ["1", "Bulbasaur", "Grass", "Poison", "フシギダネ", "Bulbasaur"],
            ["2", "Ivysaur", "Grass", "Poison", "フシギソウ", "Ivysaur"],
            ["3", "Venusaur", "Grass", "Poison", "フシギバナ", "Venusaur"],
            ["4", "Charmander", "Fire", "", "ヒトカゲ", "Hitokage"],
            ["5", "Charmeleon", "Fire", "", "リザード", "Lizardo"],
            ["5", "Charmeleon", "Fire", "Flying", "リザードン", "Lizardon"],
            ["7", "Squirtle", "Water", "", "ゼニガメ", "Zenigame"],
            ["8", "Wartortle", "Water", "", "カメール", "Kameil"],
            ["9", "Blastoise", "Water", "", "カメックス", "Kamex"],
            ["10", "Caterpie", "Bug", "", "キャタピー", "Caterpie"],
            ["11", "Metapod", "Bug", "", "トランセル", "Trancell"],
            ["12", "Butterfree", "Bug", "Flying", "バタフリー", "Butterfree"],
            ["13", "Weedle", "Bug", "Poison", "ビードル", "Beedle"],
            ["14", "Kakuna", "Bug", "Poison", "コクーン", "Cocoon"],
            ["15", "Beedrill", "Bug", "Poison", "スピアー", "Spear"],
            ["16", "Pidgey", "Normal", "Flying", "ポッポ", "Poppo"],
            ["17", "Pidgeotto", "Normal", "Flying", "ピジョン", "Pigeon"],
            ["18", "Pidgeot", "Normal", "Flying", "ピジョット", "Pigeot"],
            ["19", "Rattata", "Normal", "", "コラッタ", "Koratta"],
            ["20", "Raticate", "Normal", "", "ラッタ", "Ratta"],
            ["21", "Spearow", "Normal", "Flying", "オニスズメ", "Onisuzume"],
            ["22", "Fearow", "Normal", "Flying", "オニドリル", "Onidrill"],
            ["23", "Ekans", "Poison", "", "アーボ", "Arbo"],
            ["24", "Arbok", "Poison", "", "アーボック", "Arbok"],
            ["25", "Pikachu", "Electric", "", "ピカチュウ", "Pikachu"],
            ["26", "Raichu", "Electric", "", "ライチュウ", "Raichu"],
            ["27", "Sandshrew", "Ground", "", "サンド", "Sand"],
            ["28", "Sandslash", "Ground", "", "サンドパン", "Sandpan"],
        ),
        style_function=style_func,
    )

    print(table)
