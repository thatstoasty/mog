from benchmark.compiler import keep

import mog
from mog import Padding, TextStyle, Profile

fn basic_styling():
    var style = mog.Style(
        width=22,
        foreground=mog.Color(0xFAFAFA),
        background=mog.Color(0x7D56F4),
        text_style=TextStyle.BOLD,
        padding=Padding(top=2, left=4),
    )

    var output = style.render("Hello, Mojo")
    _ = output^


alias file_style = mog.Style(
    color_profile=Profile.TRUE_COLOR,
    width=22,
    foreground=mog.Color(0xFAFAFA),
    background=mog.Color(0x7D56F4),
    text_style=TextStyle.BOLD,
    padding=Padding(top=2, left=4),
)


fn basic_comptime_styling():
    var output = file_style.render("Hello, Mojo")
    _ = output^


fn basic_styling_big_file():
    var content: String = ""
    try:
        with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            var style = mog.Style(
                width=100,
                foreground=mog.Color(0xFAFAFA),
                background=mog.Color(0x7D56F4),
                text_style=TextStyle.BOLD,
            )
            var output = style.render(content)
            _ = output^
    except e:
        print(e)
