import testing
from testing import TestSuite
from mog.table.util import largest, median, sum

import mog


fn test_sum() raises:
    var numbers: List[UInt] = [1, 2, 3, 4, 5]
    testing.assert_equal(sum(numbers), 15)


fn test_median() raises:
    var numbers: List[UInt] = [1, 2, 3, 4, 5]
    testing.assert_equal(median(numbers), 3)

    numbers = [1, 2, 3, 4]
    testing.assert_equal(median(numbers), 2)


fn test_largest() raises:
    var numbers: List[UInt] = [1, 2, 3, 4, 5]
    var result = largest(numbers)
    testing.assert_equal(result[0], 4)
    testing.assert_equal(result[1], 5)


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
