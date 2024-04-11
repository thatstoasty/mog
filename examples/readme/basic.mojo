from mog import Style


fn main() raises:
    var style = (
        Style.new()
        .bold(True)
        .foreground("#FAFAFA")
        .background("#7D56F4")
        .padding_top(2)
        .padding_left(4)
        .width(22)
    )

    print(style.render("Hello, kitty"))
