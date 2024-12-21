import testing
import mog


alias ansi_style = mog.Style(mog.ANSI)


def test_renderer():
    alias style = ansi_style.renderer(mog.Renderer(mog.TRUE_COLOR))
    testing.assert_equal(style._renderer.profile.value, mog.TRUE_COLOR)


def test_value():
    alias style = ansi_style.value("Hello")
    testing.assert_equal(style.render(",", "user!"), "Hello, user!")


def test_tab_width():
    # Default tab width
    testing.assert_equal(ansi_style.render("\tHello world!"), "    Hello world!")

    # New tab width
    alias style = ansi_style.tab_width(1)
    testing.assert_equal(style.render("\tHello world!"), " Hello world!")


def test_unset_tab_width():
    alias style = ansi_style.tab_width(1).unset_tab_width()
    testing.assert_equal(style.render("\tHello world!"), "    Hello world!")


def test_underline_spaces():
    alias style = ansi_style.underline_spaces()
    testing.assert_equal(style.render("  Hello world!  "), "\x1b[;4m \x1b[0m\x1b[;4m \x1b[0mHello\x1b[;4m \x1b[0mworld!\x1b[;4m \x1b[0m\x1b[;4m \x1b[0m")

    # Turn on underline spaces (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.underline_spaces(False).render("  Hello world!  "), "  Hello world!  ")


def test_get_underline_spaces():
    alias style = ansi_style.underline_spaces()
    testing.assert_true(style.get_underline_spaces())


def test_unset_underline_spaces():
    alias style = ansi_style.underline_spaces().unset_underline_spaces()
    testing.assert_equal(style.render("hello"), "hello")


def test_crossout_spaces():
    alias style = ansi_style.crossout_spaces()
    testing.assert_equal(style.render("  Hello world!  "), "\x1b[;9m \x1b[0m\x1b[;9m \x1b[0mHello\x1b[;9m \x1b[0mworld!\x1b[;9m \x1b[0m\x1b[;9m \x1b[0m")

    # Turn on crossout spaces (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.crossout_spaces(False).render("  Hello world!  "), "  Hello world!  ")


def test_get_crossout_spaces():
    alias style = ansi_style.crossout_spaces()
    testing.assert_true(style.get_crossout_spaces())


def test_unset_crossout_spaces():
    alias style = ansi_style.crossout_spaces().unset_crossout_spaces()
    testing.assert_equal(style.render("hello"), "hello")


def test_underline():
    alias style = ansi_style.underline()
    testing.assert_true(style.render("hello"), "\x1b[4mhello\x1b[0m")

    # Turn on underline (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.underline(False).render("hello"), "hello")


def test_get_underline():
    alias style = ansi_style.underline()
    testing.assert_true(style.get_underline())


def test_unset_underline():
    alias style = ansi_style.underline().unset_underline()
    testing.assert_equal(style.render("hello"), "hello")


def test_bold():
    alias style = ansi_style.bold()
    testing.assert_equal(style.render("hello"), "\x1b[;1mhello\x1b[0m")

    # Turn on bold (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.bold(False).render("hello"), "hello")


def test_get_bold():
    alias style = ansi_style.bold()
    testing.assert_true(style.get_bold())


def test_unset_bold():
    alias style = ansi_style.bold().unset_bold()
    testing.assert_equal(style.render("hello"), "hello")


def test_get_italic():
    alias style = ansi_style.italic()
    testing.assert_true(style.get_italic())


def test_italic():
    alias style = ansi_style.italic()
    testing.assert_equal(style.render("hello"), "\x1b[;3mhello\x1b[0m")

    # Turn on italic (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.italic(False).render("hello"), "hello")


def test_unset_italic():
    alias style = ansi_style.italic().unset_italic()
    testing.assert_equal(style.render("hello"), "hello")


def test_get_inline():
    alias style = ansi_style.inline()
    testing.assert_true(style.get_inline())


def test_inline():
    # Inline will ignore border, padding, and margin rendering.
    alias style = ansi_style.inline().border(mog.PLUS_BORDER).padding(1, 1, 1, 1).margin(1, 1, 1, 1)
    testing.assert_equal(style.render("hello"), "hello")

    # Turn on inline (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.inline(False).render("hello"), "           \n +++++++++ \n +       + \n + hello + \n +       + \n +++++++++ \n           ")


def test_unset_inline():
    alias style = ansi_style.inline().unset_inline()
    testing.assert_equal(style.render("hello"), "hello")


def test_get_reverse():
    alias style = ansi_style.reverse()
    testing.assert_true(style.get_reverse())


def test_reverse():
    alias style = ansi_style.reverse()
    testing.assert_equal(style.render("hello"), "\x1b[;7mhello\x1b[0m")

    # Turn on reverse (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.reverse(False).render("hello"), "hello")


def test_unset_reverse():
    alias style = ansi_style.reverse().unset_reverse()
    testing.assert_equal(style.render("hello"), "hello")


def test_get_blink():
    alias style = ansi_style.blink()
    testing.assert_true(style.get_blink())


def test_blink():
    alias style = ansi_style.blink()
    testing.assert_equal(style.render("hello"), "\x1b[;5mhello\x1b[0m")

    # Turn on blink (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.blink(False).render("hello"), "hello")


def test_unset_blink():
    alias style = ansi_style.blink().unset_blink()
    testing.assert_equal(style.render("hello"), "hello")


def test_get_faint():
    alias style = ansi_style.faint()
    testing.assert_true(style.get_faint())


def test_faint():
    alias style = ansi_style.faint()
    testing.assert_equal(style.render("hello"), "\x1b[;2mhello\x1b[0m")

    # Turn on faint (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.faint(False).render("hello"), "hello")


def test_unset_faint():
    alias style = ansi_style.faint().unset_faint()
    testing.assert_equal(style.render("hello"), "hello")


def test_width():
    alias style = ansi_style.width(10)
    testing.assert_equal(style.render("hello\nworld\n!"), "hello     \nworld     \n!         ")

    # Text width wider than width chosen, text is word wrapped and padded to 10 chars.
    testing.assert_equal(style.render("hello world! This text is long."), "hello     \nworld!    \nThis text \nis long.  ")


def test_unset_width():
    alias style = ansi_style.width(10).unset_width()
    testing.assert_equal(style.render("hello"), "hello")


def test_height():
    alias style = ansi_style.height(5)
    testing.assert_equal(style.render("hello\nworld\n!"), "hello\nworld\n!    \n     \n     ")

    # Text height taller than height chosen, no height padding applied.
    testing.assert_equal(style.render("hello\nworld\n!\n\n\n\n\n"), "hello\nworld\n!    \n     \n     \n     \n     \n     ")


def test_unset_height():
    alias style = ansi_style.height(3).unset_height()
    testing.assert_equal(style.render("hello"), "hello")


def test_max_width():
    alias style = ansi_style.max_width(10)
    testing.assert_equal(style.render("hello\nworld\n!"), "hello\nworld\n!    ")

    # Text width wider than width chosen, text is truncated.
    testing.assert_equal(style.render("hello      truncated\nworld\n!"), "hello     \nworld     \n!         ")


def test_unset_max_width():
    alias style = ansi_style.max_width(10).unset_max_width()
    testing.assert_equal(style.render("hello"), "hello")


def test_max_height():
    alias style = ansi_style.max_height(5)
    # Max height does not pad with additional lines
    testing.assert_equal(style.render("hello\nworld\n!"), "hello\nworld\n!    ")

    # Text height taller than height chosen, trim extra newlines.
    testing.assert_equal(style.render("hello\nworld\n!\n\n\n\n\n"), "hello\nworld\n!    \n     \n     ")


def test_unset_max_height():
    alias style = ansi_style.max_height(3).unset_max_height()
    testing.assert_equal(style.render("hello"), "hello")


def test_horizontal_alignment():
    alias style = ansi_style.width(9)
    testing.assert_equal(style.horizontal_alignment(mog.left).render("hello"), "hello    ")
    testing.assert_equal(style.horizontal_alignment(mog.right).render("hello"), "    hello")
    testing.assert_equal(style.horizontal_alignment(mog.center).render("hello"), "  hello  ")


def test_unset_horizontal_alignment():
    alias style = ansi_style.width(9).horizontal_alignment(mog.center).unset_horizontal_alignment()
    testing.assert_equal(style.render("hello"), "hello    ")


def test_vertical_alignment():
    alias style = ansi_style.height(3)
    testing.assert_equal(style.vertical_alignment(mog.top).render("hello"), "hello\n     \n     ")
    testing.assert_equal(style.vertical_alignment(mog.bottom).render("hello"), "     \n     \nhello")
    testing.assert_equal(style.vertical_alignment(mog.center).render("hello"), "     \nhello\n     ")


def test_unset_vertical_alignment():
    alias style = ansi_style.height(3).vertical_alignment(mog.center).unset_vertical_alignment()
    testing.assert_equal(style.render("hello"), "hello\n     \n     ")


def test_alignment():
    alias style = ansi_style.width(9)
    testing.assert_equal(style.alignment(mog.left).render("hello"), "hello    ")
    testing.assert_equal(style.alignment(mog.right).render("hello"), "    hello")
    testing.assert_equal(style.alignment(mog.center).render("hello"), "  hello  ")

    alias height_style = style.height(3)
    testing.assert_equal(height_style.alignment(mog.left, mog.top).render("hello"), "hello    \n         \n         ")
    testing.assert_equal(height_style.alignment(mog.left, mog.bottom).render("hello"), "         \n         \nhello    ")
    testing.assert_equal(height_style.alignment(mog.left, mog.center).render("hello"), "         \nhello    \n         ")


def test_foreground():
    alias style = ansi_style.foreground(mog.Color(12))
    testing.assert_equal(style.render("hello"), "\x1b[;94mhello\x1b[0m")


def test_unset_foreground():
    alias style = ansi_style.foreground(mog.Color(12)).unset_foreground()
    testing.assert_equal(style.render("hello"), "hello")


def test_background():
    alias style = ansi_style.background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "\x1b[;104mhello\x1b[0m")


def test_unset_background():
    alias style = ansi_style.background(mog.Color(12)).unset_background()
    testing.assert_equal(style.render("hello"), "hello")


def test_border():
    alias style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(style.render("hello"), "+++++++\n+hello+\n+++++++")


def test_border_top():
    alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False)
    testing.assert_equal(style.border_top().render("hello"), "+++++\nhello")

    # Turn on border top (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_top(False).render("hello"), "hello")


# def test_unset_border_top():
#     alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_top().unset_border_top()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_left():
    alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False)
    testing.assert_equal(style.border_left().render("hello"), "+hello")

    # Turn on border left (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_left(False).render("hello"), "      \nhello\n      ")


# def test_unset_border_left():
#     alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_left().unset_border_left()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_right():
    alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False)
    testing.assert_equal(style.border_right().render("hello"), "hello+")

    # Turn on border right (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_right(False).render("hello"), "hello")

# TODO: All border unsets not working correctly! At least it seems like it. All sides set to false, then activating one and deactivating it makes all sides render!?
# def test_unset_border_right():
#     alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_right().unset_border_right()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_bottom():
    alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False)
    testing.assert_equal(style.border_bottom().render("hello"), "hello\n+++++")

    # Turn on border bottom (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_bottom(False).render("hello"), "     \nhello\n     ")


# def test_unset_border_bottom():
#     alias style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_bottom().unset_border_bottom()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_foreground():
    alias style = ansi_style.border(mog.PLUS_BORDER)
    print(style.renderer.profile.value)

    # One for all sides
    testing.assert_equal(style.border_foreground(mog.Color(12)).render("hello"), "\x1b[;94m+++++++\x1b[0m\n\x1b[;94m+\x1b[0mhello\x1b[;94m+\x1b[0m\n\x1b[;94m+++++++\x1b[0m")

    # Two colors for top/bottom and left/right
    testing.assert_equal(style.border_foreground(mog.Color(12), mog.Color(13)).render("hello"), "\x1b[;94m+++++++\x1b[0m\n\x1b[;95m+\x1b[0mhello\x1b[;95m+\x1b[0m\n\x1b[;94m+++++++\x1b[0m")

    # Three colors for top, left/right, and bottom
    testing.assert_equal(style.border_foreground(mog.Color(12), mog.Color(13), mog.Color(14)).render("hello"), "\x1b[;94m+++++++\x1b[0m\n\x1b[;95m+\x1b[0mhello\x1b[;95m+\x1b[0m\n\x1b[;96m+++++++\x1b[0m")

    # Four colors for top, right, bottom, left
    testing.assert_equal(style.border_foreground(mog.Color(12), mog.Color(13), mog.Color(14), mog.Color(15)).render("hello"), "\x1b[;94m+++++++\x1b[0m\n\x1b[;97m+\x1b[0mhello\x1b[;95m+\x1b[0m\n\x1b[;96m+++++++\x1b[0m")


def test_border_top_foreground():
    testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_top_foreground(mog.Color(12)).render("hello"), "\x1b[;94m+++++++\x1b[0m\n+hello+\n+++++++")


def test_unset_border_top_foreground():
    pass


def test_border_left_foreground():
    testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_left_foreground(mog.Color(12)).render("hello"), "+++++++\n\x1b[;94m+\x1b[0mhello+\n+++++++")


def test_unset_border_left_foreground():
    pass


def test_border_right_foreground():
    testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_right_foreground(mog.Color(12)).render("hello"), "+++++++\n+hello\x1b[;94m+\x1b[0m\n+++++++")


def test_unset_border_right_foreground():
    pass


def test_border_bottom_foreground():
    testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_bottom_foreground(mog.Color(12)).render("hello"), "+++++++\n+hello+\n\x1b[;94m+++++++\x1b[0m")


def test_unset_border_bottom_foreground():
    pass


def test_border_background():
    alias style = ansi_style.border(mog.PLUS_BORDER)

    # One for all sides
    testing.assert_equal(style.border_background(mog.Color(12)).render("hello"), "\x1b[;104m+++++++\x1b[0m\n\x1b[;104m+\x1b[0mhello\x1b[;104m+\x1b[0m\n\x1b[;104m+++++++\x1b[0m")

    # Two colors for top/bottom and left/right
    testing.assert_equal(style.border_background(mog.Color(12), mog.Color(13)).render("hello"), "\x1b[;104m+++++++\x1b[0m\n\x1b[;105m+\x1b[0mhello\x1b[;105m+\x1b[0m\n\x1b[;104m+++++++\x1b[0m")

    # Three colors for top, left/right, and bottom
    testing.assert_equal(style.border_background(mog.Color(12), mog.Color(13), mog.Color(14)).render("hello"), "\x1b[;104m+++++++\x1b[0m\n\x1b[;105m+\x1b[0mhello\x1b[;105m+\x1b[0m\n\x1b[;106m+++++++\x1b[0m")

    # Four colors for top, right, bottom, left
    testing.assert_equal(style.border_background(mog.Color(12), mog.Color(13), mog.Color(14), mog.Color(15)).render("hello"), "\x1b[;104m+++++++\x1b[0m\n\x1b[;107m+\x1b[0mhello\x1b[;105m+\x1b[0m\n\x1b[;106m+++++++\x1b[0m")


def test_border_top_background():
    alias style = ansi_style.border(mog.PLUS_BORDER).border_top_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "\x1b[;104m+++++++\x1b[0m\n+hello+\n+++++++")


def test_unset_border_top_background():
    pass


def test_border_left_background():
    alias style = ansi_style.border(mog.PLUS_BORDER).border_left_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "+++++++\n\x1b[;104m+\x1b[0mhello+\n+++++++")


def test_unset_border_left_background():
    pass


def test_border_right_background():
    alias style = ansi_style.border(mog.PLUS_BORDER).border_right_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "+++++++\n+hello\x1b[;104m+\x1b[0m\n+++++++")


def test_unset_border_right_background():
    pass


def test_border_bottom_background():
    alias style = ansi_style.border(mog.PLUS_BORDER).border_bottom_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "+++++++\n+hello+\n\x1b[;104m+++++++\x1b[0m")


def test_unset_border_bottom_background():
    pass


def test_padding():
    """Test padding on all sides, top/bottom and left/right, top, left/right, bottom, and all sides.
    Note: padding is applied inside of the text area. As opposed to margin which is applied outside the text area.
    """
    alias border_style = ansi_style.border(mog.PLUS_BORDER)

    # Padding on all sides
    testing.assert_equal(ansi_style.padding(1).render("hello"), "       \n hello \n       ")
    testing.assert_equal(border_style.padding(1).render("hello"), "+++++++++\n+       +\n+ hello +\n+       +\n+++++++++")

    # Top/bottom and left/right
    testing.assert_equal(ansi_style.padding(1, 2).render("hello"), "         \n  hello  \n         ")
    testing.assert_equal(border_style.padding(1, 2).render("hello"), "+++++++++++\n+         +\n+  hello  +\n+         +\n+++++++++++")

    # Top, left/right, bottom
    testing.assert_equal(ansi_style.padding(1, 2, 3).render("hello"), "         \n  hello  \n         \n         \n         ")
    testing.assert_equal(border_style.padding(1, 2, 3).render("hello"), "+++++++++++\n+         +\n+  hello  +\n+         +\n+         +\n+         +\n+++++++++++")

    # All sides
    testing.assert_equal(ansi_style.padding(1, 2, 3, 4).render("hello"), "           \n    hello  \n           \n           \n           ")
    testing.assert_equal(border_style.padding(1, 2, 3, 4).render("hello"), "+++++++++++++\n+           +\n+    hello  +\n+           +\n+           +\n+           +\n+++++++++++++")


def test_padding_top():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.padding_top(1).render("hello"), "     \nhello")
    testing.assert_equal(border_style.padding_top(1).render("hello"), "+++++++\n+     +\n+hello+\n+++++++")


def test_unset_padding_top():
    pass


def test_padding_left():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.padding_left(1).render("hello"), " hello")
    testing.assert_equal(border_style.padding_left(1).render("hello"), "++++++++\n+ hello+\n++++++++")


def test_unset_padding_left():
    pass


def test_padding_right():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.padding_right(1).render("hello"), "hello ")
    testing.assert_equal(border_style.padding_right(1).render("hello"), "++++++++\n+hello +\n++++++++")


def test_unset_padding_right():
    pass


def test_padding_bottom():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.padding_bottom(1).render("hello"), "hello\n     ")
    testing.assert_equal(border_style.padding_bottom(1).render("hello"), "+++++++\n+hello+\n+     +\n+++++++")


def test_unset_padding_bottom():
    pass


def test_margin():
    """Test margin on all sides, top/bottom and left/right, top, left/right, bottom, and all sides.
    Note: margins are applied outside of the text area. As opposed to padding which is applied inside the text area.
    """
    alias border_style = ansi_style.border(mog.PLUS_BORDER)

    # Margin on all sides
    testing.assert_equal(ansi_style.margin(1).render("hello"), "       \n hello \n       ")
    testing.assert_equal(border_style.margin(1).render("hello"), "         \n +++++++ \n +hello+ \n +++++++ \n         ")

    # Top/bottom and left/right
    testing.assert_equal(ansi_style.margin(1, 2).render("hello"), "         \n  hello  \n         ")
    testing.assert_equal(border_style.margin(1, 2).render("hello"), "           \n  +++++++  \n  +hello+  \n  +++++++  \n           ")

    # Top, left/right, bottom
    testing.assert_equal(ansi_style.margin(1, 2, 3).render("hello"), "         \n  hello  \n         \n         \n         ")
    testing.assert_equal(border_style.margin(1, 2, 3).render("hello"), "           \n  +++++++  \n  +hello+  \n  +++++++  \n           \n           \n           ")

    # All sides
    testing.assert_equal(ansi_style.margin(1, 2, 3, 4).render("hello"), "           \n    hello  \n           \n           \n           ")
    testing.assert_equal(border_style.margin(1, 2, 3, 4).render("hello"), "             \n    +++++++  \n    +hello+  \n    +++++++  \n             \n             \n             ")


def test_margin_top():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.margin_top(1).render("hello"), "     \nhello")
    testing.assert_equal(border_style.margin_top(1).render("hello"), "       \n+++++++\n+hello+\n+++++++")


def test_unset_margin_top():
    pass


def test_margin_left():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.margin_left(1).render("hello"), " hello")
    testing.assert_equal(border_style.margin_left(1).render("hello"), " +++++++\n +hello+\n +++++++")


def test_unset_margin_left():
    pass


def test_margin_right():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.margin_right(1).render("hello"), "hello ")
    testing.assert_equal(border_style.margin_right(1).render("hello"), "+++++++ \n+hello+ \n+++++++ ")


def test_unset_margin_right():
    pass


def test_margin_bottom():
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(ansi_style.margin_bottom(1).render("hello"), "hello\n     ")
    testing.assert_equal(border_style.margin_bottom(1).render("hello"), "+++++++\n+hello+\n+++++++\n       ")


def test_unset_margin_bottom():
    pass


def test_maybe_convert_tabs():
    # Default tab width of 4
    testing.assert_equal(ansi_style._maybe_convert_tabs("\tHello world!"), "    Hello world!")

    # Set tab width to 1
    testing.assert_equal(ansi_style.tab_width(1)._maybe_convert_tabs("\tHello world!"), " Hello world!")

    # Set tab width to -1, which disables `\t` conversion to spaces.
    testing.assert_equal(ansi_style.tab_width(-1)._maybe_convert_tabs("\tHello world!"), "\tHello world!")


def test_style_border():
    pass


def test_apply_border():
    # Uses no border by default
    testing.assert_equal(ansi_style._apply_border("hello"), "hello")

    # Standard pathway for applying a border with no other styling.
    alias border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(border_style._apply_border("hello"), "+++++++\n+hello+\n+++++++")

    # Render with individual border sides disabled.
    testing.assert_equal(border_style.unset_border_top()._apply_border("hello"), "+hello+\n+++++++")
    testing.assert_equal(border_style.unset_border_left()._apply_border("hello"), "++++++\nhello+\n++++++")
    testing.assert_equal(border_style.unset_border_right()._apply_border("hello"), "++++++\n+hello\n++++++")
    testing.assert_equal(border_style.unset_border_bottom()._apply_border("hello"), "+++++++\n+hello+")

    # If the border sides are set, but the character used is an empty string "", then it should be replaced with a whitespace " ".
    # testing.assert_equal(ansi_style.border(mog.NO_BORDER).unset_border_top().unset_border_bottom()._apply_border("hello"), " hello ")



def test_apply_margin():
    pass


def test_render():
    pass
