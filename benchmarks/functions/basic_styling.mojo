from benchmark.compiler import keep

import mog


fn basic_styling():
    var style = (
        mog.Style(
            color=mog.Color(0xFAFAFA),
            background_color=mog.Color(0x7D56F4),
            width=22,
        )
        .bold_text()
        .set_padding(top=2, left=4)
    )

    var output = style.render("Hello, kitty")
    _ = output^


alias file_style = (
    mog.Style(
        mog.Profile.TRUE_COLOR,
        color=mog.Color(0xFAFAFA),
        background_color=mog.Color(0x7D56F4),
        width=22,
    )
    .bold_text()
    .set_padding(top=2, left=4)
)


fn basic_comptime_styling():
    var output = file_style.render("Hello, kitty")
    _ = output^


fn basic_styling_big_file():
    var content: String = ""
    try:
        with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            var style = mog.Style(
                width=100,
                color=mog.Color(0xFAFAFA),
                background_color=mog.Color(0x7D56F4)
            ).bold_text()
            var output = style.render(content)
            _ = output^
    except e:
        print(e)
