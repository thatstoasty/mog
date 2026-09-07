from std import testing
from std.testing import TestSuite

import mog
from mog.size import get_width, get_height
from mog.style import _maybe_convert_tabs, _apply_border
from mog import Position, Profile, Emphasis, Axis


comptime ansi_style = mog.Style(Profile.ANSI)


def test_renderer() raises:
    comptime style = ansi_style.renderer(mog.Renderer(Profile.TRUE_COLOR))
    testing.assert_equal(style._renderer.profile, Profile.TRUE_COLOR)


def test_value() raises:
    comptime style = ansi_style.value("Hello")
    testing.assert_equal(style.render(",", "user!"), "Hello, user!")


def test_tab_width() raises:
    # fnault tab width
    testing.assert_equal(ansi_style.render("\tHello world!"), "    Hello world!")

    # New tab width
    comptime style = ansi_style.tab_width(1)
    testing.assert_equal(style.render("\tHello world!"), " Hello world!")


def test_unset_tab_width() raises:
    comptime style = ansi_style.tab_width(1).unset_tab_width()
    testing.assert_equal(style.render("\tHello world!"), "    Hello world!")


def test_underline_spaces() raises:
    comptime style = ansi_style.underline_spaces()
    # Runs of spaces are styled together: the sequences are the same for each
    # one, so wrapping them separately paints the same thing twice.
    testing.assert_equal(
        style.render("  Hello world!  "),
        "\x1b[4m  \x1b[0mHello\x1b[4m \x1b[0mworld!\x1b[4m  \x1b[0m",
    )

    # Turn on underline spaces (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(
        style.set_emphasis(Emphasis.UNDERLINE_SPACES, value=False).render("  Hello world!  "),
        "  Hello world!  ",
    )


def test_styled_runs_are_not_split_per_character() raises:
    """Every character in a run gets the same escape sequences, so the run is
    wrapped once. This used to emit a pair of sequences per character, which is
    the same picture in five times the bytes, and split grapheme clusters apart
    with escapes in the middle of them."""
    comptime style = ansi_style.underline()
    testing.assert_equal(style.render("Project"), "\x1b[4mProject\x1b[0m")
    testing.assert_equal(style.render("ab cd"), "\x1b[4mab\x1b[0m\x1b[4m \x1b[0m\x1b[4mcd\x1b[0m")
    # A cluster is never split across two runs, which would put escape
    # sequences inside a single drawn character. This matters most where the
    # codepoints of one cluster classify differently: a space carrying a
    # combining mark is one character, and is styled by what it starts with.
    testing.assert_equal(style.render("e\u0301"), "\x1b[4me\u0301\x1b[0m")
    testing.assert_equal(style.render(" \u0301"), "\x1b[4m \u0301\x1b[0m")
    testing.assert_equal(style.render("a \u0301b"), "\x1b[4ma\x1b[0m\x1b[4m \u0301\x1b[0m\x1b[4mb\x1b[0m")
    # A zero-width joiner sequence is one cluster too.
    testing.assert_equal(style.render("\U0001F469\u200d\U0001F467"), "\x1b[4m\U0001F469\u200d\U0001F467\x1b[0m")
    testing.assert_equal(style.render(""), "")
    testing.assert_equal(style.render("a\nb"), "\x1b[4ma\x1b[0m\n\x1b[4mb\x1b[0m")


def test_get_underline_spaces() raises:
    comptime style = ansi_style.underline_spaces()
    testing.assert_true(style.check_emphasis(Emphasis.UNDERLINE_SPACES))


def test_unset_underline_spaces() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.UNDERLINE_SPACES).unset_emphasis(Emphasis.UNDERLINE_SPACES)
    testing.assert_equal(style.render("hello"), "hello")


def test_strikethrough_spaces() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.STRIKETHROUGH_SPACES)
    testing.assert_equal(
        style.render("  Hello world!  "),
        "\x1b[9m  \x1b[0mHello\x1b[9m \x1b[0mworld!\x1b[9m  \x1b[0m",
    )

    # Turn on strikethrough spaces (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(
        style.set_emphasis(Emphasis.STRIKETHROUGH_SPACES, value=False).render("  Hello world!  "),
        "  Hello world!  ",
    )


def test_get_strikethrough_spaces() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.STRIKETHROUGH_SPACES)
    testing.assert_true(style.check_emphasis(Emphasis.STRIKETHROUGH_SPACES))


def test_unset_strikethrough_spaces() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.STRIKETHROUGH_SPACES).unset_emphasis(
        Emphasis.STRIKETHROUGH_SPACES
    )
    testing.assert_equal(style.render("hello"), "hello")


def test_underline() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.UNDERLINE)
    testing.assert_true(style.render("hello"), "\x1b[4mhello\x1b[0m")

    # Turn on underline (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(
        style.set_emphasis(Emphasis.UNDERLINE, value=False).render("hello"),
        "hello",
    )


def test_get_underline() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.UNDERLINE)
    testing.assert_true(style.check_emphasis(Emphasis.UNDERLINE))


def test_unset_underline() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.UNDERLINE).unset_emphasis(Emphasis.UNDERLINE)
    testing.assert_equal(style.render("hello"), "hello")


def test_bold() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.BOLD)
    testing.assert_equal(style.render("hello"), "\x1b[1mhello\x1b[0m")

    # Turn on bold (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.set_emphasis(Emphasis.BOLD, value=False).render("hello"), "hello")


def test_get_bold() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.BOLD)
    testing.assert_true(style.check_emphasis(Emphasis.BOLD))


def test_unset_bold() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.BOLD).unset_emphasis(Emphasis.BOLD)
    testing.assert_equal(style.render("hello"), "hello")


def test_get_italic() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.ITALIC)
    testing.assert_true(style.check_emphasis(Emphasis.ITALIC))


def test_italic() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.ITALIC)
    testing.assert_equal(style.render("hello"), "\x1b[3mhello\x1b[0m")

    # Turn on italic (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(
        style.set_emphasis(Emphasis.ITALIC, value=False).render("hello"),
        "hello",
    )


def test_unset_italic() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.ITALIC).unset_emphasis(Emphasis.ITALIC)
    testing.assert_equal(style.render("hello"), "hello")


def test_get_inline() raises:
    comptime style = ansi_style.inline()
    testing.assert_true(style.check_if_inline())


def test_inline() raises:
    # Inline will ignore border, padding, and margin rendering.
    comptime style = ansi_style.inline().border(mog.PLUS_BORDER).padding(1).margin(1)
    testing.assert_equal(style.render("hello"), "hello")

    # Turn on inline (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(
        style.inline(False).render("hello"),
        "           \n +++++++++ \n +       + \n + hello + \n +       + \n +++++++++ \n           ",
    )


def test_unset_inline() raises:
    comptime style = ansi_style.inline().unset_inline()
    testing.assert_equal(style.render("hello"), "hello")


def test_get_reverse() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.REVERSE)
    testing.assert_true(style.check_emphasis(Emphasis.REVERSE))


def test_reverse() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.REVERSE)
    testing.assert_equal(style.render("hello"), "\x1b[7mhello\x1b[0m")

    # Turn on reverse (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(
        style.set_emphasis(Emphasis.REVERSE, value=False).render("hello"),
        "hello",
    )


def test_unset_reverse() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.REVERSE).unset_emphasis(Emphasis.REVERSE)
    testing.assert_equal(style.render("hello"), "hello")


def test_get_blink() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.BLINK)
    testing.assert_true(style.check_emphasis(Emphasis.BLINK))


def test_blink() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.BLINK)
    testing.assert_equal(style.render("hello"), "\x1b[5mhello\x1b[0m")

    # Turn on blink (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.set_emphasis(Emphasis.BLINK, value=False).render("hello"), "hello")


def test_unset_blink() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.BLINK).unset_emphasis(Emphasis.BLINK)
    testing.assert_equal(style.render("hello"), "hello")


def test_get_faint() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.FAINT)
    testing.assert_true(style.check_emphasis(Emphasis.FAINT))


def test_faint() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.FAINT)
    testing.assert_equal(style.render("hello"), "\x1b[2mhello\x1b[0m")

    # Turn on faint (flag has a value set), but then set it to False (flag has value set, value is False).
    testing.assert_equal(style.set_emphasis(Emphasis.FAINT, value=False).render("hello"), "hello")


def test_unset_faint() raises:
    comptime style = ansi_style.set_emphasis(Emphasis.FAINT).unset_emphasis(Emphasis.FAINT)
    testing.assert_equal(style.render("hello"), "hello")


def test_width() raises:
    comptime style = ansi_style.width(10)
    testing.assert_equal(style.render("hello\nworld\n!"), "hello     \nworld     \n!         ")

    # Text width wider than width chosen, text is word wrapped and padded to 10 chars.
    testing.assert_equal(
        style.render("hello world! This text is long."),
        "hello     \nworld!    \nThis text \nis long.  ",
    )


def test_unset_width() raises:
    comptime style = ansi_style.width(10).unset_width()
    testing.assert_equal(style.render("hello"), "hello")


def test_height() raises:
    comptime style = ansi_style.height(5)
    testing.assert_equal(style.render("hello\nworld\n!"), "hello\nworld\n!    \n     \n     ")

    # Text height taller than height chosen, no height padding applied.
    testing.assert_equal(
        style.render("hello\nworld\n!\n\n\n\n\n"),
        "hello\nworld\n!    \n     \n     \n     \n     \n     ",
    )


def test_unset_height() raises:
    comptime style = ansi_style.height(3).unset_height()
    testing.assert_equal(style.render("hello"), "hello")


def test_max_width() raises:
    comptime style = ansi_style.max_width(10)
    testing.assert_equal(style.render("hello\nworld\n!"), "hello\nworld\n!    ")

    # Text width wider than width chosen, text is truncated.
    testing.assert_equal(
        style.render("hello      truncated\nworld\n!"),
        "hello     \nworld     \n!         ",
    )


def test_unset_max_width() raises:
    comptime style = ansi_style.max_width(10).unset_max_width()
    testing.assert_equal(style.render("hello"), "hello")


def test_max_height() raises:
    comptime style = ansi_style.max_height(5)
    # Max height does not pad with additional lines
    testing.assert_equal(style.render("hello\nworld\n!"), "hello\nworld\n!    ")

    # Text height taller than height chosen, trim extra newlines.
    testing.assert_equal(
        style.render("hello\nworld\n!\n\n\n\n\n"),
        "hello\nworld\n!    \n     \n     ",
    )


def test_unset_max_height() raises:
    comptime style = ansi_style.max_height(3).unset_max_height()
    testing.assert_equal(style.render("hello"), "hello")


def test_horizontal_alignment() raises:
    comptime style = ansi_style.width(9)
    testing.assert_equal(
        style.text_alignment(Axis.HORIZONTAL, Position.LEFT).render("hello"),
        "hello    ",
    )
    testing.assert_equal(
        style.text_alignment(Axis.HORIZONTAL, Position.RIGHT).render("hello"),
        "    hello",
    )
    testing.assert_equal(
        style.text_alignment(Axis.HORIZONTAL, Position.CENTER).render("hello"),
        "  hello  ",
    )


def test_unset_horizontal_alignment() raises:
    comptime style = ansi_style.width(9).text_alignment(Axis.HORIZONTAL, Position.CENTER).unset_text_alignment(
        Axis.HORIZONTAL
    )
    testing.assert_equal(style.render("hello"), "hello    ")


def test_vertical_alignment() raises:
    comptime style = ansi_style.height(3)
    testing.assert_equal(
        style.text_alignment(Axis.VERTICAL, Position.TOP).render("hello"),
        "hello\n     \n     ",
    )
    testing.assert_equal(
        style.text_alignment(Axis.VERTICAL, Position.BOTTOM).render("hello"),
        "     \n     \nhello",
    )
    testing.assert_equal(
        style.text_alignment(Axis.VERTICAL, Position.CENTER).render("hello"),
        "     \nhello\n     ",
    )


def test_unset_vertical_alignment() raises:
    comptime style = ansi_style.height(3).text_alignment(Axis.VERTICAL, Position.CENTER).unset_text_alignment(
        Axis.VERTICAL
    )
    testing.assert_equal(style.render("hello"), "hello\n     \n     ")


def test_alignment() raises:
    comptime style = ansi_style.width(9)
    testing.assert_equal(
        style.text_alignment(Axis.HORIZONTAL, Position.LEFT).render("hello"),
        "hello    ",
    )
    testing.assert_equal(
        style.text_alignment(Axis.HORIZONTAL, Position.RIGHT).render("hello"),
        "    hello",
    )
    testing.assert_equal(
        style.text_alignment(Axis.HORIZONTAL, Position.CENTER).render("hello"),
        "  hello  ",
    )

    comptime height_style = style.height(3)
    testing.assert_equal(
        height_style.text_alignment(Position.LEFT, Position.TOP).render("hello"),
        "hello    \n         \n         ",
    )
    testing.assert_equal(
        height_style.text_alignment(Position.LEFT, Position.BOTTOM).render("hello"),
        "         \n         \nhello    ",
    )
    testing.assert_equal(
        height_style.text_alignment(Position.LEFT, Position.CENTER).render("hello"),
        "         \nhello    \n         ",
    )


def test_foreground() raises:
    comptime style = ansi_style.foreground(mog.Color(12))
    testing.assert_equal(style.render("hello"), "\x1b[94mhello\x1b[0m")


def test_unset_foreground() raises:
    comptime style = ansi_style.foreground(mog.Color(12)).unset_foreground()
    testing.assert_equal(style.render("hello"), "hello")


def test_background() raises:
    comptime style = ansi_style.background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "\x1b[104mhello\x1b[0m")


def test_unset_background() raises:
    comptime style = ansi_style.background(mog.Color(12)).unset_background()
    testing.assert_equal(style.render("hello"), "hello")


def test_border() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(style.render("hello"), "+++++++\n+hello+\n+++++++")


def test_border_top() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_side_rendering(left=False, right=False, bottom=False)
    testing.assert_equal(style.render("hello"), "+++++\nhello")

    # Turn on border top (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_top(False).render("hello"), "hello")


# def test_unset_border_top() raises:
#     comptime style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_top().unset_border_top()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_left() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_side_rendering(top=False, right=False, bottom=False)
    testing.assert_equal(style.render("hello"), "+hello")

    # Turn on border left (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_left(False).render("hello"), "      \nhello\n      ")


# def test_unset_border_left() raises:
#     comptime style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_left().unset_border_left()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_right() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_side_rendering(top=False, left=False, bottom=False)
    testing.assert_equal(style.render("hello"), "hello+")

    # Turn on border right (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_right(False).render("hello"), "hello")


# TODO: All border unsets not working correctly! At least it seems like it. All sides set to false, then activating one and deactivating it makes all sides render!?
# def test_unset_border_right() raises:
#     comptime style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_right().unset_border_right()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_bottom() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_side_rendering(top=False, left=False, right=False)
    testing.assert_equal(style.render("hello"), "hello\n+++++")

    # Turn on border bottom (flag has a value set), but then set it to False (flag has value set, value is False).
    # testing.assert_equal(style.border_bottom(False).render("hello"), "     \nhello\n     ")


# def test_unset_border_bottom() raises:
#     comptime style = ansi_style.border(mog.PLUS_BORDER, False, False, False, False).border_bottom().unset_border_bottom()
#     testing.assert_equal(style.render("hello"), "hello")


def test_border_foreground() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER)

    # One for all sides
    testing.assert_equal(
        style.border_foreground(mog.Color(12)).render("hello"),
        "\x1b[94m+++++++\x1b[0m\n\x1b[94m+\x1b[0mhello\x1b[94m+\x1b[0m\n\x1b[94m+++++++\x1b[0m",
    )

    # Two colors for top/bottom and left/right
    testing.assert_equal(
        style.border_foreground(mog.Color(12), mog.Color(13)).render("hello"),
        "\x1b[94m+++++++\x1b[0m\n\x1b[95m+\x1b[0mhello\x1b[95m+\x1b[0m\n\x1b[94m+++++++\x1b[0m",
    )

    # Three colors for top, left/right, and bottom
    testing.assert_equal(
        style.border_foreground(mog.Color(12), mog.Color(13), mog.Color(14)).render("hello"),
        "\x1b[94m+++++++\x1b[0m\n\x1b[95m+\x1b[0mhello\x1b[95m+\x1b[0m\n\x1b[96m+++++++\x1b[0m",
    )

    # Four colors for top, right, bottom, left
    testing.assert_equal(
        style.border_foreground(mog.Color(12), mog.Color(13), mog.Color(14), mog.Color(15)).render("hello"),
        "\x1b[94m+++++++\x1b[0m\n\x1b[97m+\x1b[0mhello\x1b[95m+\x1b[0m\n\x1b[96m+++++++\x1b[0m",
    )


# def test_border_top_foreground() raises:
#     testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_top_foreground(mog.Color(12)).render("hello"), "\x1b[94m+++++++\x1b[0m\n+hello+\n+++++++")


# def test_unset_border_top_foreground() raises:
#     pass


# def test_border_left_foreground() raises:
#     testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_left_foreground(mog.Color(12)).render("hello"), "+++++++\n\x1b[94m+\x1b[0mhello+\n+++++++")


# def test_unset_border_left_foreground() raises:
#     pass


# def test_border_right_foreground() raises:
#     testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_right_foreground(mog.Color(12)).render("hello"), "+++++++\n+hello\x1b[94m+\x1b[0m\n+++++++")


# def test_unset_border_right_foreground() raises:
#     pass


# def test_border_bottom_foreground() raises:
#     testing.assert_equal(ansi_style.border(mog.PLUS_BORDER).border_bottom_foreground(mog.Color(12)).render("hello"), "+++++++\n+hello+\n\x1b[94m+++++++\x1b[0m")


# def test_unset_border_bottom_foreground() raises:
#     pass


def test_border_background() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER)

    # One for all sides
    testing.assert_equal(
        style.border_background(mog.Color(12)).render("hello"),
        "\x1b[104m+++++++\x1b[0m\n\x1b[104m+\x1b[0mhello\x1b[104m+\x1b[0m\n\x1b[104m+++++++\x1b[0m",
    )

    # Two colors for top/bottom and left/right
    testing.assert_equal(
        style.border_background(mog.Color(12), mog.Color(13)).render("hello"),
        "\x1b[104m+++++++\x1b[0m\n\x1b[105m+\x1b[0mhello\x1b[105m+\x1b[0m\n\x1b[104m+++++++\x1b[0m",
    )

    # Three colors for top, left/right, and bottom
    testing.assert_equal(
        style.border_background(mog.Color(12), mog.Color(13), mog.Color(14)).render("hello"),
        "\x1b[104m+++++++\x1b[0m\n\x1b[105m+\x1b[0mhello\x1b[105m+\x1b[0m\n\x1b[106m+++++++\x1b[0m",
    )

    # Four colors for top, right, bottom, left
    testing.assert_equal(
        style.border_background(mog.Color(12), mog.Color(13), mog.Color(14), mog.Color(15)).render("hello"),
        "\x1b[104m+++++++\x1b[0m\n\x1b[107m+\x1b[0mhello\x1b[105m+\x1b[0m\n\x1b[106m+++++++\x1b[0m",
    )


def test_border_top_background() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_top_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "\x1b[104m+++++++\x1b[0m\n+hello+\n+++++++")


def test_unset_border_top_background() raises:
    pass


def test_border_left_background() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_left_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "+++++++\n\x1b[104m+\x1b[0mhello+\n+++++++")


def test_unset_border_left_background() raises:
    pass


def test_border_right_background() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_right_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "+++++++\n+hello\x1b[104m+\x1b[0m\n+++++++")


def test_unset_border_right_background() raises:
    pass


def test_border_bottom_background() raises:
    comptime style = ansi_style.border(mog.PLUS_BORDER).border_bottom_background(mog.Color(12))
    testing.assert_equal(style.render("hello"), "+++++++\n+hello+\n\x1b[104m+++++++\x1b[0m")


def test_unset_border_bottom_background() raises:
    pass


def test_padding() raises:
    """Test padding on all sides, top/bottom and left/right, top, left/right, bottom, and all sides.
    Note: padding is applied inside of the text area. As opposed to margin which is applied outside the text area.
    """
    comptime border_style = ansi_style.border(mog.PLUS_BORDER)

    # Padding on all sides
    testing.assert_equal(ansi_style.padding(1).render("hello"), "       \n hello \n       ")
    testing.assert_equal(
        border_style.padding(1).render("hello"),
        "+++++++++\n+       +\n+ hello +\n+       +\n+++++++++",
    )

    # Top/bottom and left/right
    testing.assert_equal(
        ansi_style.padding(1, 2).render("hello"),
        "         \n  hello  \n         ",
    )
    testing.assert_equal(
        border_style.padding(1, 2).render("hello"),
        "+++++++++++\n+         +\n+  hello  +\n+         +\n+++++++++++",
    )

    # Top, left/right, bottom
    # testing.assert_equal(ansi_style.padding(1, 2, 3).render("hello"), "         \n  hello  \n         \n         \n         ")
    # testing.assert_equal(border_style.padding(1, 2, 3).render("hello"), "+++++++++++\n+         +\n+  hello  +\n+         +\n+         +\n+         +\n+++++++++++")

    # All sides
    testing.assert_equal(
        ansi_style.padding(top=1, right=2, bottom=3, left=4).render("hello"),
        "           \n    hello  \n           \n           \n           ",
    )
    testing.assert_equal(
        border_style.padding(top=1, right=2, bottom=3, left=4).render("hello"),
        "+++++++++++++\n+           +\n+    hello  +\n+           +\n+           +\n+           +\n+++++++++++++",
    )


# def test_padding_top() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.padding_top(1).render("hello"), "     \nhello")
#     testing.assert_equal(border_style.padding_top(1).render("hello"), "+++++++\n+     +\n+hello+\n+++++++")


# def test_unset_padding_top() raises:
#     pass


# def test_padding_left() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.padding_left(1).render("hello"), " hello")
#     testing.assert_equal(border_style.padding_left(1).render("hello"), "++++++++\n+ hello+\n++++++++")


# def test_unset_padding_left() raises:
#     pass


# def test_padding_right() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.padding_right(1).render("hello"), "hello ")
#     testing.assert_equal(border_style.padding_right(1).render("hello"), "++++++++\n+hello +\n++++++++")


# def test_unset_padding_right() raises:
#     pass


# def test_padding_bottom() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.padding_bottom(1).render("hello"), "hello\n     ")
#     testing.assert_equal(border_style.padding_bottom(1).render("hello"), "+++++++\n+hello+\n+     +\n+++++++")


# def test_unset_padding_bottom() raises:
#     pass


def test_margin() raises:
    """Test margin on all sides, top/bottom and left/right, top, left/right, bottom, and all sides.
    Note: margins are applied outside of the text area. As opposed to padding which is applied inside the text area.
    """
    comptime border_style = ansi_style.border(mog.PLUS_BORDER)

    # Margin on all sides
    testing.assert_equal(ansi_style.margin(1).render("hello"), "       \n hello \n       ")
    testing.assert_equal(
        border_style.margin(1).render("hello"),
        "         \n +++++++ \n +hello+ \n +++++++ \n         ",
    )

    # Top/bottom and left/right
    testing.assert_equal(
        ansi_style.margin(1, 2).render("hello"),
        "         \n  hello  \n         ",
    )
    testing.assert_equal(
        border_style.margin(1, 2).render("hello"),
        "           \n  +++++++  \n  +hello+  \n  +++++++  \n           ",
    )

    # # Top, left/right, bottom
    # testing.assert_equal(ansi_style.margin(1, 2, 3).render("hello"), "         \n  hello  \n         \n         \n         ")
    # testing.assert_equal(border_style.margin(1, 2, 3).render("hello"), "           \n  +++++++  \n  +hello+  \n  +++++++  \n           \n           \n           ")

    # All sides
    testing.assert_equal(
        ansi_style.margin(top=1, right=2, bottom=3, left=4).render("hello"),
        "           \n    hello  \n           \n           \n           ",
    )
    testing.assert_equal(
        border_style.margin(top=1, right=2, bottom=3, left=4).render("hello"),
        "             \n    +++++++  \n    +hello+  \n    +++++++  \n             \n             \n             ",
    )


# def test_margin_top() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.margin_top(1).render("hello"), "     \nhello")
#     testing.assert_equal(border_style.margin_top(1).render("hello"), "       \n+++++++\n+hello+\n+++++++")


# def test_unset_margin_top() raises:
#     pass


# def test_margin_left() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.margin_left(1).render("hello"), " hello")
#     testing.assert_equal(border_style.margin_left(1).render("hello"), " +++++++\n +hello+\n +++++++")


# def test_unset_margin_left() raises:
#     pass


# def test_margin_right() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.margin_right(1).render("hello"), "hello ")
#     testing.assert_equal(border_style.margin_right(1).render("hello"), "+++++++ \n+hello+ \n+++++++ ")


# def test_unset_margin_right() raises:
#     pass


# def test_margin_bottom() raises:
#     comptime border_style = ansi_style.border(mog.PLUS_BORDER)
#     testing.assert_equal(ansi_style.margin_bottom(1).render("hello"), "hello\n     ")
#     testing.assert_equal(border_style.margin_bottom(1).render("hello"), "+++++++\n+hello+\n+++++++\n       ")


# def test_unset_margin_bottom() raises:
#     pass


def test_maybe_convert_tabs() raises:
    # fnault tab width of 4
    testing.assert_equal(_maybe_convert_tabs(ansi_style, "\tHello world!"), "    Hello world!")

    # Set tab width to 1
    testing.assert_equal(
        _maybe_convert_tabs(ansi_style.tab_width(1), "\tHello world!"),
        " Hello world!",
    )

    # Set tab width to -1, which disables `\t` conversion to spaces.
    testing.assert_equal(
        _maybe_convert_tabs(ansi_style.tab_width(-1), "\tHello world!"),
        "\tHello world!",
    )


def test_style_border() raises:
    pass


def test_apply_border() raises:
    # Uses no border by fnault
    testing.assert_equal(_apply_border(ansi_style, "hello"), "hello")

    # Standard pathway for applying a border with no other styling.
    comptime border_style = ansi_style.border(mog.PLUS_BORDER)
    testing.assert_equal(_apply_border(border_style, "hello"), "+++++++\n+hello+\n+++++++")

    # Render with individual border sides disabled.
    testing.assert_equal(
        _apply_border(border_style.unset_border_side_rendering(top=True), "hello"),
        "+hello+\n+++++++",
    )
    testing.assert_equal(
        _apply_border(border_style.unset_border_side_rendering(left=True), "hello"),
        "++++++\nhello+\n++++++",
    )
    testing.assert_equal(
        _apply_border(border_style.unset_border_side_rendering(right=True), "hello"),
        "++++++\n+hello\n++++++",
    )
    testing.assert_equal(
        _apply_border(border_style.unset_border_side_rendering(bottom=True), "hello"),
        "+++++++\n+hello+",
    )

    # If the border sides are set, but the character used is an empty string "", then it should be replaced with a whitespace " ".
    # testing.assert_equal(ansi_style.border(mog.NO_BORDER).unset_border_top().unset_border_bottom()._apply_border("hello"), " hello ")


# def test_apply_margin() raises:
#     pass


# def test_render() raises:
#     pass


def test_render_without_margins() raises:
    """A style with no margins must render exactly as it would without the margin pass."""
    var style = mog.Style().width(12)
    testing.assert_equal(style.render("hello"), "hello       ")
    testing.assert_equal(style.render("one\ntwo"), "one         \ntwo         ")
    testing.assert_equal(mog.Style().render("hello"), "hello")


def test_render_max_height_shorter_than_text() raises:
    """Truncating to fewer lines than the text has."""
    testing.assert_equal(mog.Style().max_height(2).render("a\nb\nc"), "a\nb")
    testing.assert_equal(mog.Style().max_height(1).render("a\nb\nc"), "a")


def test_render_max_height_longer_than_text() raises:
    """When the text already fits, max_height must leave it byte for byte alone. It
    does not pad the text out to the height; that is what `height` is for."""
    testing.assert_equal(mog.Style().max_height(5).render("a\nb"), "a\nb")
    testing.assert_equal(mog.Style().max_height(2).render("a\nb"), "a\nb")
    testing.assert_equal(mog.Style().max_height(5).render("solo"), "solo")


def test_render_width_wraps_only_when_needed() raises:
    """Text narrower than the width passes through; wider text still wraps."""
    testing.assert_equal(mog.Style().width(10).render("short"), "short     ")
    testing.assert_equal(mog.Style().width(10).render("a much longer line here"), "a much    \nlonger    \nline here ")


def test_render_width_wraps_wide_glyphs() raises:
    """Display width, not byte length, decides whether wrapping happens. These glyphs
    are 3 bytes and 2 cells each, so the text fits a width its byte count exceeds."""
    testing.assert_equal(mog.Style().width(10).render("フシギダネ"), "フシギダネ")
    testing.assert_equal(mog.Style().width(6).render("フシギダネ"), "フシギ\nダネ  ")


def test_render_max_width_only_truncates_long_lines() raises:
    testing.assert_equal(mog.Style().max_width(10).render("short"), "short")
    testing.assert_equal(mog.Style().max_width(4).render("truncate me"), "trun")
    testing.assert_equal(mog.Style().max_width(4, tail="…").render("truncate me"), "tru…")
    # Alignment pads every line out to the widest one before truncation runs, so the
    # short line arrives at max_width already padded, and comes back padded to 3.
    testing.assert_equal(mog.Style().max_width(3).render("ab\nlonger"), "ab \nlon")


def test_render_max_width_wide_glyphs() raises:
    """Truncation counts cells, so a 3-byte 2-cell glyph is not cut mid-sequence."""
    testing.assert_equal(mog.Style().max_width(4).render("フシギダネ"), "フシ")
    testing.assert_equal(mog.Style().max_width(10).render("フシギダネ"), "フシギダネ")


def test_render_without_border() raises:
    """A style with no border renders identically to one that never consults a border."""
    testing.assert_equal(mog.Style().render("hello"), "hello")
    testing.assert_equal(mog.Style().width(7).render("hello"), "hello  ")
    testing.assert_equal(mog.Style().border(mog.NO_BORDER).render("hello"), "hello")


def test_affects_layout_false_for_appearance_only() raises:
    """Colour and emphasis are zero-width escape sequences, so they cannot resize text."""
    testing.assert_false(mog.Style().affects_layout())
    testing.assert_false(mog.Style(mog.Profile.ANSI).bold().affects_layout())
    testing.assert_false(mog.Style(mog.Profile.ANSI).faint().italic().affects_layout())
    testing.assert_false(mog.Style(mog.Profile.ANSI).foreground(mog.Color(240)).affects_layout())
    testing.assert_false(mog.Style(mog.Profile.ANSI).background(mog.Color(2)).affects_layout())
    testing.assert_false(mog.Style().tab_width(8).affects_layout())


def test_affects_layout_true_for_geometry() raises:
    testing.assert_true(mog.Style().width(10).affects_layout())
    testing.assert_true(mog.Style().height(3).affects_layout())
    testing.assert_true(mog.Style().max_width(10).affects_layout())
    testing.assert_true(mog.Style().max_height(3).affects_layout())
    testing.assert_true(mog.Style().padding(1).affects_layout())
    testing.assert_true(mog.Style().padding(left=1).affects_layout())
    testing.assert_true(mog.Style().margin(1).affects_layout())
    testing.assert_true(mog.Style().border(mog.ROUNDED_BORDER).affects_layout())
    testing.assert_true(mog.Style().inline().affects_layout())
    testing.assert_true(mog.Style(value="prefix").affects_layout())


def test_affects_layout_agrees_with_rendering() raises:
    """The predicate is only useful if a False answer really means the rendered text
    measures the same as the raw text."""
    var texts = ["hello", "one\ntwo", "フシギダネ", ""]
    var styles = [
        mog.Style(mog.Profile.ANSI),
        mog.Style(mog.Profile.ANSI).bold(),
        mog.Style(mog.Profile.ANSI).foreground(mog.Color(240)).italic(),
        mog.Style(mog.Profile.ANSI).underline().background(mog.Color(2)),
    ]
    for s in range(len(styles)):
        testing.assert_false(styles[s].affects_layout())
        for t in range(len(texts)):
            var rendered = styles[s].render(texts[t])
            testing.assert_equal(get_width(rendered), get_width(texts[t]))
            testing.assert_equal(get_height(rendered), get_height(texts[t]))


def test_left_only_keyword_is_not_ignored() raises:
    """Passing only `left=` must apply, like any other single side. These guards used to
    test `right` twice and never `left`, so a left-only call returned the style
    unchanged."""
    testing.assert_equal(mog.Style().padding(left=2).render("x"), "  x")
    testing.assert_equal(mog.Style().padding(right=2).render("x"), "x  ")
    # The blank line added by top/bottom padding is itself padded out to the widest line.
    testing.assert_equal(mog.Style().padding(top=1).render("x"), " \nx")
    testing.assert_equal(mog.Style().padding(bottom=1).render("x"), "x\n ")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
