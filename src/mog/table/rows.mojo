trait Data(Movable, Copyable, ExplicitlyCopyable):
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

    fn __init__(out self, rows: List[List[String]] = List[List[String]]()):
        """Initializes a new StringData instance.

        Args:
            rows: The rows of the table.
        """
        self._rows = rows
        self._columns = len(rows)
    
    fn __init__(out self, *rows: List[String]):
        """Initializes a new StringData instance.

        Args:
            rows: The rows of the table.
        """
        var widest = 0
        var r = List[List[String]](capacity=len(rows))
        for row in rows:
            widest = max(widest, len(row[]))
            r.append(row[])
        self._rows = r
        self._columns = widest

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
    
    fn append(mut self, *elements: String):
        """Appends the given row to the table.

        Args:
            elements: The row to append.
        """
        self._columns = max(self._columns, len(elements))
        var row = List[String](capacity=len(elements))
        for element in elements:
            row.append(element[])
        self._rows.append(row)
    
    fn __add__(self, other: Self) -> Self:
        """Concatenates two StringData instances.

        Args:
            other: The other StringData instance to concatenate.

        Returns:
            The concatenated StringData instance.
        """
        return StringData(self._rows + other._rows, max(self.columns(), other.columns()))
    
    fn __iadd__(mut self, other: Self):
        """Concatenates two StringData instances in place.

        Args:
            other: The other StringData instance to concatenate.
        """
        self._rows.extend(other._rows)
        self._columns = max(self.columns(), other.columns())


alias FilterFunction = fn (row: Int) -> Bool
"""Function type that filters rows based on a condition."""


@value
struct Filter[DataType: Data, //](Data):
    """Applies a filter function on some data.

    Parameters:
        DataType: The type of data to use for the table.
    """

    var data: DataType
    """The data of the table."""
    var filter: FilterFunction
    """The filter function to apply."""

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
