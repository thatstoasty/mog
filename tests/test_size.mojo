from testing import testing
from mog.size import get_height, get_width, get_size


fn test_get_height() raises:
    print("Testing get_height")
    var text = "This\nis\na\ntest\nstring"
    testing.assert_equal(get_height(text), 5)


fn test_get_width() raises:
    print("Testing get_width")
    var text = "This\nis\na\ntest\nstring"
    testing.assert_equal(get_width(text), 6)


fn test_get_size() raises:
    print("Testing get_size")
    var text = "This\nis\na\ntest\nstring"
    var height: Int
    var width: Int
    width, height = get_size(text)
    testing.assert_equal(width, 6)
    testing.assert_equal(height, 5)


fn run_tests() raises:
    test_get_height()
    test_get_width()
    test_get_size()