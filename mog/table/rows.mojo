trait Data(CollectionElement):
    """Trait that wraps the basic methods of a table model."""

    fn at(self, row: Int, cell: Int) -> String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            cell: The cell index.

        Returns:
            The contents of the cell at the given index.
        """
        ...

    fn rows(self) -> Int:
        """Returns the number of rows in the table."""
        ...

    fn columns(self) -> Int:
        """Returns the number of columns in the table."""
        ...


@value
struct StringData(Data):
    """String-based implementation of the Data Trait.

    Example Usage:
    ```mojo
    import mog

    fn main():
        var data = mog.StringData()
        data.append(List[String]("Name", "Age"))
        data.append(List[String]("My Name", "30"))
        data.append(List[String]("Your Name", "25"))
        data.append(List[String]("Their Name", "35"))
        print(data.at(1, 0), data.at(1, 1))
    ```
    """

    var _rows: List[List[String]]
    var _columns: Int

    fn __init__(inout self, _rows: List[List[String]] = List[List[String]](), _columns: Int = 0):
        self._rows = _rows
        self._columns = _columns

    fn at(self, row: Int, cell: Int) -> String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            cell: The cell index.

        Returns:
            The contents of the cell at the given index.
        """
        if row >= len(self._rows) or cell >= len(self._rows[row]):
            return ""

        return self._rows[row][cell]

    fn rows(self) -> Int:
        """Returns the number of rows in the table."""
        return len(self._rows)

    fn columns(self) -> Int:
        """Returns the number of columns in the table."""
        return self._columns

    fn append(inout self, row: List[String]):
        """Appends the given row to the table.

        Args:
            row: The row to append.
        """
        self._columns = max(self._columns, len(row))
        self._rows.append(row)

    fn item(inout self, rows: List[String]) -> Self:
        """Appends the given row to the table.

        Args:
            rows: The row to append.
        """
        self._columns = max(self._columns, len(rows))
        self._rows.append(rows)
        return self


alias FilterFunction = fn (row: Int) -> Bool
"""FilterFunction is a function type that filters rows based on a condition."""


@value
struct Filter[T: Data](Data):
    """Applies a filter functoin on some data."""

    var data: T
    var filter_function: FilterFunction

    fn filter(self, data: Int) -> Bool:
        """Applies the given filter function to the data."""
        return self.filter_function(data)

    fn at(self, row: Int, cell: Int) -> String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            cell: The cell index.

        Returns:
            The contents of the cell at the given index.
        """
        var j: Int = 0
        var i: Int = 0
        while i < self.data.rows():
            if self.filter(i):
                if j == row:
                    return self.data.at(i, cell)

                j += 1
            i += 1

        return ""

    fn columns(self) -> Int:
        """Returns the number of columns in the table."""
        return self.data.columns()

    fn rows(self) -> Int:
        """Returns the number of rows in the table."""
        var j: Int = 0
        var i: Int = 0
        while i < self.data.rows():
            if self.filter(i):
                j += 1
            i += 1

        return j
