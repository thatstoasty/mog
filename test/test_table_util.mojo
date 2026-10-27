from std import testing
from std.testing import TestSuite
from mog.table.util import largest, median, sum

import mog


def test_sum() raises:
    var numbers: List[UInt] = [1, 2, 3, 4, 5]
    testing.assert_equal(sum(numbers), 15)


def test_median() raises:
    var numbers: List[UInt] = [1, 2, 3, 4, 5]
    testing.assert_equal(median(numbers), 3)

    numbers = [1, 2, 3, 4]
    testing.assert_equal(median(numbers), 2)


def test_largest() raises:
    var numbers: List[UInt] = [1, 2, 3, 4, 5]
    var result = largest(numbers)
    testing.assert_equal(result[0], 4)
    testing.assert_equal(result[1], 5)


def test_sum_of_large_values() raises:
    """Totals past the range of a single narrow column still come out right."""
    var numbers: List[UInt] = [40000, 40000]
    testing.assert_equal(sum(numbers), 80000)

    var many = List[UInt](length=100, fill=1000)
    testing.assert_equal(sum(many), 100000)


def test_median_of_large_values() raises:
    """The two middle values are summed before being halved, without wrapping."""
    var numbers: List[UInt] = [40000, 40000]
    testing.assert_equal(median(numbers), 40000)

    var spread: List[UInt] = [60000, 65535]
    testing.assert_equal(median(spread), 62767)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
