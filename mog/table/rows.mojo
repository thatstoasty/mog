"""A module for working with table data."""


struct Data[columns: Int](Copyable) where columns > 0:
    """Table data.

    #### Example Usage:
    ```mojo
    import mog

    def main():
        var data = mog.Data(
            ["Name", "Age"],
            ["My Name", "30"],
            ["Your Name", "25"],
            ["Their Name", "35"]
        )
        print(data[1, 0], data[1, 1])
    ```
    """

    comptime RowType = Array[String, Self.columns]
    var _rows: List[Self.RowType]
    """The rows of the table."""
    # var _columns: UInt
    # """The number of columns in the table."""

    def __init__(out self):
        """Initializes a new Data instance."""
        self._rows = List[Self.RowType]()

    def __init__(out self, var rows: List[Self.RowType]):
        """Initializes a new Data instance.

        Args:
            rows: The rows of the table.
        """
        self._rows = rows^

    def __getitem__(self, row: UInt, column: UInt) -> ref[self._rows[row][column]] String:
        """Returns the contents of the cell at the given index.

        Args:
            row: The row index.
            column: The column index.

        Returns:
            The contents of the cell at the given index.
        """
        return self._rows[row][column]
    
    def __len__(self) -> Int:
        return len(self._rows)

    def rows(self) -> UInt:
        """Returns the number of rows in the table.

        Returns:
            The number of rows in the table.
        """
        return UInt(len(self._rows))

    def append(mut self, var row: Self.RowType):
        """Appends the given row to the table.

        Args:
            row: The row to append.
        """
        self._rows.append(row^)

    def add_rows(mut self, var rows: List[Self.RowType]):
        """Appends the given rows to the table.

        Args:
            rows: The rows to append.
        """
        for var row in rows^:
            self._rows.append(row^)

    def __add__(self, deinit other: Self) -> Self:
        """Concatenates two Data instances.

        Args:
            other: The other Data instance to concatenate.

        Returns:
            The concatenated Data instance.
        """
        return Data(self._rows + other._rows^)

    def __iadd__(mut self, deinit other: Self):
        """Concatenates two Data instances in place.

        Args:
            other: The other Data instance to concatenate.
        """
        self._rows += other._rows^
