import mist
from std import testing
from std.testing import TestSuite
from mog.align import align_text_horizontal, align_text_vertical

from mog import Position


comptime text = "hello"
comptime multiline_text = "hello\nhello\nhello"
comptime style = mist.Style(mist.Profile.ansi)


def test_centered_align_text_horizontal() raises:
    testing.assert_equal(align_text_horizontal(text, Position.CENTER, 10, style), "  hello   ")

    # Multi line alignment
    testing.assert_equal(
        align_text_horizontal(multiline_text, Position.CENTER, 10, style),
        "  hello   \n  hello   \n  hello   ",
    )


def test_styled_centered_align_text_horizontal() raises:
    var style = mist.Style(mist.Profile.ansi).background(0xFFFFFF)
    testing.assert_equal(
        align_text_horizontal(text, Position.CENTER, 10, style),
        "\x1b[107m  \x1b[0mhello\x1b[107m   \x1b[0m",
    )

    # Multi line alignment
    testing.assert_equal(
        align_text_horizontal(multiline_text, Position.CENTER, 10, style),
        (
            "\x1b[107m  \x1b[0mhello\x1b[107m   \x1b[0m\n\x1b[107m "
            " \x1b[0mhello\x1b[107m   \x1b[0m\n\x1b[107m  \x1b[0mhello\x1b[107m"
            "   \x1b[0m"
        ),
    )


def test_left_align_text_horizontal() raises:
    testing.assert_equal(align_text_horizontal(text, Position.LEFT, 10, style), "hello     ")

    # Multi line alignment
    testing.assert_equal(
        align_text_horizontal(multiline_text, Position.LEFT, 10, style),
        "hello     \nhello     \nhello     ",
    )


def test_styled_left_align_text_horizontal() raises:
    var style = mist.Style(mist.Profile.ansi).background(0xFFFFFF)
    testing.assert_equal(
        align_text_horizontal(text, Position.LEFT, 10, style),
        "hello\x1b[107m     \x1b[0m",
    )

    # Multi line alignment
    testing.assert_equal(
        align_text_horizontal(multiline_text, Position.LEFT, 10, style),
        "hello\x1b[107m     \x1b[0m\nhello\x1b[107m     \x1b[0m\nhello\x1b[107m     \x1b[0m",
    )


def test_right_align_text_horizontal() raises:
    testing.assert_equal(align_text_horizontal(text, Position.RIGHT, 10, style), "     hello")

    # Multi line alignment
    testing.assert_equal(
        align_text_horizontal(multiline_text, Position.LEFT, 10, style),
        "hello     \nhello     \nhello     ",
    )


def test_styled_right_align_text_horizontal() raises:
    var style = mist.Style(mist.Profile.ansi).background(0xFFFFFF)
    testing.assert_equal(
        align_text_horizontal(text, Position.RIGHT, 10, style),
        "\x1b[107m     \x1b[0mhello",
    )

    # Multi line alignment
    testing.assert_equal(
        align_text_horizontal(multiline_text, Position.RIGHT, 10, style),
        "\x1b[107m     \x1b[0mhello\n\x1b[107m     \x1b[0mhello\n\x1b[107m     \x1b[0mhello",
    )


def test_empty_align_text_horizontal() raises:
    """Test that a padded string is returned if the text is empty."""
    var bg_style = mist.Style(mist.Profile.ansi).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal("", Position.LEFT, 10, style), "          ")
    testing.assert_equal(align_text_horizontal("", Position.RIGHT, 10, style), "          ")
    testing.assert_equal(align_text_horizontal("", Position.CENTER, 10, style), "          ")
    testing.assert_equal(
        align_text_horizontal("", Position.LEFT, 10, bg_style),
        "\x1b[107m          \x1b[0m",
    )


def test_centered_align_text_vertical() raises:
    testing.assert_equal(align_text_vertical(text, Position.CENTER, 3), "\nhello\n")


def test_top_align_text_vertical() raises:
    testing.assert_equal(align_text_vertical(text, Position.TOP, 3), "hello\n\n")


def test_bottom_align_text_vertical() raises:
    testing.assert_equal(align_text_vertical(text, Position.BOTTOM, 5), "\n\n\n\nhello")


def test_tall_text_align_text_vertical() raises:
    """Test that the original text is returned if the text is taller than the height."""
    testing.assert_equal(align_text_vertical(multiline_text, Position.CENTER, 1), multiline_text)


def test_fractional_align_text_horizontal() raises:
    """A position between the named constants splits the padding in proportion to it."""
    # 5 cells of padding: a quarter of it (truncated) goes on the left.
    testing.assert_equal(align_text_horizontal(text, Position(0.25), 10, style), " hello    ")
    testing.assert_equal(align_text_horizontal(text, Position(0.75), 10, style), "   hello  ")

    # The named constants are the endpoints of that same split.
    testing.assert_equal(
        align_text_horizontal(text, Position(0.0), 10, style),
        align_text_horizontal(text, Position.LEFT, 10, style),
    )
    testing.assert_equal(
        align_text_horizontal(text, Position(1.0), 10, style),
        align_text_horizontal(text, Position.RIGHT, 10, style),
    )


def test_fractional_align_text_horizontal_pads_to_width() raises:
    """A fractional position still pads every line out to the requested width."""
    var aligned = align_text_horizontal("ab\ncdef", Position(0.25), 8, style)
    for line in aligned.split("\n"):
        testing.assert_equal(line.byte_length(), 8)


def test_fractional_align_text_vertical() raises:
    """A position between the named constants splits the blank lines in proportion to it."""
    testing.assert_equal(align_text_vertical(text, Position(0.25), 5), "\nhello\n\n\n")
    testing.assert_equal(align_text_vertical(text, Position(0.5), 5), "\n\nhello\n\n")
    testing.assert_equal(align_text_vertical(text, Position(0.75), 5), "\n\n\nhello\n")

    # The named constants are the endpoints of that same split.
    testing.assert_equal(
        align_text_vertical(text, Position(0.0), 5), align_text_vertical(text, Position.TOP, 5)
    )
    testing.assert_equal(
        align_text_vertical(text, Position(1.0), 5), align_text_vertical(text, Position.BOTTOM, 5)
    )


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
