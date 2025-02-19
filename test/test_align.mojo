import testing
import mist
import mog.position
from mog.align import align_text_horizontal, align_text_vertical


alias text = "hello"
alias multiline_text = "hello\nhello\nhello"
alias style = mist.Style(mist.ANSI)

def test_centered_align_text_horizontal():
    testing.assert_equal(align_text_horizontal(text, Position.CENTER, 10, style), "  hello   ")
    
    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, Position.CENTER, 10, style), "  hello   \n  hello   \n  hello   ")


def test_styled_centered_align_text_horizontal():
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal(text, Position.CENTER, 10, style), "\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, Position.CENTER, 10, style), "\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m\n\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m\n\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m")


def test_left_align_text_horizontal():
    testing.assert_equal(align_text_horizontal(text, Position.LEFT, 10, style), "hello     ")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, Position.LEFT, 10, style), "hello     \nhello     \nhello     ")


def test_styled_left_align_text_horizontal():
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal(text, Position.LEFT, 10, style), "hello\x1b[;47m     \x1b[0m")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, Position.LEFT, 10, style), "hello\x1b[;47m     \x1b[0m\nhello\x1b[;47m     \x1b[0m\nhello\x1b[;47m     \x1b[0m")


def test_right_align_text_horizontal():
    testing.assert_equal(align_text_horizontal(text, Position.RIGHT, 10, style), "     hello")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, Position.LEFT, 10, style), "hello     \nhello     \nhello     ")


def test_styled_right_align_text_horizontal():
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal(text, Position.RIGHT, 10, style), "\x1b[;47m     \x1b[0mhello")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, Position.RIGHT, 10, style), "\x1b[;47m     \x1b[0mhello\n\x1b[;47m     \x1b[0mhello\n\x1b[;47m     \x1b[0mhello")


def test_empty_align_text_horizontal():
    """Test that a padded string is returned if the text is empty."""
    var bg_style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal("", Position.LEFT, 10, style), "          ")
    testing.assert_equal(align_text_horizontal("", Position.RIGHT, 10, style), "          ")
    testing.assert_equal(align_text_horizontal("", Position.CENTER, 10, style), "          ")
    testing.assert_equal(align_text_horizontal("", Position.LEFT, 10, bg_style), "\x1b[;47m          \x1b[0m")


def test_centered_align_text_vertical():
    testing.assert_equal(align_text_vertical(text, Position.CENTER, 3), "\nhello\n")


def test_top_align_text_vertical():
    testing.assert_equal(align_text_vertical(text, Position.TOP, 3), "hello\n\n")


def test_bottom_align_text_vertical():
    testing.assert_equal(align_text_vertical(text, Position.BOTTOM, 5), "\n\n\n\nhello")


def test_tall_text_align_text_vertical():
    """Test that the original text is returned if the text is taller than the height."""
    testing.assert_equal(align_text_vertical(multiline_text, Position.CENTER, 1), multiline_text)
