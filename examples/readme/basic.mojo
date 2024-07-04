import mog


fn main():
    var style = (
        mog.new_style()
        .bold(True)
        .foreground(mog.Color("#FAFAFA"))
        .background(mog.Color("#7D56F4"))
        .padding_top(2)
        .padding_left(4)
        .width(22)
    )
    print(style.render("Hello, kitty"))
