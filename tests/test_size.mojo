from tests.wrapper import MojoTest
from mog.size import get_height, get_width, get_size


fn test_get_height() raises:
    var test = MojoTest("Testing size.get_height")
    var text = "This\nis\na\ntest\nstring"
    test.assert_equal(get_height(text), 5)


fn test_get_width() raises:
    var test = MojoTest("Testing size.get_width")
    var text = "This\nis\na\ntest\nstring"
    test.assert_equal(get_width(text), 6)


fn test_get_size() raises:
    var test = MojoTest("Testing size.get_size")
    var text = "This\nis\na\ntest\nstring"
    var height: Int
    var width: Int
    width, height = get_size(text)
    test.assert_equal(width, 6)
    test.assert_equal(height, 5)


fn main() raises:
    test_get_height()
    test_get_width()
    test_get_size()
