from collections import Optional


trait Data(CollectionElement):
    """Trait that wraps the basic methods of a table model."""

    # TODO: Need to figure out if I want this to return an optional or just raise.
    # Also it should return a ref to the data, not a copy. When traits support attributes.
    fn __getitem__(self, row: Int, column: Int) -> String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            column: The column index.

        Returns:
            The contents of the cell at the given index.
        """
        ...

    fn rows(self) -> Int:
        """Returns the number of rows in the table.

        Returns:
            The number of rows in the table.
        """
        ...

    fn columns(self) -> Int:
        """Returns the number of columns in the table.

        Returns:
            The number of columns in the table.
        """
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
        print(data[1, 0], data[1, 1])
    ```
    """

    var _rows: List[List[String]]
    """The rows of the table."""
    var _columns: Int
    """The number of columns in the table."""

    fn __init__(out self, rows: List[List[String]] = List[List[String]](), columns: Int = 0):
        """Initializes a new StringData instance.

        Args:
            rows: The rows of the table.
            columns: The number of columns in the table.
        """
        self._rows = rows
        self._columns = columns

    # TODO: Can't return ref String because it depends on the origin of a struct attribute
    # and Traits do not support variables yet.
    fn __getitem__(self, row: Int, column: Int) -> String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            column: The column index.

        Returns:
            The contents of the cell at the given index.
        """
        return self._rows[row][column]

    fn rows(self) -> Int:
        """Returns the number of rows in the table.

        Returns:
            The number of rows in the table.
        """
        return len(self._rows)

    fn columns(self) -> Int:
        """Returns the number of columns in the table.

        Returns:
            The number of columns in the table.
        """
        return self._columns

    fn append(mut self, row: List[String]):
        """Appends the given row to the table.

        Args:
            row: The row to append.
        """
        self._columns = max(self._columns, len(row))
        self._rows.append(row)

    fn item(mut self, rows: List[String]) -> Self:
        """Appends the given row to the table.

        Args:
            rows: The row to append.

        Returns:
            The updated table.
        """
        self._columns = max(self._columns, len(rows))
        self._rows.append(rows)
        return self


alias FilterFunction = fn (row: Int) -> Bool
"""Function type that filters rows based on a condition."""


@value
struct Filter[DataType: Data](Data):
    """Applies a filter function on some data.

    Parameters:
        DataType: The type of data to use for the table.
    """

    var data: DataType
    """The data of the table."""
    var filter_function: FilterFunction
    """The filter function to apply."""

    fn filter(self, data: Int) -> Bool:
        """Applies the given filter function to the data.

        Args:
            data: The data to filter.

        Returns:
            The filtered data.
        """
        return self.filter_function(data)

    fn __getitem__(self, row: Int, column: Int) -> String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            column: The column index.

        Returns:
            The contents of the cell at the given index.
        """
        var j = 0
        var i = 0
        while i < self.data.rows():
            if self.filter(i):
                if j == row:
                    return self.data[i, column]

                j += 1
            i += 1

        return ""

    fn columns(self) -> Int:
        """Returns the number of columns in the table.

        Returns:
            The number of columns in the table.
        """
        return self.data.columns()

    fn rows(self) -> Int:
        """Returns the number of rows in the table.

        Returns:
            The number of rows in the table.
        """
        var j = 0
        var i = 0
        while i < self.data.rows():
            if self.filter(i):
                j += 1
            i += 1

        return j
