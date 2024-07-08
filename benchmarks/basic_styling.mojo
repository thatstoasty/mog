import mog
from benchmark.compiler import keep


fn basic_styling():
    var style = (
        mog.Style()
        .bold(True)
        .foreground(mog.Color(0xFAFAFA))
        .background(mog.Color(0x7D56F4))
        .padding_top(2)
        .padding_left(4)
        .width(22)
    )

    var output = style.render("Hello, kitty")
    keep(output)


var file_style = (
    mog.Style()
    .bold(True)
    .foreground(mog.Color(0xFAFAFA))
    .background(mog.Color(0x7D56F4))
    .padding_top(2)
    .padding_left(4)
    .width(22)
)


fn basic_comptime_styling():
    var output = file_style.render("Hello, kitty")
    keep(output)


fn basic_styling_big_file():
    var content: String = ""
    try:
        with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            var style = mog.Style().bold(True).foreground(mog.Color(0xFAFAFA)).background(mog.Color(0x7D56F4)).width(
                100
            )
            var output = style.render(content)
            keep(output)
    except e:
        print(e)
