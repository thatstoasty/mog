import testing

from mog.table import Filter, StringData


def test_string_data_append():
    var data = StringData(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )
    testing.assert_equal(data.rows(), 4)
    testing.assert_equal(data.columns(), 2)

    data.append(List[String]("Her Name", "40", "105"))
    testing.assert_equal(data.rows(), 5)
    testing.assert_equal(data.columns(), 3)

    data.append("No Name", "0")
    testing.assert_equal(data.rows(), 6)
    testing.assert_equal(data.columns(), 3)


def test_string_data_add():
    var data = StringData(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )
    var data2 = StringData(
        List[String]("No Name", "0", "999"),
    )
    var new = data + data2
    testing.assert_equal(new.rows(), 5)
    testing.assert_equal(new.columns(), 3)
    testing.assert_equal(new[4, 0], "No Name")


def test_string_data_iadd():
    var data = StringData(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )
    var data2 = StringData(
        List[String]("No Name", "0", "999"),
    )
    data += data2
    testing.assert_equal(data.rows(), 5)
    testing.assert_equal(data.columns(), 3)
    testing.assert_equal(data[4, 0], "No Name")


def test_filter():
    var data = StringData(
        List[String]("Name", "Age"),
        List[String]("My Name", "30"),
        List[String]("Your Name", "25"),
        List[String]("Their Name", "35")
    )

    fn filter_headers(row: Int) -> Bool:
        return row != 0

    var filter = Filter(data, filter_headers)
    testing.assert_equal(filter.rows(), 3)
    testing.assert_equal(filter.columns(), 2)
    testing.assert_equal(filter[0, 0], "My Name")
