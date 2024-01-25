from stormlight.style import Style
import stormlight.position


fn main() raises:
    var style = Style()
    style.bold()
    style.width(50)
    style.padding_top(1)
    style.padding_right(1)
    style.padding_bottom(1)
    style.padding_left(1)

    # TODO: Alignment causes the text coloring/formatting to be lost?
    style.horizontal_alignment(position.center)
    style.border("ascii_border")
    style.foreground("#c9a0dc")
    print(style.render("Hola Sekai! This is a test of the stormlight style system."))