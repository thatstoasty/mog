import testing
from testing import TestSuite
from mog.size import get_dimensions, get_height, get_width


alias test_string = "This\nis\na\ntest\nstring"


fn test_get_height() raises:
    testing.assert_equal(get_height(test_string), 5)


fn test_get_width() raises:
    testing.assert_equal(get_width(test_string), 6)


fn test_get_size() raises:
    var dim = get_dimensions(test_string)
    testing.assert_equal(dim.width, 6)
    testing.assert_equal(dim.height, 5)


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
