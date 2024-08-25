from mog.gojo.strings import StringBuilder
import mog

alias line: String = "─"
alias width = 96
alias column_width = 30
alias subtle = mog.AdaptiveColor(light=0xD9DCCF, dark=0x383838)
alias highlight = mog.AdaptiveColor(light=0x874BFD, dark=0x7D56F4)
alias special = mog.AdaptiveColor(light=0x43BF6D, dark=0x73F59F)


fn build_lists() -> String:
    var list_style = mog.Style().border(mog.NORMAL_BORDER, False, True, False, False).border_foreground(
        subtle
    ).margin_right(2).height(8)
    # width(column_width + 1)

    var list_header = mog.Style().border(mog.NORMAL_BORDER, False, False, True, False).border_foreground(
        subtle
    ).margin_right(2)

    var list_item = mog.Style().padding_left(2)
    # var check_mark = mog.Style().foreground(special).padding_right(1).render("✔")
    # var list_done = mog.Style().crossout().foreground(mog.AdaptiveColor(light=0x969B86, dark=0x696969))

    # var lists = mog.join_horizontal(
    #     mog.position.top,
    #     list_style.render(
    #         mog.join_vertical(
    #             mog.position.left,
    #             list_header.render("Citrus Fruits to Try"),
    #             list_item.render("Grapefruit"),
    #             list_item.render("Yuzu"),
    #             list_item.render("Citron"),
    #             list_item.render("Kumquat"),
    #             list_item.render("Pomelo"),
    #         ),
    #     ),
    # list_style.width(column_width).render(
    #     mog.join_vertical(
    #         mog.position.left,
    #         list_header.render("Actual Lip Gloss Vendors"),
    #         list_item.render("Glossier"),
    #         list_item.render("Claire's Boutique"),
    #         list_item.render("Nyx"),
    #         list_item.render("Mac"),
    #         list_item.render("Milk"),
    #     ),
    # ),
    # list_style.width(column_width - 1).render(
    #     mog.join_vertical(
    #         mog.position.left,
    #         list_header.render("Programming Languages"),
    #         list_item.render("Mojo"),
    #         list_item.render("Rust"),
    #         list_item.render("Python"),
    #         list_item.render("Gleam"),
    #         list_item.render("Go"),
    #     ),
    # ),
    # )

    return list_style.render(
        mog.join_vertical(
            mog.position.left,
            list_header.render("Citrus Fruits to Try"),
            list_item.render("Grapefruit"),
            list_item.render("Yuzu"),
            list_item.render("Citron"),
            list_item.render("Kumquat"),
            list_item.render("Pomelo"),
        ),
    )


fn find(s: String, substr: String, start: Int = 0) -> Int:
    var i = start
    for char in s:
        print("char", char)
        if char == substr:
            break
        i += len(char)

    return i


fn get_slice(s: String, start: Int = 0, end: Int = -1) -> String:
    var i = 0
    var builder = StringBuilder()
    for char in s:
        if i >= start and i < end:
            _ = builder.write(char.as_bytes_slice())
        i += len(char)

    return str(builder)


fn split(s: String, sep: String, maxsplit: Int = -1) raises -> List[String]:
    var output = List[String]()

    var str_byte_len = len(s) - 1
    var lhs = 0
    var rhs = 0
    var items = 0
    var sep_len = sep.byte_length()
    if sep_len == 0:
        raise Error("ValueError: empty separator")
    if str_byte_len < 0:
        output.append("")

    while lhs <= str_byte_len:
        rhs = find(s, sep, lhs)
        # rhs = s.find(sep, lhs)
        print(lhs, rhs, str_byte_len)
        if rhs == -1:
            mog.raw_print(s[lhs:])
            output.append(get_slice(s, lhs))
            break

        if maxsplit > -1:
            if items == maxsplit:
                output.append(get_slice(s, lhs))
                break
            items += 1

        output.append(get_slice(s, lhs, rhs))
        mog.raw_print(s[lhs:rhs])
        lhs = rhs + sep_len

    if s.endswith(sep) and (len(output) <= maxsplit or maxsplit == -1):
        output.append("")
    return output


fn main() raises:
    var text: String = "─Go\n\n\n"
    # var text2: String = 'Go\n\n\n'
    var lines = split(text, "\n")
    print(lines.__str__(), len(lines))
    print(text)
    # var lines2 = split(text, "\n")
    # print(lines2.__str__(), len(lines2))
    # print(text2)
