import testing
import mog
from mog.whitespace import WhitespaceRenderer, with_whitespace_background, with_whitespace_foreground, with_whitespace_chars, place, place_horizontal, place_vertical


def test_with_whitespace_background():
    # Use a renderer with a specific profile to ensure consistent output.
    testing.assert_equal(
        mog.Renderer(mog.ANSI).place(10, 3, mog.right, mog.bottom, "hello", with_whitespace_background[mog.Color(2)]()),
        "\x1b[;42m          \x1b[0m\n\x1b[;42m          \x1b[0m\n\x1b[;42m     \x1b[0mhello"
    )


def test_with_whitespace_foreground():
    testing.assert_equal(
        mog.Renderer(mog.ANSI).place(10, 3, mog.left, mog.center, "hello", with_whitespace_foreground[mog.Color(2)]()),
        "\x1b[;32m          \x1b[0m\nhello\x1b[;32m     \x1b[0m\n\x1b[;32m          \x1b[0m"
    )


def test_with_whitespace_chars():
    testing.assert_equal(
        mog.Renderer(mog.ANSI).place(10, 3, mog.center, mog.center, "hello", with_whitespace_chars["<>"]()),
        "<><><><><>\n<><hello<>\n<><><><><>"
    )

def test_multiple_whitespace_options():
    testing.assert_equal(
        mog.Renderer(mog.ANSI).place(10, 3, mog.center, mog.center, "hello", with_whitespace_chars["<>"](), with_whitespace_background[mog.Color(2)]()),
        "\x1b[;42m<><><><><>\x1b[0m\n\x1b[;42m<><\x1b[0mhello\x1b[;42m<>\x1b[0m\n\x1b[;42m<><><><><>\x1b[0m"
    )

