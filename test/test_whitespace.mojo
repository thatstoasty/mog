import testing
import mog
from mog import Position, Alignment
from mog.whitespace import WhitespaceRenderer


def test_with_whitespace_background():
    # Use a renderer with a specific profile to ensure consistent output.
    testing.assert_equal(
        WhitespaceRenderer(
            style=mog.Style(mog.ANSI).background(mog.Color(2))
        ).place(10, 3, Alignment(Position.RIGHT, Position.BOTTOM), "hello"),
        "\x1b[;42m          \x1b[0m\n\x1b[;42m          \x1b[0m\n\x1b[;42m     \x1b[0mhello"
    )


def test_with_whitespace_foreground():
    testing.assert_equal(
        WhitespaceRenderer(
            style=mog.Style(mog.ANSI).foreground(mog.Color(2))
        ).place(10, 3, Alignment(Position.LEFT, Position.CENTER), "hello"),
        "\x1b[;32m          \x1b[0m\nhello\x1b[;32m     \x1b[0m\n\x1b[;32m          \x1b[0m"
    )


def test_with_whitespace_chars():
    testing.assert_equal(
        WhitespaceRenderer(
            style=mog.Style(mog.ANSI), chars="<>"
        ).place(10, 3, Alignment(Position.CENTER, Position.CENTER), "hello"),
        "<><><><><>\n<><hello<>\n<><><><><>"
    )

def test_multiple_whitespace_options():
    testing.assert_equal(
        WhitespaceRenderer(
            style=mog.Style(mog.ANSI).background(mog.Color(2)),
            chars="<>"
        ).place(10, 3, Alignment(Position.CENTER, Position.CENTER), "hello"),
        "\x1b[;42m<><><><><>\x1b[0m\n\x1b[;42m<><\x1b[0mhello\x1b[;42m<>\x1b[0m\n\x1b[;42m<><><><><>\x1b[0m"
    )


alias TRUE_COLOR_RENDERER = WhitespaceRenderer(style=mog.Style(mog.TRUE_COLOR))


def test_place_horizontal():
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.CENTER), "   Hello, World!  ")

    # Text longer than width, return same string
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 10, Position.CENTER), "Hello, World!")


def test_place_horizontal_left():
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.LEFT), "Hello, World!     ")


def test_place_horizontal_right():
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, Position.RIGHT), "     Hello, World!")


def test_place_horizontal_fractional():
    # 0 ---------- 1
    # left ----- right
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, 0.2), " Hello, World!    ")
    testing.assert_equal(TRUE_COLOR_RENDERER.place_horizontal("Hello, World!", 18, 0.8), "    Hello, World! ")


def test_place_vertical():
    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.CENTER), "             \nHello, World!\n             ")

    # Text taller than height, return same string
    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("\nHello, World!\n", 1, Position.CENTER), "\nHello, World!\n")


def test_place_vertical_top():
    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.TOP), "Hello, World!\n             \n             ")


def test_place_vertical_bottom():
    testing.assert_equal(TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 3, Position.BOTTOM), "             \n             \nHello, World!")


def test_place_vertical_fractional():
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 5, 0.2),
        "             \nHello, World!\n             \n             \n             "
    )
    testing.assert_equal(
        TRUE_COLOR_RENDERER.place_vertical("Hello, World!", 5, 0.8),
        "             \n             \n             \nHello, World!\n             "
    )


def test_place():
    testing.assert_equal(TRUE_COLOR_RENDERER.place(18, 3, Alignment(Position.CENTER, Position.CENTER), "Hello, World!"), "                  \n   Hello, World!  \n                  ")

    # Text taller than height, return width padded string
    testing.assert_equal(TRUE_COLOR_RENDERER.place(18, 1, Alignment(Position.CENTER, Position.CENTER), "Hello, World!"), "   Hello, World!  ")

    # Text wider than width, return height padded string. Remember it's a box, so every line will have equal width.
    testing.assert_equal(TRUE_COLOR_RENDERER.place(1, 3, Alignment(Position.CENTER, Position.CENTER), "Hello, World!"), "             \nHello, World!\n             ")

    # Text taller than height and wider than width, return same string
    testing.assert_equal(TRUE_COLOR_RENDERER.place(1, 1, Alignment(Position.CENTER, Position.CENTER), "Hello, World!"), "Hello, World!")
