# RGB values of ANSI colors (0-255).
fn build_ansi_hex_codes() -> DynamicVector[String]:
    var values = DynamicVector[String]()
    values.append("#000000")
    values.append("#800000")
    values.append("#008000")
    values.append("#808000")
    values.append("#000080")
    values.append("#800080")
    values.append("#008080")
    values.append("#c0c0c0")
    values.append("#808080")
    values.append("#ff0000")
    values.append("#00ff00")
    values.append("#ffff00")
    values.append("#0000ff")
    values.append("#ff00ff")
    values.append("#00ffff")
    values.append("#ffffff")
    values.append("#000000")
    values.append("#00005f")
    values.append("#000087")
    values.append("#0000af")
    values.append("#0000d7")
    values.append("#0000ff")
    values.append("#005f00")
    values.append("#005f5f")
    values.append("#005f87")
    values.append("#005faf")
    values.append("#005fd7")
    values.append("#005fff")
    values.append("#008700")
    values.append("#00875f")
    values.append("#008787")
    values.append("#0087af")
    values.append("#0087d7")
    values.append("#0087ff")
    values.append("#00af00")
    values.append("#00af5f")
    values.append("#00af87")
    values.append("#00afaf")
    values.append("#00afd7")
    values.append("#00afff")
    values.append("#00d700")
    values.append("#00d75f")
    values.append("#00d787")
    values.append("#00d7af")
    values.append("#00d7d7")
    values.append("#00d7ff")
    values.append("#00ff00")
    values.append("#00ff5f")
    values.append("#00ff87")
    values.append("#00ffaf")
    values.append("#00ffd7")
    values.append("#00ffff")
    values.append("#5f0000")
    values.append("#5f005f")
    values.append("#5f0087")
    values.append("#5f00af")
    values.append("#5f00d7")
    values.append("#5f00ff")
    values.append("#5f5f00")
    values.append("#5f5f5f")
    values.append("#5f5f87")
    values.append("#5f5faf")
    values.append("#5f5fd7")
    values.append("#5f5fff")
    values.append("#5f8700")
    values.append("#5f875f")
    values.append("#5f8787")
    values.append("#5f87af")
    values.append("#5f87d7")
    values.append("#5f87ff")
    values.append("#5faf00")
    values.append("#5faf5f")
    values.append("#5faf87")
    values.append("#5fafaf")
    values.append("#5fafd7")
    values.append("#5fafff")
    values.append("#5fd700")
    values.append("#5fd75f")
    values.append("#5fd787")
    values.append("#5fd7af")
    values.append("#5fd7d7")
    values.append("#5fd7ff")
    values.append("#5fff00")
    values.append("#5fff5f")
    values.append("#5fff87")
    values.append("#5fffaf")
    values.append("#5fffd7")
    values.append("#5fffff")
    values.append("#870000")
    values.append("#87005f")
    values.append("#870087")
    values.append("#8700af")
    values.append("#8700d7")
    values.append("#8700ff")
    values.append("#875f00")
    values.append("#875f5f")
    values.append("#875f87")
    values.append("#875faf")
    values.append("#875fd7")
    values.append("#875fff")
    values.append("#878700")
    values.append("#87875f")
    values.append("#878787")
    values.append("#8787af")
    values.append("#8787d7")
    values.append("#8787ff")
    values.append("#87af00")
    values.append("#87af5f")
    values.append("#87af87")
    values.append("#87afaf")
    values.append("#87afd7")
    values.append("#87afff")
    values.append("#87d700")
    values.append("#87d75f")
    values.append("#87d787")
    values.append("#87d7af")
    values.append("#87d7d7")
    values.append("#87d7ff")
    values.append("#87ff00")
    values.append("#87ff5f")
    values.append("#87ff87")
    values.append("#87ffaf")
    values.append("#87ffd7")
    values.append("#87ffff")
    values.append("#af0000")
    values.append("#af005f")
    values.append("#af0087")
    values.append("#af00af")
    values.append("#af00d7")
    values.append("#af00ff")
    values.append("#af5f00")
    values.append("#af5f5f")
    values.append("#af5f87")
    values.append("#af5faf")
    values.append("#af5fd7")
    values.append("#af5fff")
    values.append("#af8700")
    values.append("#af875f")
    values.append("#af8787")
    values.append("#af87af")
    values.append("#af87d7")
    values.append("#af87ff")
    values.append("#afaf00")
    values.append("#afaf5f")
    values.append("#afaf87")
    values.append("#afafaf")
    values.append("#afafd7")
    values.append("#afafff")
    values.append("#afd700")
    values.append("#afd75f")
    values.append("#afd787")
    values.append("#afd7af")
    values.append("#afd7d7")
    values.append("#afd7ff")
    values.append("#afff00")
    values.append("#afff5f")
    values.append("#afff87")
    values.append("#afffaf")
    values.append("#afffd7")
    values.append("#afffff")
    values.append("#d70000")
    values.append("#d7005f")
    values.append("#d70087")
    values.append("#d700af")
    values.append("#d700d7")
    values.append("#d700ff")
    values.append("#d75f00")
    values.append("#d75f5f")
    values.append("#d75f87")
    values.append("#d75faf")
    values.append("#d75fd7")
    values.append("#d75fff")
    values.append("#d78700")
    values.append("#d7875f")
    values.append("#d78787")
    values.append("#d787af")
    values.append("#d787d7")
    values.append("#d787ff")
    values.append("#d7af00")
    values.append("#d7af5f")
    values.append("#d7af87")
    values.append("#d7afaf")
    values.append("#d7afd7")
    values.append("#d7afff")
    values.append("#d7d700")
    values.append("#d7d75f")
    values.append("#d7d787")
    values.append("#d7d7af")
    values.append("#d7d7d7")
    values.append("#d7d7ff")
    values.append("#d7ff00")
    values.append("#d7ff5f")
    values.append("#d7ff87")
    values.append("#d7ffaf")
    values.append("#d7ffd7")
    values.append("#d7ffff")
    values.append("#ff0000")
    values.append("#ff005f")
    values.append("#ff0087")
    values.append("#ff00af")
    values.append("#ff00d7")
    values.append("#ff00ff")
    values.append("#ff5f00")
    values.append("#ff5f5f")
    values.append("#ff5f87")
    values.append("#ff5faf")
    values.append("#ff5fd7")
    values.append("#ff5fff")
    values.append("#ff8700")
    values.append("#ff875f")
    values.append("#ff8787")
    values.append("#ff87af")
    values.append("#ff87d7")
    values.append("#ff87ff")
    values.append("#ffaf00")
    values.append("#ffaf5f")
    values.append("#ffaf87")
    values.append("#ffafaf")
    values.append("#ffafd7")
    values.append("#ffafff")
    values.append("#ffd700")
    values.append("#ffd75f")
    values.append("#ffd787")
    values.append("#ffd7af")
    values.append("#ffd7d7")
    values.append("#ffd7ff")
    values.append("#ffff00")
    values.append("#ffff5f")
    values.append("#ffff87")
    values.append("#ffffaf")
    values.append("#ffffd7")
    values.append("#ffffff")
    values.append("#080808")
    values.append("#121212")
    values.append("#1c1c1c")
    values.append("#262626")
    values.append("#303030")
    values.append("#3a3a3a")
    values.append("#444444")
    values.append("#4e4e4e")
    values.append("#585858")
    values.append("#626262")
    values.append("#6c6c6c")
    values.append("#767676")
    values.append("#808080")
    values.append("#8a8a8a")
    values.append("#949494")
    values.append("#9e9e9e")
    values.append("#a8a8a8")
    values.append("#b2b2b2")
    values.append("#bcbcbc")
    values.append("#c6c6c6")
    values.append("#d0d0d0")
    values.append("#dadada")
    values.append("#e4e4e4")
    values.append("#eeeeee")

    return values


alias ansi_hex_codes = build_ansi_hex_codes()