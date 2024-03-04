from .weave.ansi import ansi
from .stdlib_extensions.builtins.string import split


# Width returns the cell width of characters in the string. ANSI sequences are
# ignored and characters wider than one cell (such as Chinese characters and
# emojis) are appropriately measured.
#
# You should use this instead of len(string) len([]rune(string) as neither
# will give you accurate results.
fn get_width(text: String) raises -> Int:
    var strings = split(text, "\n")
    var width: Int = 0
    for i in range(len(strings)):
        var l = strings[i]
        var w = ansi.printable_rune_width(l)
        if w > width:
            width = w

    return width


# Height returns height of a string in cells. This is done simply by
# counting \n characters. If your strings use \r\n for newlines you should
# convert them to \n first, or simply write a separate fntion for measuring
# height.
fn get_height(text: String) -> Int:
    var height = 1
    for i in range(len(text)):
        if text[i] == "\n":
            height += 1

    return height


# Size returns the width and height of the string in cells. ANSI sequences are
# ignored and characters wider than one cell (such as Chinese characters and
# emojis) are appropriately measured.
fn get_size(text: String) raises -> (Int, Int):
    return get_width(text), get_height(text)
