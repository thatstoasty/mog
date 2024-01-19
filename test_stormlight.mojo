from stormlight.style import Style

fn main() raises:
    var style = Style()
    style.italic()
    print(style.render("Hola Sekai!\n  This is my paragraph. \n Lorem ipsum."))