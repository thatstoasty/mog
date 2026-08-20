from std import testing
from std.testing import TestSuite
from mog.table.util import largest, median, sum

import mog


def test_sum() raises:
    var numbers: List[UInt16] = [1, 2, 3, 4, 5]
    testing.assert_equal(sum(numbers), 15)


def test_median() raises:
    var numbers: List[UInt16] = [1, 2, 3, 4, 5]
    testing.assert_equal(median(numbers), 3)

    numbers = [1, 2, 3, 4]
    testing.assert_equal(median(numbers), 2)


def test_largest() raises:
    var numbers: List[UInt16] = [1, 2, 3, 4, 5]
    var result = largest(numbers)
    testing.assert_equal(result[0], 4)
    testing.assert_equal(result[1], 5)


def test_sum_accumulates_beyond_element_range() raises:
    """The total is wider than the elements, so a table with enough columns to exceed
    a UInt16 still reports its real width."""
    var numbers: List[UInt16] = [40000, 40000]
    testing.assert_equal(sum(numbers), 80000)

    var many = List[UInt16](length=100, fill=1000)
    testing.assert_equal(sum(many), 100000)


def test_median_widens_intermediate() raises:
    """The two middle values are summed at a wider type before being halved back."""
    var numbers: List[UInt16] = [40000, 40000]
    testing.assert_equal(median(numbers), 40000)

    var spread: List[UInt16] = [60000, 65535]
    testing.assert_equal(median(spread), 62767)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
