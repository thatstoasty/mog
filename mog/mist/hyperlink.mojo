from .style import osc, st


# hyperlink creates a hyperlink using OSC8.
fn hyperlink(link: String, name: String) -> String:
    return osc + "8;;" + link + st + name + osc + "8;;" + st
