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
    print(repr(style.inline(False).render("hello")))
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
