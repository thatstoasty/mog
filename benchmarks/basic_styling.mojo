import mog
from benchmark.compiler import keep


fn basic_styling():
    var style = (
        mog.new_style()
        .bold(True)
        .foreground(mog.Color("#FAFAFA"))
        .background(mog.Color("#7D56F4"))
        .padding_top(2)
        .padding_left(4)
        .width(22)
    )

    var output = style.render("Hello, kitty")
    keep(output)


fn basic_styling_big_file():
    var content: String = ""
    try:
        with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            var style = mog.new_style().bold(True).foreground(mog.Color("#FAFAFA")).background(
                mog.Color("#7D56F4")
            ).width(100)
            var output = style.render(content)
            keep(output)
    except e:
        print(e)