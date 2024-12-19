import testing
import mist
import mog.position
from mog.align import align_text_horizontal, align_text_vertical


alias text = "hello"
alias multiline_text = "hello\nhello\nhello"


def test_centered_align_text_horizontal():
    testing.assert_equal(align_text_horizontal(text, position.center, 10), "  hello   ")
    
    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, position.center, 10), "  hello   \n  hello   \n  hello   ")


def test_styled_centered_align_text_horizontal():
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal(text, position.center, 10, style), "\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, position.center, 10, style), "\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m\n\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m\n\x1b[;47m  \x1b[0mhello\x1b[;47m   \x1b[0m")


def test_left_align_text_horizontal():
    testing.assert_equal(align_text_horizontal(text, position.left, 10), "hello     ")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, position.left, 10), "hello     \nhello     \nhello     ")


def test_styled_left_align_text_horizontal():
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal(text, position.left, 10, style), "hello\x1b[;47m     \x1b[0m")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, position.left, 10, style), "hello\x1b[;47m     \x1b[0m\nhello\x1b[;47m     \x1b[0m\nhello\x1b[;47m     \x1b[0m")


def test_right_align_text_horizontal():
    testing.assert_equal(align_text_horizontal(text, position.right, 10), "     hello")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, position.left, 10), "hello     \nhello     \nhello     ")


def test_styled_right_align_text_horizontal():
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal(text, position.right, 10, style), "\x1b[;47m     \x1b[0mhello")

    # Multi line alignment
    testing.assert_equal(align_text_horizontal(multiline_text, position.right, 10, style), "\x1b[;47m     \x1b[0mhello\n\x1b[;47m     \x1b[0mhello\n\x1b[;47m     \x1b[0mhello")


def test_empty_align_text_horizontal():
    """Test that a padded string is returned if the text is empty."""
    var style = mist.Style(mist.ANSI).background(0xFFFFFF)
    testing.assert_equal(align_text_horizontal("", position.left, 10), "          ")
    testing.assert_equal(align_text_horizontal("", position.right, 10), "          ")
    testing.assert_equal(align_text_horizontal("", position.center, 10), "          ")
    testing.assert_equal(align_text_horizontal("", position.left, 10, style), "\x1b[;47m          \x1b[0m")


def test_centered_align_text_vertical():
    testing.assert_equal(align_text_vertical(text, position.center, 3), "\nhello\n")


def test_top_align_text_vertical():
    testing.assert_equal(align_text_vertical(text, position.top, 3), "hello\n\n")


def test_bottom_align_text_vertical():
    testing.assert_equal(align_text_vertical(text, position.bottom, 5), "\n\n\n\nhello")


def test_tall_text_align_text_vertical():
    """Test that the original text is returned if the text is taller than the height."""
    testing.assert_equal(align_text_vertical(multiline_text, position.center, 1), multiline_text)
