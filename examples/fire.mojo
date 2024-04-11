from external.gojo.strings import StringBuilder
from external.weave.ansi import printable_rune_width
from external.mist.screen import clear_lines, clear_screen
from mog.join import join_vertical, join_horizontal
from mog.border import rounded_border
from mog.style import Style
from mog import position


fn main() raises:
    # The page style
    var fire_style = Style.new().padding(1).border(
        rounded_border()
    ).border_foreground("#eb4034").foreground("#eb4034")

    # gradient colors
    var colors = List[String](
        "#fb5523",
        "#f9621c",
        "#f76e15",
        "#f4790e",
        "#f28307",
        "#ef8d02",
        "#eb9601",
        "#e89f05",
        "#e4a80d",
        "#e0b017",
    )
    var text = """
                                ▒▒▓▓
                                ▒▒▓▓
                              ░░██░░
                            ░░██████░░
                          ▒▒████████░░
                        ▒▒██████████░░
                      ████████████████▓▓
                    ████████████▓▓████▒▒
                  ████████████▓▓▒▒██████▓▓
                ████████████▓▓▒▒▒▒██████▒▒
                ████████████▓▓▒▒▓▓████████▓▓
              ▒▒████████████▒▒▓▓██████████▓▓
              ██████████▓▓▒▒▒▒▓▓████████████▓▓
            ░░██████████▓▓▒▒▒▒▓▓████████████▓▓
            ████████████▒▒▒▒▒▒████████████████
            ██████████▓▓▒▒▒▒▒▒▓▓████████████████
            ██████████▓▓▒▒▒▒▒▒▓▓████████████████▒▒
            ██████████▒▒▒▒▒▒▒▒▒▒▒▒████████████████
            ████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒████████████████
            ████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████
            ████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓████████████
            ████████▓▓▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒████████████
              ██████▓▓▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▓▓████████
              ████████▓▓▒▒░░░░░░▒▒▒▒▒▒▓▓████████
                ██████▓▓▒▒░░░░░░▒▒▒▒▒▒▓▓████████
                ████████▓▓▒▒░░▒▒▒▒▒▒▓▓████████
                  ████████▓▓▒▒▒▒▒▒▓▓████████
                      ████████████████▓▓
    """
    var i = 0
    while True:
        var style = fire_style.copy()
        if i > 100:
            style = style.copy().foreground(colors[1])
        elif i > 200:
            style = style.copy().foreground(colors[2])
        elif i > 300:
            style = style.copy().foreground(colors[3])
        elif i > 400:
            style = style.copy().foreground(colors[4])
        elif i > 500:
            style = style.copy().foreground(colors[5])
        elif i > 600:
            style = style.copy().foreground(colors[6])
        elif i > 700:
            style = style.copy().foreground(colors[7])
        elif i > 800:
            style = style.copy().foreground(colors[8])
        elif i > 900:
            style = style.copy().foreground(colors[9])
        else:
            style = style.copy().foreground(colors[0])
        var rendered_text = style.render(text)

        if i != 0:
            clear_screen()
        print(rendered_text, end="")
        i += 1

        if i == 1000:
            i = 0
