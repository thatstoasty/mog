import mog


fn main():
    var style = (
        mog.Style()
        .bold(True)
        .foreground(mog.Color(0xFAFAFA))
        .background(mog.Color(0x7D56F4))
        .padding_top(2)
        .padding_left(4)
        .width(22)
    )

    print(style.render("Hello, kitty"))
