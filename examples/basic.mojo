import mog
from mog import Padding, Emphasis


fn main():
    var style = mog.Style(
        width=22,
        foreground=mog.Color(0xFAFAFA),
        background=mog.Color(0x7D56F4),
        emphasis=Emphasis.BOLD,
        padding=Padding(top=2, left=4),
    )

    print(style.render("Hello, Mojo"))
