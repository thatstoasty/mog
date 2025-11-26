import testing
from testing import TestSuite
from mog.whitespace import WhitespaceRenderer

import mog
from mog import Alignment, Position, Profile


alias ANSI_STYLE = mog.Style(Profile.ANSI)

fn test_with_whitespace_background() raises:
    # Use a renderer with a specific profile to ensure consistent output.
    testing.assert_equal(
        WhitespaceRenderer(
            style=ANSI_STYLE.set_background_color(mog.Color(2))
        ).place(10, 3, Alignment(horizontal=Position.RIGHT, vertical=Position.BOTTOM), "hello"),
        "\x1b[42m          \x1b[0m\n\x1b[42m          \x1b[0m\n\x1b[42m     \x1b[0mhello",
        '\x1b[42m     \x1b[0m'
    )


fn test_with_whitespace_foreground() raises:
    testing.assert_equal(
        WhitespaceRenderer(
            style=ANSI_STYLE.set_foreground_color(mog.Color(2))
        ).place(10, 3, Alignment(horizontal=Position.LEFT, vertical=Position.CENTER), "hello"),
        "\x1b[32m          \x1b[0m\nhello\x1b[32m     \x1b[0m\n\x1b[32m          \x1b[0m"
    )


fn test_with_whitespace_chars() raises:
    testing.assert_equal(
        WhitespaceRenderer(
            style=ANSI_STYLE, chars="<>"
        ).place(10, 3, Alignment(horizontal=Position.CENTER, vertical=Position.CENTER), "hello"),
        "<><><><><>\n<>hello<><\n<><><><><>"
    )

fn test_multiple_whitespace_options() raises:
    testing.assert_equal(
        WhitespaceRenderer(
            style=ANSI_STYLE.set_background_color(mog.Color(2)),
            chars="<>"
        ).place(10, 3, Alignment(horizontal=Position.CENTER, vertical=Position.CENTER), "hello"),
        "\x1b[42m<><><><><>\x1b[0m\n\x1b[42m<>\x1b[0mhello\x1b[42m<><\x1b[0m\n\x1b[42m<><><><><>\x1b[0m"
    )


alias TRUE_COLOR_RENDERER = WhitespaceRenderer(style=mog.Style(Profile.TRUE_COLOR))

fn test_place_horizontal() raises:
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.CENTER), "  Hello, World!   ")

    # Text longer than width, return same string
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 10, Position.CENTER), "Hello, World!")


fn test_place_horizontal_left() raises:

    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.LEFT), "Hello, World!     ")


fn test_place_horizontal_right() raises:

    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.RIGHT), "     Hello, World!")


fn test_place_horizontal_fractional() raises:

    # 0 ---------- 1
    # left ----- right
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position(0.2)), " Hello, World!    ")
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position(0.8)), "    Hello, World! ")


fn test_place_vertical() raises:

    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.CENTER), "             \nHello, World!\n             ")

    # Text taller than height, return same string
    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("\nHello, World!\n", 1, Position.CENTER), "\nHello, World!\n")


fn test_place_vertical_top() raises:

    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.TOP), "Hello, World!\n             \n             ")


fn test_place_vertical_bottom() raises:

    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.BOTTOM), "             \n             \nHello, World!")


fn test_place_vertical_fractional() raises:

    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 5, Position(0.2)),
        "             \nHello, World!\n             \n             \n             "
    )
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 5, Position(0.8)),
        "             \n             \n             \nHello, World!\n             "
    )


fn test_place() raises:

    testing.assert_equal(TRUE_COLOR_RENDERER.place(18, 3, Alignment(horizontal=Position.CENTER, vertical=Position.CENTER), "Hello, World!"), "                  \n  Hello, World!   \n                  ")

    # Text taller than height, return width padded string
    testing.assert_equal(TRUE_COLOR_RENDERER.place(18, 1, Alignment(horizontal=Position.CENTER, vertical=Position.CENTER), "Hello, World!"), "  Hello, World!   ")

    # Text wider than width, return height padded string. Remember it's a box, so every line will have equal width.
    testing.assert_equal(TRUE_COLOR_RENDERER.place(1, 3, Alignment(horizontal=Position.CENTER, vertical=Position.CENTER), "Hello, World!"), "             \nHello, World!\n             ")

    # Text taller than height and wider than width, return same string
    testing.assert_equal(TRUE_COLOR_RENDERER.place(1, 1, Alignment(horizontal=Position.CENTER, vertical=Position.CENTER), "Hello, World!"), "Hello, World!")


fn main() raises -> None:
    # TestSuite.discover_tests[__functions_in_module()]().run()
    var suite = TestSuite()
    suite.test[test_with_whitespace_background]()
    suite^.run()
