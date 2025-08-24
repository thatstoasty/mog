import testing
from mog.table.util import largest, median, sum

import mog


def test_sum():
    testing.assert_equal(sum(List[Int](1, 2, 3, 4, 5)), 15)


def test_median():
    testing.assert_equal(median(List[Int](1, 2, 3, 4, 5)), 3)


def test_largest():
    var result = largest(List[Int](1, 2, 3, 4, 5))
    testing.assert_equal(result[0], 4)
    testing.assert_equal(result[1], 5)
