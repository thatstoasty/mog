from tests.wrapper import MojoTest
from mog.align import align_text_horizontal, align_text_vertical
from external.mist import TerminalStyle, Profile
import mog.position


fn test_align_text_horizontal() raises:
    var test = MojoTest("Testing align.align_text_horizontal")
    var style = TerminalStyle(Profile())

    # Test center alignment
    var centered = align_text_horizontal("hello", position.center, 10, style)
    # print(centered)

    test.assert_equal(centered, "  hello   ")

    # Test left alignment
    var left = align_text_horizontal("hello", position.left, 10, style)
    # print(left)

    test.assert_equal(left, "hello     ")

    # Test right alignment
    var right = align_text_horizontal("hello", position.right, 10, style)
    # print(right)

    test.assert_equal(right, "     hello")


fn test_align_text_vertical() raises:
    var test = MojoTest("Testing align.align_text_vertical")

    # Test center alignment
    var centered = align_text_vertical("hello", position.center, 3)
    # print(centered)

    test.assert_equal(centered, "\nhello\n")

    # Test top alignment
    var top = align_text_vertical("hello", position.top, 3)
    # print(top)

    test.assert_equal(top, "hello\n\n")

    # Test bottom alignment
    var bottom = align_text_vertical("hello", position.bottom, 5)
    # print(bottom)

    test.assert_equal(bottom, "\n\n\n\nhello")


fn main() raises:
    test_align_text_horizontal()
    test_align_text_vertical()
