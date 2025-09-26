# trait Data(Copyable, Movable):
#     """Trait that wraps the basic methods of a table model."""

#     fn __init__(out self):
#         """Initializes a new Data instance."""
#         ...

#     # TODO: Need to figure out if I want this to return an optional or just raise.
#     # Also it should return a ref to the data, not a copy. When traits support attributes.
#     fn __getitem__(self, row: Int, column: Int) -> String:
#         """Returns the contents of the cell at the given index.

#         Args:
#             row: The row index.
#             column: The column index.

#         Returns:
#             The contents of the cell at the given index.
#         """
#         ...

#     fn rows(self) -> Int:
#         """Returns the number of rows in the table.

#         Returns:
#             The number of rows in the table.
#         """
#         ...

#     fn columns(self) -> Int:
#         """Returns the number of columns in the table.

#         Returns:
#             The number of columns in the table.
#         """
#         ...


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
    var _columns: Int
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
        self._columns = len(self._rows)

    fn __init__(out self, *rows: List[String]):
        """Initializes a new Data instance.

        Args:
            rows: The rows of the table.
        """
        var widest = 0
        var r = List[List[String]](capacity=len(rows))
        for row in rows:
            widest = max(widest, len(row))
            r.append(row.copy())
        self._rows = r^
        self._columns = widest

    # TODO: Can't return ref String because it depends on the origin of a struct attribute
    # and Traits do not support variables yet.
    fn __getitem__(self, row: Int, column: Int) -> ref [self._rows[row][column]] String:
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

    fn add_row(mut self, var row: List[String]):
        """Appends the given row to the table.

        Args:
            row: The row to append.
        """
        self._columns = max(self._columns, len(row))
        self._rows.append(row^)

    fn add_row(mut self, *elements: String):
        """Appends the given row to the table.

        Args:
            elements: The row to append.
        """
        self._columns = max(self._columns, len(elements))
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
            self._columns = max(self._columns, len(row))
            self._rows.append(row.copy())

    fn add_rows(mut self, *rows: List[String]):
        """Returns the style for a cell based on it's position (row, column).

        Args:
            rows: The rows to add to the table.
        """
        var widest = 0
        for row in rows:
            widest = max(widest, len(row))
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


# alias FilterFn = fn (row: Int) -> Bool
# """Function type that filters rows based on a condition."""


# @fieldwise_init
# struct FilteredData[T: Data, //](Data):
#     """Applies a filter function on some data.

#     Parameters:
#         T: The type of data to use for the table.
#     """

#     var data: T
#     """The data of the table."""
#     var filter: Optional[FilterFn]
#     """The filter function to apply."""

#     fn __init__(out self):
#         """Initializes a new FilteredData instance."""
#         self.data = T()
#         self.filter = None

#     fn __getitem__(self, row: Int, column: Int) -> String:
#         """Returns the contents of the cell at the given index.

#         Args:
#             row: The row index.
#             column: The column index.

#         Returns:
#             The contents of the cell at the given index.
#         """
#         var j = 0
#         var i = 0
#         while i < self.data.rows():
#             if self.filter and self.filter.value()(i):
#                 if j == row:
#                     return self.data[i, column]

#                 j += 1
#             i += 1

#         return ""

#     fn columns(self) -> Int:
#         """Returns the number of columns in the table.

#         Returns:
#             The number of columns in the table.
#         """
#         return self.data.columns()

#     fn rows(self) -> Int:
#         """Returns the number of rows in the table.

#         Returns:
#             The number of rows in the table.
#         """
#         var j = 0
#         var i = 0
#         while i < self.data.rows():
#             if self.filter and self.filter.value()(i):
#                 j += 1
#             i += 1

#         return j
