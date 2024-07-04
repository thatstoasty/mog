from .style import Style, new_style
from .profile import Profile


alias RED = 0xE88388
alias GREEN = 0xA8CC8C
alias YELLOW = 0xDBAB79
alias BLUE = 0x71BEF2
alias MAGENTA = 0xD290E4
alias CYAN = 0x66C2CD
alias GRAY = 0xB9BFCA


# Convenience functions for quick style application
fn render_as_color(text: String, color: UInt32) -> String:
    var profile = Profile()
    return new_style(profile.value).foreground(color=profile.color(color)).render(text)


fn red(text: String) -> String:
    """Apply red color to the text."""
    return render_as_color(text, RED)


fn green(text: String) -> String:
    """Apply green color to the text."""
    return render_as_color(text, GREEN)


fn yellow(text: String) -> String:
    """Apply yellow color to the text."""
    return render_as_color(text, YELLOW)


fn blue(text: String) -> String:
    """Apply blue color to the text."""
    return render_as_color(text, BLUE)


fn magenta(text: String) -> String:
    """Apply magenta color to the text."""
    return render_as_color(text, MAGENTA)


fn cyan(text: String) -> String:
    """Apply cyan color to the text."""
    return render_as_color(text, CYAN)


fn gray(text: String) -> String:
    """Apply gray color to the text."""
    return render_as_color(text, GRAY)


fn render_with_background_color(text: String, color: UInt32) -> String:
    var profile = Profile()
    return new_style().background(color=profile.color(color)).render(text)


fn red_background(text: String) -> String:
    """Apply red background color to the text."""
    return render_with_background_color(text, RED)


fn green_background(text: String) -> String:
    """Apply green background color to the text."""
    return render_with_background_color(text, GREEN)


fn yellow_background(text: String) -> String:
    """Apply yellow background color to the text."""
    return render_with_background_color(text, YELLOW)


fn blue_background(text: String) -> String:
    """Apply blue background color to the text."""
    return render_with_background_color(text, BLUE)


fn magenta_background(text: String) -> String:
    """Apply magenta background color to the text."""
    return render_with_background_color(text, MAGENTA)


fn cyan_background(text: String) -> String:
    """Apply cyan background color to the text."""
    return render_with_background_color(text, CYAN)


fn gray_background(text: String) -> String:
    """Apply gray background color to the text."""
    return render_with_background_color(text, GRAY)


fn bold(text: String) -> String:
    return new_style().bold().render(text)


fn faint(text: String) -> String:
    return new_style().faint().render(text)


fn italic(text: String) -> String:
    return new_style().italic().render(text)


fn underline(text: String) -> String:
    return new_style().underline().render(text)


fn overline(text: String) -> String:
    return new_style().overline().render(text)


fn crossout(text: String) -> String:
    return new_style().crossout().render(text)
