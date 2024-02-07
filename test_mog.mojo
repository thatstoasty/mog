# from mog.style import Style
# import mog.position
# from mog.join import join_vertical, join_horizontal


fn main() raises:
    var t = DynamicVector[String]()
    t.append("Hello")
    t.append("World")
    print(height("Hello World!\nThis is an example."))
    # let a: String = "Hello World!\nThis is an example."
    # let b: String = "I could be more creative.\nBut, I'm out of ideas."

    # print(join_vertical(position.center, a, b))
    # print(join_horizontal(position.bottom, a, b))


# fn main() raises:
#     var style = Style()
#     style.bold()
#     style.width(50)
#     style.padding_top(1)
#     style.padding_right(1)
#     style.padding_bottom(1)
#     style.padding_left(1)

#     style.horizontal_alignment(position.center)
#     style.border("ascii_border")
#     style.foreground("#c9a0dc")
#     # style.background("#2d2d2d")
#     print(style.render("Hello World!\nThis is a test of the stormlight style system. Which can wrap lines that are longer than the limit.\n\nYep."))