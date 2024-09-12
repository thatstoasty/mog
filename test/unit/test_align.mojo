import testing
from mog.align import align_text_horizontal, align_text_vertical
import mog.mist
import mog.position


def test_align_text_horizontal():
    var style = mist.Style()

    # Test center alignment
    var centered = align_text_horizontal("hello", position.center, 10)
    # print(centered)

    testing.assert_equal(centered, "  hello   ")

    # Test left alignment
    var left = align_text_horizontal("hello", position.left, 10, style)
    # print(left)

    testing.assert_equal(left, "hello     ")

    # Test right alignment
    var right = align_text_horizontal("hello", position.right, 10)
    # print(right)

    testing.assert_equal(right, "     hello")


def test_align_text_vertical():
    # Test center alignment
    var centered = align_text_vertical("hello", position.center, 3)
    # print(centered)

    testing.assert_equal(centered, "\nhello\n")

    # Test top alignment
    var top = align_text_vertical("hello", position.top, 3)
    # print(top)

    testing.assert_equal(top, "hello\n\n")

    # Test bottom alignment
    var bottom = align_text_vertical("hello", position.bottom, 5)
    # print(bottom)

    testing.assert_equal(bottom, "\n\n\n\nhello")
