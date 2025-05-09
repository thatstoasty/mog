import testing
from mog.size import get_height, get_width, get_dimensions


alias test_string = "This\nis\na\ntest\nstring"


def test_get_height():
    testing.assert_equal(get_height(test_string), 5)


def test_get_width():
    testing.assert_equal(get_width(test_string), 6)


def test_get_size():
    var dim = get_dimensions(test_string)
    testing.assert_equal(dim.width, 6)
    testing.assert_equal(dim.height, 5)
