from std import testing
from std.testing import TestSuite
from mog.whitespace import WhitespaceRenderer

import mog
from mog import Alignment, Position, Profile


comptime ANSI_STYLE = mog.Style(Profile.ANSI)


def test_with_whitespace_background() raises:
    # Use a renderer with a specific profile to ensure consistent output.
    testing.assert_equal(
        WhitespaceRenderer(style=ANSI_STYLE.background(mog.Color(2))).place(
            "hello",
            10,
            3,
            Alignment(horizontal=Position.RIGHT, vertical=Position.BOTTOM),
        ),
        "\x1b[42m          \x1b[0m\n\x1b[42m          \x1b[0m\n\x1b[42m     \x1b[0mhello",
        "\x1b[42m     \x1b[0m",
    )


def test_with_whitespace_foreground() raises:
    testing.assert_equal(
        WhitespaceRenderer(style=ANSI_STYLE.foreground(mog.Color(2))).place(
            "hello",
            10,
            3,
            Alignment(horizontal=Position.LEFT, vertical=Position.CENTER),
        ),
        "\x1b[32m          \x1b[0m\nhello\x1b[32m     \x1b[0m\n\x1b[32m          \x1b[0m",
    )


def test_with_whitespace_chars() raises:
    testing.assert_equal(
        WhitespaceRenderer(style=ANSI_STYLE, chars="<>").place(
            "hello",
            10,
            3,
            Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        ),
        "<><><><><>\n<>hello<><\n<><><><><>",
    )


def test_multiple_whitespace_options() raises:
    testing.assert_equal(
        WhitespaceRenderer(style=ANSI_STYLE.background(mog.Color(2)), chars="<>").place(
            "hello",
            10,
            3,
            Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        ),
        "\x1b[42m<><><><><>\x1b[0m\n\x1b[42m<>\x1b[0mhello\x1b[42m<><\x1b[0m\n\x1b[42m<><><><><>\x1b[0m",
    )


comptime TRUE_COLOR_RENDERER = WhitespaceRenderer(style=mog.Style(Profile.TRUE_COLOR))


def test_place_horizontal() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.CENTER),
        "  Hello, World!   ",
    )

    # Text longer than width, return same string
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 10, Position.CENTER),
        "Hello, World!",
    )


def test_place_horizontal_left() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.LEFT),
        "Hello, World!     ",
    )


def test_place_horizontal_right() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.RIGHT),
        "     Hello, World!",
    )


def test_place_horizontal_fractional() raises:
    # 0 ---------- 1
    # left ----- right
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position(0.2)),
        " Hello, World!    ",
    )
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position(0.8)),
        "    Hello, World! ",
    )


def test_place_vertical() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.CENTER),
        "             \nHello, World!\n             ",
    )

    # Text taller than height, return same string
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("\nHello, World!\n", 1, Position.CENTER),
        "\nHello, World!\n",
    )


def test_place_vertical_top() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.TOP),
        "Hello, World!\n             \n             ",
    )


def test_place_vertical_bottom() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.BOTTOM),
        "             \n             \nHello, World!",
    )


def test_place_vertical_fractional() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 5, Position(0.2)),
        "             \nHello, World!\n             \n             \n             ",
    )
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 5, Position(0.8)),
        "             \n             \n             \nHello, World!\n             ",
    )


def test_place() raises:
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place(
            "Hello, World!",
            18,
            3,
            Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        ),
        "                  \n  Hello, World!   \n                  ",
    )

    # Text taller than height, return width padded string
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place(
            "Hello, World!",
            18,
            1,
            Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        ),
        "  Hello, World!   ",
    )

    # Text wider than width, return height padded string. Remember it's a box, so every line will have equal width.
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place(
            "Hello, World!",
            1,
            3,
            Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        ),
        "             \nHello, World!\n             ",
    )

    # Text taller than height and wider than width, return same string
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place(
            "Hello, World!",
            1,
            1,
            Alignment(horizontal=Position.CENTER, vertical=Position.CENTER),
        ),
        "Hello, World!",
    )


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # var suite = TestSuite()
    # suite.test[test_with_whitespace_background]()
    # suite^.run()
