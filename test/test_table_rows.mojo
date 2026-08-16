from std import testing
from std.testing import TestSuite

from mog.table import Data


def test_string_data_append() raises:
    var data = Data([
        ["Name", "Age"],
        ["My Name", "30"],
        ["Your Name", "25"],
        ["Their Name", "35"],
    ])
    testing.assert_equal(data.rows(), 4)
    testing.assert_equal(data.columns, 2)

    data.append(["No Name", "0"])
    testing.assert_equal(data.rows(), 5)


def test_string_data_add() raises:
    var data = Data([
        ["Name", "Age"],
        ["My Name", "30"],
        ["Your Name", "25"],
        ["Their Name", "35"],
    ])
    var data2 = Data(
        [["No Name", "0"]],
    )
    var new = data + data2^
    testing.assert_equal(new.rows(), 5)
    testing.assert_equal(new.columns, 2)
    testing.assert_equal(new[4, 0], "No Name")


def test_string_data_iadd() raises:
    var data = Data([
        ["Name", "Age"],
        ["My Name", "30"],
        ["Your Name", "25"],
        ["Their Name", "35"],
    ])
    var data2 = Data(
        [["No Name", "0"]],
    )
    data += data2^
    testing.assert_equal(data.rows(), 5)
    testing.assert_equal(data.columns, 2)
    testing.assert_equal(data[4, 0], "No Name")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
