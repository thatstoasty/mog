import testing
from testing import TestSuite

from mog.table import Data


fn test_string_data_append() raises:
    var data = Data(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )
    testing.assert_equal(data.rows(), 4)
    testing.assert_equal(data.columns(), 2)

    data.add_row(List[String]("Her Name", "40", "105"))
    testing.assert_equal(data.rows(), 5)
    testing.assert_equal(data.columns(), 3)

    data.add_row("No Name", "0")
    testing.assert_equal(data.rows(), 6)
    testing.assert_equal(data.columns(), 3)


fn test_string_data_add() raises:
    var data = Data(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )
    var data2 = Data(
        List[String]("No Name", "0", "999"),
    )
    var new = data + data2
    testing.assert_equal(new.rows(), 5)
    testing.assert_equal(new.columns(), 3)
    testing.assert_equal(new[4, 0], "No Name")


fn test_string_data_iadd() raises:
    var data = Data(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )
    var data2 = Data(
        List[String]("No Name", "0", "999"),
    )
    data += data2
    testing.assert_equal(data.rows(), 5)
    testing.assert_equal(data.columns(), 3)
    testing.assert_equal(data[4, 0], "No Name")


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
