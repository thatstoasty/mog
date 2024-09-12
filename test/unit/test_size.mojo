import testing
from mog.size import get_height, get_width, get_size


def test_get_height():
    var text = "This\nis\na\ntest\nstring"
    testing.assert_equal(get_height(text), 5)


def test_get_width():
    var text = "This\nis\na\ntest\nstring"
    testing.assert_equal(get_width(text), 6)


def test_get_size():
    var text = "This\nis\na\ntest\nstring"
    var height: Int
    var width: Int
    width, height = get_size(text)
    testing.assert_equal(width, 6)
    testing.assert_equal(height, 5)
