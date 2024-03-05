from testing import testing
from mog.align import align_text_horizontal, align_text_vertical
from mog.mist import TerminalStyle, Profile
import mog.position


fn test_align_text_horizontal() raises:
    print("Testing align_text_horizontal")
    var style = TerminalStyle(Profile())

    # Test center alignment
    var centered = align_text_horizontal("hello", position.center, 10, style)
    # print(centered)

    testing.assert_equal(centered, "  hello   ")

    # Test left alignment
    var left = align_text_horizontal("hello", position.left, 10, style)
    # print(left)

    testing.assert_equal(left, "hello     ")

    # Test right alignment
    var right = align_text_horizontal("hello", position.right, 10, style)
    # print(right)

    testing.assert_equal(right, "     hello")


fn test_align_text_vertical() raises:
    print("Testing align_text_vertical")
    var style = TerminalStyle(Profile())

    # Test center alignment
    var centered = align_text_vertical("hello", position.center, 3)
    # print(centered)

    testing.assert_equal(centered, "hello")

    # Test top alignment
    var top = align_text_vertical("hello", position.top, 3)
    # print(top)

    testing.assert_equal(top, "hello\n")

    # Test bottom alignment
    var bottom = align_text_vertical("hello", position.bottom, 5)
    # print(right)

    testing.assert_equal(bottom, "\n\n\nhello")


fn run_tests() raises:
    test_align_text_horizontal()
    test_align_text_vertical()