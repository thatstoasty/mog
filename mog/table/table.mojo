from mist import Profile
from mist.transform import truncate
from mog.border import ROUNDED_BORDER, Border
from mog.join import join_horizontal
from mog.position import Position
from mog.size import get_height, get_width
from mog.style import Style
from mog.table.rows import Data
from mog.table.util import largest, median, sum


alias StyleFn = fn (data: Data, row: Int, col: Int) -> Style
"""Styling function that determines the style of a Cell.

It takes the row and column of the cell as an input and determines the
lipgloss Style to use for that cell position.

#### Examples:
```mojo
import mog

fn styler(data: mog.Data, row: Int, col: Int) -> mog.Style:
    if row == 0:
        return mog.Style().bold()
    elif row % 2 == 0:
        return mog.Style().italic()
    else:
        return mog.Style().faint()

fn main():
    var t = mog.Table(
        headers=["Name", "Age"],
        data=mog.Data(
            ["Kini", "4"],
            ["Eli", "1"],
            ["Iris", "102"],
        ),
        style_function=styler
    )
    print(t)
```
"""


fn default_styles(data: Data, row: Int, col: Int) -> Style:
    """Returns a new Style with no attributes.

    Args:
        data: The data of the table.
        row: The row of the cell.
        col: The column of the cell.

    Returns:
        A new Style with no attributes.
    """
    return mog.Style()


# TODO: Parametrize on data field, so other structs that implement `Data` can be used. For now it only support `StringData`.
struct Table(Copyable, Movable, Stringable, Writable):
    """Used to model and render tabular data as a table.

    #### Examples:
    ```mojo
    import mog

    fn styler(data: mog.Data, row: Int, col: Int) -> mog.Style:
        if row == 0:
            return mog.Style().bold_text()
        elif row % 2 == 0:
            return mog.Style().italicize_text()
        else:
            return mog.Style().faint_text()

    fn main():
        var t = mog.Table(
            headers=["Name", "Age"],
            data=mog.Data(
                ["Kini", "4"],
                ["Eli", "1"],
                ["Iris", "102"],
            ),
            style_function=styler
        )
        print(t)
    ```
    """

    var _styler: StyleFn
    """The style function that determines the style of a cell. It returns a `mog.Style` for a given row and column position."""
    var _border: Border
    """The border style to use for the table."""
    var _border_top: Bool
    """Whether to render the top border of the table."""
    var _border_bottom: Bool
    """Whether to render the bottom border of the table."""
    var _border_left: Bool
    """Whether to render the left border of the table."""
    var _border_right: Bool
    """Whether to render the right border of the table."""
    var _border_header: Bool
    """Whether to render the header border of the table."""
    var _border_column: Bool
    """Whether to render the column border of the table."""
    var _border_row: Bool
    """Whether to render the row divider borders for each row of the table."""
    var _border_style: Style
    """The style to use for the border."""
    var _headers: List[String]
    """The headers of the table."""
    var data: Data
    """The data of the table."""
    var width: Int
    """The width of the table."""
    var height: Int
    """The height of the table."""
    var _offset: Int
    """The offset of the table."""

    fn __init__(
        out self,
        *,
        style_function: StyleFn = default_styles,
        border_style: Optional[Style] = None,
        border: Border = ROUNDED_BORDER,
        border_top: Bool = True,
        border_bottom: Bool = True,
        border_left: Bool = True,
        border_right: Bool = True,
        border_header: Bool = True,
        border_column: Bool = True,
        border_row: Bool = False,
        var headers: List[String] = List[String](),
        var data: Data = Data(),
        width: Int = 0,
        height: Int = 0,
    ):
        """Initializes a new Table.

        Args:
            style_function: The style function that determines the style of a cell.
            border_style: The style to use for the border.
            border: The border style to use for the table.
            border_top: Whether to render the top border of the table.
            border_bottom: Whether to render the bottom border of the table.
            border_left: Whether to render the left border of the table.
            border_right: Whether to render the right border of the table.
            border_header: Whether to render the header border of the table.
            border_column: Whether to render the column border of the table.
            border_row: Whether to render the row divider borders for each row of the table.
            headers: The headers of the table.
            data: The data of the table.
            width: The width of the table.
            height: The height of the table.
        """
        self._styler = style_function
        self._border = border.copy()
        self._border_style = border_style.value().copy() if border_style else mog.Style()
        self._border_top = border_top
        self._border_bottom = border_bottom
        self._border_left = border_left
        self._border_right = border_right
        self._border_header = border_header
        self._border_column = border_column
        self._border_row = border_row
        self._headers = headers^
        self.data = data^
        self.width = width
        self.height = height
        self._offset = 0

    fn __moveinit__(out self, deinit other: Self):
        """Initializes a new Table by moving the data from another Table.

        Args:
            other: The other Table to move the data from.
        """
        self._styler = other._styler
        self._border = other._border^
        self._border_style = other._border_style^
        self._border_top = other._border_top
        self._border_bottom = other._border_bottom
        self._border_left = other._border_left
        self._border_right = other._border_right
        self._border_header = other._border_header
        self._border_column = other._border_column
        self._border_row = other._border_row
        self._headers = other._headers^
        self.data = other.data^
        self.width = other.width
        self.height = other.height
        self._offset = other._offset

    fn copy(self) -> Self:
        """Returns a copy of the Table.

        Returns:
            A copy of the Table.
        """
        return Self(
            style_function=self._styler,
            border_style=self._border_style.copy(),
            border=self._border,
            border_top=self._border_top,
            border_bottom=self._border_bottom,
            border_left=self._border_left,
            border_right=self._border_right,
            border_header=self._border_header,
            border_column=self._border_column,
            border_row=self._border_row,
            headers=self._headers.copy(),
            data=self.data.copy(),
            width=self.width,
            height=self.height,
        )

    fn copy_without_data(self) -> Self:
        """Returns a copy of the Table with an empty Data attribute.

        Returns:
            A copy of the Table.
        """
        return Self(
            style_function=self._styler,
            border_style=self._border_style.copy(),
            border=self._border,
            border_top=self._border_top,
            border_bottom=self._border_bottom,
            border_left=self._border_left,
            border_right=self._border_right,
            border_header=self._border_header,
            border_column=self._border_column,
            border_row=self._border_row,
            headers=self._headers.copy(),
            data=Data(),
            width=self.width,
            height=self.height,
        )

    # @staticmethod
    # fn new() -> Self:
    #     """Returns a new Table, this is to bypass the compiler limitation on these args having default values.
    #     It seems like argument default values are handled at compile time, and mog Styles are not compile time constants,
    #     UNLESS a profile is specified ahead of time.

    #     Returns:
    #         A new Table.
    #     """
    #     return Table[styler=default_styles](border_style=mog.Style())

    fn clear_rows(self) -> Self:
        """Clears the table rows.

        Returns:
            The updated table.
        """
        return self.copy_without_data()

    fn style(self, row: Int, col: Int) -> Style:
        """Returns the style for a cell based on it's position (row, column).

        Args:
            row: The row of the cell.
            col: The column of the cell.

        Returns:
            The style for the cell.
        """
        return self._styler(self.data, row, col)

    # fn rows(self, *rows: List[String]) -> Self:
    #     """Returns the style for a cell based on it's position (row, column).

    #     Args:
    #         rows: The rows to add to the table.

    #     Returns:
    #         The updated table.
    #     """
    #     var new = self.copy()
    #     for i in range(len(rows)):
    #         new.data.append(rows[i].copy())
    #     return new^

    # fn rows(self, rows: List[List[String]]) -> Self:
    #     """Appends the data from `rows` to the table.

    #     Args:
    #         rows: The rows to add to the table.

    #     Returns:
    #         The updated table.
    #     """
    #     var new = self.copy()
    #     for row in rows:
    #         new.data.append(row.copy())
    #     return new^

    # fn row(self, *row: String) -> Self:
    #     """Appends a row to the table data.

    #     Args:
    #         row: The row to append to the table.

    #     Returns:
    #         The updated table.
    #     """
    #     var new = self.copy()
    #     var temp = List[String](capacity=len(row))
    #     for element in row:
    #         temp.append(element)
    #     new.data.append(temp^)
    #     return new^

    # fn row(self, var row: List[String]) -> Self:
    #     """Appends a row to the table data.

    #     Args:
    #         row: The row to append to the table.

    #     Returns:
    #         The updated table.
    #     """
    #     var new = self.copy()
    #     new.data.append(row^)
    #     return new^

    fn set_headers(self, *headers: String) -> Self:
        """Sets the table headers.

        Args:
            headers: The headers to set.

        Returns:
            The updated table.
        """
        var new = self.copy()
        var temp = List[String](capacity=len(headers))
        for element in headers:
            temp.append(element)
        new._headers = temp^
        return new^

    fn set_headers(self, var headers: List[String]) -> Self:
        """Sets the table headers.

        Args:
            headers: The headers to set.

        Returns:
            The updated table.
        """
        var new = self.copy()
        new._headers = headers^
        return new^

    # fn set_style(self, styler: StyleFunction) -> Self:
    #     """Sets the table headers.

    #     Args:
    #         styler: The style function to use.

    #     Returns:
    #         The updated table.
    #     """
    #     var new = self.copy()
    #     new._styler = styler
    #     return new^

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes the table to the writer.

        Parameters:
            W: The type of writer to write to.

        Args:
            writer: The writer to write to.
        """
        var has_headers = len(self._headers) > 0
        var has_rows = self.data.rows() > 0
        if not has_headers and not has_rows:
            return

        var result = String()
        # Add empty cells to the headers, until it's the same length as the longest
        # row (only if there are at headers in the first place).
        var headers = self._headers.copy()
        if has_headers:
            var i = len(headers)
            while i < self.data.columns():
                headers.append("")
                i += 1

        # Initialize the widths.
        var widths_len = max(len(self._headers), self.data.columns())
        var widths = List[Int](capacity=widths_len)
        for _ in range(widths_len):
            widths.append(0)

        # Initialize the heights.
        var heights_len = Int(has_headers) + self.data.rows()
        var heights = List[Int](capacity=heights_len)
        for _ in range(heights_len):
            heights.append(0)

        # The style function may affect width of the table. It's possible to set
        # the StyleFunction after the headers and rows. Update the widths for a final
        # time.
        for i in range(len(headers)):
            widths[i] = get_width(self.style(0, i).render(headers[i]))
            heights[0] = get_height(self.style(0, i).render(headers[i]))

        var row_number = 0
        while row_number < self.data.rows():
            var column_number = 0
            while column_number < self.data.columns():
                var rendered = self.style(row_number + 1, column_number).render(self.data[row_number, column_number])
                var row_number_with_header_offset = row_number + Int(has_headers)
                heights[row_number_with_header_offset] = max(
                    heights[row_number_with_header_offset],
                    get_height(rendered),
                )
                widths[column_number] = max(widths[column_number], get_width(rendered))

                column_number += 1
            row_number += 1

        # Table Resizing Logic.
        #
        # Given a user defined table width, we must ensure the table is exactly that
        # width. This must account for all borders, column, separators, and column
        # data.
        #
        # In the case where the table is narrower than the specified table width,
        # we simply expand the columns evenly to fit the width.
        # For example, a table with 3 columns takes up 50 characters total, and the
        # width specified is 80, we expand each column by 10 characters, adding 30
        # to the total width.
        #
        # In the case where the table is wider than the specified table width, we
        # _could_ simply shrink the columns evenly but this would result in data
        # being truncated (perhaps unnecessarily). The naive approach could result
        # in very poor cropping of the table data. So, instead of shrinking columns
        # evenly, we calculate the median non-whitespace length of each column, and
        # shrink the columns based on the largest median.
        #
        # For example,
        #  ┌──────┬───────────────┬──────────┐
        #  │ Name │ Age of Person │ Location │
        #  ├──────┼───────────────┼──────────┤
        #  │ Kini │ 40            │ New York │
        #  │ Eli  │ 30            │ London   │
        #  │ Iris │ 20            │ Paris    │
        #  └──────┴───────────────┴──────────┘
        #
        # Median non-whitespace length  vs column width of each column:
        #
        # Name: 4 / 5
        # Age of Person: 2 / 15
        # Location: 6 / 10
        #
        # The biggest difference is 15 - 2, so we can shrink the 2nd column by 13.
        var width = self._compute_width(widths)
        if width < self.width and self.width > 0:
            # Table is too narrow, expand the columns evenly until it reaches the
            # desired width.
            var i = 0
            while width < self.width:
                widths[i] += 1
                width += 1
                i = (i + 1) % len(widths)

        elif width > self.width and self.width > 0:
            # Table is too wide, calculate the median non-whitespace length of each
            # column, and shrink the columns based on the largest difference.
            var column_medians = List[Int](capacity=len(widths))
            for i in range(len(widths)):
                var trimmed_width = List[Int](capacity=self.data.rows())

                for r in range(self.data.rows()):
                    var rendered_cell = self.style(r + Int(has_headers), i).render(self.data[r, i])
                    var non_whitespace_chars = get_width(rendered_cell.removesuffix(" "))
                    trimmed_width[r] = non_whitespace_chars + 1

                column_medians[i] = median(trimmed_width)

            # Find the biggest differences between the median and the column width.
            # Shrink the columns based on the largest difference.
            var differences = List[Int](capacity=len(widths))
            for i in range(len(widths)):
                differences[i] = widths[i] - column_medians[i]

            while width > self.width:
                index, _ = largest(differences)
                if differences[index] < 1:
                    break

                var shrink = min(differences[index], width - self.width)
                widths[index] -= shrink
                width -= shrink
                differences[index] = 0

            # Table is still too wide, begin shrinking the columns based on the
            # largest column.
            while width > self.width:
                index, _ = largest(widths)
                if widths[index] < 1:
                    break

                widths[index] -= 1
                width -= 1

        if self._border_top:
            result.write(self._construct_top_border(widths), NEWLINE)

        if has_headers:
            result.write(self._construct_headers(widths, headers), NEWLINE)

        var r = self._offset
        while r < self.data.rows():
            result.write(self._construct_row(r, widths, heights, headers))
            r += 1

        if self._border_bottom:
            result.write(self._construct_bottom_border(widths))

        writer.write(
            mog.Style(Profile.ASCII, max_height=self._compute_height(heights), max_width=self.width).render(result)
        )

    fn __str__(self) -> String:
        """Returns the table as a String.

        Returns:
            The table as a string.
        """
        return String(self)

    fn _compute_width(self, widths: List[Int]) -> Int:
        """Computes the width of the table in it's current configuration.

        Args:
            widths: The widths of the columns.

        Returns:
            The width of the table.
        """
        var width = sum(widths) + Int(self._border_left) + Int(self._border_right)
        if self._border_column:
            width += len(widths) - 1

        return width

    fn _compute_height(self, heights: List[Int]) -> Int:
        """Computes the height of the table in it's current configuration.

        Args:
            heights: The heights of the rows.

        Returns:
            The height of the table.
        """
        return (
            sum(heights)
            - 1
            + Int(len(self._headers) > 0)
            + Int(self._border_top)
            + Int(self._border_bottom)
            + Int(self._border_header)
            + self.data.rows() * Int(self._border_row)
        )

    fn _construct_top_border(self, widths: List[Int]) -> String:
        """Constructs the top border for the table given it's current
        border configuration and data.

        Args:
            widths: The widths of the columns.

        Returns:
            The constructed top border as a string.
        """
        var result = String()
        if self._border_left:
            result.write(self._border_style.render(self._border.top_left))

        var i = 0
        while i < len(widths):
            result.write(self._border_style.render(self._border.top * widths[i]))
            if i < len(widths) - 1 and self._border_column:
                result.write(self._border_style.render(self._border.middle_top))
            i += 1

        if self._border_right:
            result.write(self._border_style.render(self._border.top_right))

        return result

    fn _construct_bottom_border(self, widths: List[Int]) -> String:
        """Constructs the bottom border for the table given it's current
        border configuration and data.

        Args:
            widths: The widths of the columns.

        Returns:
            The constructed bottom border as a string.
        """
        var result = String()
        if self._border_left:
            result.write(self._border_style.render(self._border.bottom_left))

        var i = 0
        while i < len(widths):
            result.write(self._border_style.render(self._border.bottom * widths[i]))
            if i < len(widths) - 1 and self._border_column:
                result.write(self._border_style.render(self._border.middle_bottom))
            i += 1

        if self._border_right:
            result.write(self._border_style.render(self._border.bottom_right))

        return result

    fn _construct_headers(self, widths: List[Int], headers: List[String]) -> String:
        """Constructs the headers for the table given it's current
        header configuration and data.

        Args:
            widths: The widths of the columns.
            headers: The headers of the table.

        Returns:
            The constructed headers as a string.
        """
        var result = String()
        if self._border_left:
            result.write(self._border_style.render(self._border.left))

        for i in range(len(headers)):
            var style = self.style(0, i).set_max_height(1).set_width(widths[i]).set_max_width(widths[i])

            result.write(style.render(truncate(headers[i], widths[i], "…")))
            if (i < len(headers) - 1) and (self._border_column):
                result.write(self._border_style.render(self._border.left))

        if self._border_header:
            if self._border_right:
                result.write(self._border_style.render(self._border.right))

            result.write("\n")
            if self._border_left:
                result.write(self._border_style.render(self._border.middle_left))

            var i = 0
            while i < len(headers):
                result.write(self._border_style.render(self._border.bottom * widths[i]))
                if i < len(headers) - 1 and self._border_column:
                    result.write(self._border_style.render(self._border.middle))

                i += 1

            if self._border_right:
                result.write(self._border_style.render(self._border.middle_right))

        if self._border_right and not self._border_header:
            result.write(self._border_style.render(self._border.right))

        return result

    fn _construct_row(self, index: Int, widths: List[Int], heights: List[Int], headers: List[String]) -> String:
        """Constructs the row for the table given an index and row data
        based on the current configuration.

        Args:
            index: The index of the row to construct.
            widths: The widths of the columns.
            heights: The heights of the rows.
            headers: The headers of the table.

        Returns:
            The constructed row as a string.
        """
        var result = String()

        var has_headers = len(headers) > 0
        var height = heights[index + Int(has_headers)]

        var cells = List[String]()
        var left = (self._border_style.render(self._border.left) + "\n") * height
        if self._border_left:
            cells.append(left)

        var c = 0
        while c < self.data.columns():
            var style = self.style(index + 1, c).set_height(height).set_max_height(height).set_width(widths[c]).set_max_width(widths[c])
            cells.append(style.render(truncate(self.data[index, c], widths[c] * height, "…")))
            if c < self.data.columns() - 1 and self._border_column:
                cells.append(left)

            c += 1

        if self._border_right:
            cells.append((self._border_style.render(self._border.right) + "\n") * height)

        # TODO: removesuffix doesn't seem to work with all utf8 chars, maybe it'll be fixed upstream soon.
        # It wasn't recognizing the last character as a newline.
        for ref cell in cells:
            if cell[-1] == "\n":
                cell = cell[:-1]

        result.write(join_horizontal(Position.TOP, cells), "\n")

        if self._border_row and index < self.data.rows() - 1:
            result.write(self._border_style.render(self._border.middle_left))
            var i = 0
            while i < len(widths):
                result.write(self._border_style.render(self._border.middle * widths[i]))
                if i < len(widths) - 1 and self._border_column:
                    result.write(self._border_style.render(self._border.middle))

                i += 1
            result.write(self._border_style.render(self._border.middle_right) + "\n")

        return result
