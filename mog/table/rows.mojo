from math import max
from ..stdlib_extensions.builtins import list


# Data is the interface that wraps the basic methods of a table model.
trait Data:
    # At returns the contents of the cell at the given index.
    fn at(self, row: Int, cell: Int) raises -> String:
        ...

    # Rows returns the number of rows in the table.
    fn rows(self) -> Int:
        ...

    # Columns returns the number of columns in the table.
    fn columns(self) -> Int:
        ...


# StringData is a String-based implementation of the Data interface.
@value
struct StringData(Data):
    var _rows: list[list[String]]
    var _columns: Int

    # At returns the contents of the cell at the given index.
    fn at(self, row: Int, cell: Int) raises -> String:
        if row >= len(self._rows) or cell >= len(self._rows[row]):
            return ""

        return self._rows[row][cell]

    # Rows returns the number of rows in the table.
    fn rows(self) -> Int:
        return len(self._rows)

    # Columns returns the number of columns in the table.
    fn columns(self) -> Int:
        return self._columns

    # Append appends the given row to the table.
    fn append(inout self, row: list[String]):
        self._columns = max(self._columns, len(row))
        self._rows.append(row)

    # Item appends the given row to the table.
    fn item(inout self, rows: list[String]) -> Self:
        self._columns = max(self._columns, len(rows))
        self._rows.append(rows)
        return self


# new_string_data creates a new StringData with the given number of columns.
fn new_string_data(*rows: list[String]) -> StringData:
    var string_data = StringData(
        _rows=list[list[String]](), _columns=0
    )

    for row in rows:
        string_data._columns = max(string_data._columns, len(row[]))
        string_data._rows.append(row[])

    return string_data


alias FilterFunction = fn (row: Int) -> Bool


# Filter applies a filter on some data.
@value
struct Filter(Data):
    var data: StringData
    var filter_function: FilterFunction

    # # Filter applies the given filter fntion to the data.
    # fn filter(inout self, filter_function: FilterFunction) -> Self:
    #     self.filter_function = filter_function
    #     return self

    # Filter applies the given filter fntion to the data.
    fn filter(self, data: Int) -> Bool:
        return self.filter_function(data)

    # Row returns the row at the given index.
    fn at(self, row: Int, cell: Int) raises -> String:
        var j: Int = 0
        var i: Int = 0
        while i < self.data.rows():
            if self.filter(i):
                if j == row:
                    return self.data.at(i, cell)

                j += 1
            i += 1

        return ""

    # Columns returns the number of columns in the table.
    fn columns(self) -> Int:
        return self.data.columns()

    # Rows returns the number of rows in the table.
    fn rows(self) -> Int:
        var j: Int = 0
        var i: Int = 0
        while i < self.data.rows():
            if self.filter(i):
                j += 1
            i += 1

        return j


# # new_filter initializes a new Filter.
# fn new_filter(data: Data) -> Filter:
# 	return Filter(
#         data = data
#     )
