@fieldwise_init
struct Data(Copyable, Movable):
    """Table data.

    #### Example Usage:
    ```mojo
    import mog

    fn main():
        var data = mog.Data(
            ["Name", "Age"],
            ["My Name", "30"],
            ["Your Name", "25"],
            ["Their Name", "35"]
        )
        print(data[1, 0], data[1, 1])
    ```
    """

    var _rows: List[List[String]]
    """The rows of the table."""
    var _columns: UInt
    """The number of columns in the table."""

    fn __init__(out self):
        """Initializes a new Data instance."""
        self._rows = List[List[String]]()
        self._columns = 0

    fn __init__(out self, var rows: List[List[String]]):
        """Initializes a new Data instance.

        Args:
            rows: The rows of the table.
        """
        self._rows = rows^
        self._columns = UInt(len(self._rows))

    fn __init__(out self, *rows: List[String]):
        """Initializes a new Data instance.

        Args:
            rows: The rows of the table.
        """
        var widest: UInt = 0
        var r = List[List[String]](capacity=len(rows))
        for row in rows:
            widest = max(widest, UInt(len(row)))
            r.append(row.copy())
        self._rows = r^
        self._columns = widest

    # TODO: Can't return ref String because it depends on the origin of a struct attribute
    # and Traits do not support variables yet.
    fn __getitem__(self, row: UInt, column: UInt) -> ref [self._rows[row][column]] String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            column: The column index.

        Returns:
            The contents of the cell at the given index.
        """
        return self._rows[row][column]

    fn rows(self) -> UInt:
        """Returns the number of rows in the table.

        Returns:
            The number of rows in the table.
        """
        return UInt(len(self._rows))

    fn columns(self) -> UInt:
        """Returns the number of columns in the table.

        Returns:
            The number of columns in the table.
        """
        return UInt(self._columns)

    fn add_row(mut self, var row: List[String]):
        """Appends the given row to the table.

        Args:
            row: The row to append.
        """
        self._columns = max(self._columns, UInt(len(row)))
        self._rows.append(row^)

    fn add_row(mut self, *elements: String):
        """Appends the given row to the table.

        Args:
            elements: The row to append.
        """
        self._columns = max(self._columns, UInt(len(elements)))
        var row = List[String](capacity=len(elements))
        for element in elements:
            row.append(element)
        self._rows.append(row^)

    fn add_rows(mut self, var rows: List[List[String]]):
        """Appends the given rows to the table.

        Args:
            rows: The rows to append.
        """
        for row in rows:
            self._columns = max(self._columns, UInt(len(row)))
            self._rows.append(row.copy())

    fn add_rows(mut self, *rows: List[String]):
        """Returns the style for a cell based on it's position (row, column).

        Args:
            rows: The rows to add to the table.
        """
        var widest: UInt = 0
        for row in rows:
            widest = max(widest, UInt(len(row)))
            self._rows.append(row.copy())
        self._columns = widest

    fn __add__(self, other: Self) -> Self:
        """Concatenates two Data instances.

        Args:
            other: The other Data instance to concatenate.

        Returns:
            The concatenated Data instance.
        """
        return Data(self._rows + other._rows.copy(), max(self.columns(), other.columns()))

    fn __iadd__(mut self, other: Self):
        """Concatenates two Data instances in place.

        Args:
            other: The other Data instance to concatenate.
        """
        self._rows.extend(other._rows.copy())
        self._columns = max(self.columns(), other.columns())
