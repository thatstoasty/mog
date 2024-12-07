from weave import truncate
from ..style import Style
from ..border import ROUNDED_BORDER, Border
from ..join import join_horizontal
from ..size import get_height, get_width
from ..position import Position
from .rows import StringData
from .util import median, largest, sum


alias StyleFunction = fn (row: Int, col: Int) -> Style
"""
StyleFunction is the style fntion that determines the style of a Cell.

It takes the row and column of the cell as an input and determines the
lipgloss Style to use for that cell position.

Example Usage:

```
import mog

fn main():
    var header_style =  mog.Style().bold()
    var even_row_style = mog.Style().italic()
    var odd_row_style = mog.Style().faint()

    fn styler(row: Int, col: Int) -> mog.Style:
        if row == 0:
            return header_style
        elif row%2 == 0:
            return even_row_style
        else:
            return odd_row_style

    var t = mog.new_table().
    set_headers("Name", "Age").
    row("Kini", "4").
    row("Eli", "1").
    row("Iris", "102").
    style_function(styler)

    print(t)
```
.
"""


fn default_styles(row: Int, col: Int) -> Style:
    """Returns a new Style with no attributes.

    Args:
        row: The row of the cell.
        col: The column of the cell.

    Returns:
        A new Style with no attributes.
    """
    return mog.Style()


# TODO: Parametrize on data field, so other structs that implement `Data` can be used. For now it only support `StringData`.
@value
struct Table:
    """Used to model and render tabular data as a table.

    Examples:
    ```
    import mog

    fn main():
        var header_style =  mog.Style().bold()
        var even_row_style = mog.Style().italic()
        var odd_row_style = mog.Style().faint()

        fn styler(row: Int, col: Int) -> mog.Style:
            if row == 0:
                return header_style
            elif row%2 == 0:
                return even_row_style
            else:
                return odd_row_style

        var t = mog.new_table().
        set_headers("Name", "Age").
        row("Kini", "4").
        row("Eli", "1").
        row("Iris", "102").
        style_function(styler)

        print(t)
    ```
    .
    """

    var style_function: StyleFunction
    """The style function that determines the style of a cell. It returns a `mog.Style` for a given row and column position."""
    var border: Border
    """The border style to use for the table."""
    var border_top: Bool
    """Whether to render the top border of the table."""
    var border_bottom: Bool
    """Whether to render the bottom border of the table."""
    var border_left: Bool
    """Whether to render the left border of the table."""
    var border_right: Bool
    """Whether to render the right border of the table."""
    var border_header: Bool
    """Whether to render the header border of the table."""
    var border_column: Bool
    """Whether to render the column border of the table."""
    var border_row: Bool
    """Whether to render the row divider borders for each row of the table."""
    var border_style: Style
    """The style to use for the border."""
    var headers: List[String]
    """The headers of the table."""
    var data: StringData
    """The data of the table."""
    var width: Int
    """The width of the table."""
    var height: Int
    """The height of the table."""
    var offset: Int
    """The offset of the table."""
    var widths: List[Int]
    """Tracks the width of each column."""
    var heights: List[Int]
    """Tracks the height of each row."""

    fn __init__(
        out self,
        style_function: StyleFunction,
        border_style: Style,
        border: Border = ROUNDED_BORDER,
        border_top: Bool = True,
        border_bottom: Bool = True,
        border_left: Bool = True,
        border_right: Bool = True,
        border_header: Bool = True,
        border_column: Bool = True,
        border_row: Bool = False,
        headers: List[String] = List[String](),
        data: StringData = StringData(),
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
        self.style_function = style_function
        self.border = border
        self.border_style = border_style
        self.border_top = border_top
        self.border_bottom = border_bottom
        self.border_left = border_left
        self.border_right = border_right
        self.border_header = border_header
        self.border_column = border_column
        self.border_row = border_row
        self.headers = headers
        self.data = data
        self.width = width
        self.height = height
        self.offset = 0
        self.widths = List[Int]()
        self.heights = List[Int]()

    fn clear_rows(self) -> Table:
        """Clears the table rows.
        
        Returns:
            The updated table.
        """
        var new = self
        new.data = StringData()
        return new

    fn style(self, row: Int, col: Int) -> Style:
        """Returns the style for a cell based on it's position (row, column).

        Args:
            row: The row of the cell.
            col: The column of the cell.

        Returns:
            The style for the cell.
        """
        return self.style_function(row, col)

    fn rows(self, *rows: List[String]) -> Table:
        """Returns the style for a cell based on it's position (row, column).

        Args:
            rows: The rows to add to the table.
        
        Returns:
            The updated table.
        """
        var new = self
        for i in range(len(rows)):
            new.data.append(rows[i])
        return new

    fn rows(self, rows: List[List[String]]) -> Table:
        """Appends the data from `rows` to the table.

        Args:
            rows: The rows to add to the table.
        
        Returns:
            The updated table.
        """
        var new = self
        for row in rows:
            new.data.append(row[])
        return new

    fn row(self, *row: String) -> Table:
        """Appends a row to the table data.

        Args:
            row: The row to append to the table.
        
        Returns:
            The updated table.
        """
        var new = self
        var temp = List[String](capacity=len(row))
        for element in row:
            temp.append(element[])
        new.data.append(temp)
        return new

    fn row(self, row: List[String]) -> Table:
        """Appends a row to the table data.

        Args:
            row: The row to append to the table.
        
        Returns:
            The updated table.
        """
        var new = self
        new.data.append(row)
        return new

    fn set_headers(self, *headers: String) -> Table:
        """Sets the table headers.

        Args:
            headers: The headers to set.
        
        Returns:
            The updated table.
        """
        var new = self
        var temp = List[String]()
        for element in headers:
            temp.append(element[])
        new.headers = temp
        return new

    fn set_headers(self, headers: List[String]) -> Table:
        """Sets the table headers.

        Args:
            headers: The headers to set.
        
        Returns:
            The updated table.
        """
        var new = self
        new.headers = headers
        return new

    fn __str__(inout self) -> String:
        """Returns the table as a String.
        
        Returns:
            The table as a string.
        """
        var has_headers = len(self.headers) > 0
        var has_rows = self.data.rows() > 0

        if not has_headers and not has_rows:
            return ""

        var result = String()

        # Add empty cells to the headers, until it's the same length as the longest
        # row (only if there are at headers in the first place).
        if has_headers:
            var i = len(self.headers)
            while i < self.data.columns():
                self.headers.append("")
                i += 1

        # Initialize the widths.
        var widths_len = max(len(self.headers), self.data.columns())
        self.widths = List[Int](capacity=widths_len)
        for _ in range(widths_len):
            self.widths.append(0)

        var heights_len = int(has_headers) + self.data.rows()
        self.heights = List[Int](capacity=heights_len)
        for _ in range(heights_len):
            self.heights.append(0)

        # The style function may affect width of the table. It's possible to set
        # the StyleFunction after the headers and rows. Update the widths for a final
        # time.
        for i in range(len(self.headers)):
            self.widths[i] = get_width(self.style(0, i).render(self.headers[i]))
            self.heights[0] = get_height(self.style(0, i).render(self.headers[i]))

        var row_number = 0
        while row_number < self.data.rows():
            var column_number = 0
            while column_number < self.data.columns():
                var cell = self.data.at(row_number, column_number)
                var row_number_with_header_offset = row_number + int(has_headers)
                var rendered = self.style(row_number + 1, column_number).render(cell)

                self.heights[row_number_with_header_offset] = max(
                    self.heights[row_number_with_header_offset],
                    get_height(rendered),
                )
                self.widths[column_number] = max(self.widths[column_number], get_width(rendered))

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

        var width = self.compute_width()

        if width < self.width and self.width > 0:
            # Table is too narrow, expand the columns evenly until it reaches the
            # desired width.
            var i: Int = 0
            while width < self.width:
                self.widths[i] += 1
                width += 1
                i = (i + 1) % len(self.widths)

        elif width > self.width and self.width > 0:
            # Table is too wide, calculate the median non-whitespace length of each
            # column, and shrink the columns based on the largest difference.
            var column_medians = List[Int](capacity=len(self.widths))
            for i in range(len(self.widths)):
                var trimmed_width = List[Int](capacity=self.data.rows())

                for r in range(self.data.rows()):
                    var rendered_cell = self.style(r + int(has_headers), i).render(self.data.at(r, i))
                    var non_whitespace_chars = get_width(rendered_cell.removesuffix(" "))
                    trimmed_width[r] = non_whitespace_chars + 1

                column_medians[i] = median(trimmed_width)

            # Find the biggest differences between the median and the column width.
            # Shrink the columns based on the largest difference.
            var differences = List[Int](capacity=len(self.widths))
            for i in range(len(self.widths)):
                differences[i] = self.widths[i] - column_medians[i]

            while width > self.width:
                var index: Int = 0
                var val: Int = 0
                index, val = largest(differences)
                if differences[index] < 1:
                    break

                var shrink = min(differences[index], width - self.width)
                self.widths[index] -= shrink
                width -= shrink
                differences[index] = 0

            # Table is still too wide, begin shrinking the columns based on the
            # largest column.
            while width > self.width:
                var index: Int = 0
                var val: Int = 0
                index, val = largest(self.widths)
                if self.widths[index] < 1:
                    break

                self.widths[index] -= 1
                width -= 1

        if self.border_top:
            result.write(self.construct_top_border(), NEWLINE)

        if has_headers:
            result.write(self.construct_headers(), NEWLINE)

        var r = self.offset
        while r < self.data.rows():
            result.write(self.construct_row(r))
            r += 1

        if self.border_bottom:
            result.write(self.construct_bottom_border())

        return mog.Style().max_height(self.compute_height()).max_width(self.width).render(result)

    fn compute_width(self) -> Int:
        """Computes the width of the table in it's current configuration.

        Returns:
            The width of the table.
        """
        var width = sum(self.widths) + int(self.border_left) + int(self.border_right)
        if self.border_column:
            width += len(self.widths) - 1

        return width

    fn compute_height(self) -> Int:
        """Computes the height of the table in it's current configuration.

        Returns:
            The height of the table.
        """
        var has_headers = len(self.headers) > 0
        return (
            sum(self.heights)
            - 1
            + int(has_headers)
            + int(self.border_top)
            + int(self.border_bottom)
            + int(self.border_header)
            + self.data.rows() * int(self.border_row)
        )

    # render
    fn render(inout self) -> String:
        """Returns the table as a String.

        Returns:
            The table as a string.
        """
        return self.__str__()

    fn construct_top_border(self) -> String:
        """Constructs the top border for the table given it's current
        border configuration and data.

        Returns:
            The constructed top border as a string.
        """
        var result = String()
        if self.border_left:
            result.write(self.border_style.render(self.border.top_left))

        var i: Int = 0
        while i < len(self.widths):
            result.write(self.border_style.render(self.border.top * self.widths[i]))
            if i < len(self.widths) - 1 and self.border_column:
                result.write(self.border_style.render(self.border.middle_top))
            i += 1

        if self.border_right:
            result.write(self.border_style.render(self.border.top_right))

        return result

    fn construct_bottom_border(self) -> String:
        """Constructs the bottom border for the table given it's current
        border configuration and data.

        Returns:
            The constructed bottom border as a string.
        """
        var result = String()
        if self.border_left:
            result.write(self.border_style.render(self.border.bottom_left))

        var i: Int = 0
        while i < len(self.widths):
            result.write(self.border_style.render(self.border.bottom * self.widths[i]))
            if i < len(self.widths) - 1 and self.border_column:
                result.write(self.border_style.render(self.border.middle_bottom))

            i += 1

        if self.border_right:
            result.write(self.border_style.render(self.border.bottom_right))

        return result

    fn construct_headers(self) -> String:
        """Constructs the headers for the table given it's current
        header configuration and data.

        Returns:
            The constructed headers as a string.
        """
        var result = String()
        if self.border_left:
            result.write(self.border_style.render(self.border.left))

        for i in range(len(self.headers)):
            var header = self.headers[i]
            var style = self.style(0, i).max_height(1).width(self.widths[i]).max_width(self.widths[i])

            result.write(style.render(truncate(header, self.widths[i], "…")))

            if (i < len(self.headers) - 1) and (self.border_column):
                result.write(self.border_style.render(self.border.left))

        if self.border_header:
            if self.border_right:
                result.write(self.border_style.render(self.border.right))

            result.write("\n")
            if self.border_left:
                result.write(self.border_style.render(self.border.middle_left))

            var i: Int = 0
            while i < len(self.headers):
                result.write(self.border_style.render(self.border.bottom * self.widths[i]))
                if i < len(self.headers) - 1 and self.border_column:
                    result.write(self.border_style.render(self.border.middle))

                i += 1

            if self.border_right:
                result.write(self.border_style.render(self.border.middle_right))

        if self.border_right and not self.border_header:
            result.write(self.border_style.render(self.border.right))

        return result

    fn construct_row(self, index: Int) -> String:
        """Constructs the row for the table given an index and row data
        based on the current configuration.

        Args:
            index: The index of the row to construct.

        Returns:
            The constructed row as a string.
        """
        var result = String()

        var has_headers = len(self.headers) > 0
        var height = self.heights[index + int(has_headers)]

        var cells = List[String]()
        var left = (self.border_style.render(self.border.left) + "\n") * height
        if self.border_left:
            cells.append(left)

        var c = 0
        while c < self.data.columns():
            var cell = self.data.at(index, c)
            var style = self.style(index + 1, c).
            height(height).
            max_height(height).
            width(self.widths[c]).
            max_width(self.widths[c])

            cells.append(style.render(truncate(cell, self.widths[c] * height, "…")))

            if c < self.data.columns() - 1 and self.border_column:
                cells.append(left)

            c += 1

        if self.border_right:
            var right = (self.border_style.render(self.border.right) + "\n") * height
            cells.append(right)

        for i in range(len(cells)):
            var cell = cells[i]
            cells[i] = cell.removesuffix("\n")

        result.write(join_horizontal(position.top, cells) + "\n")

        if self.border_row and index < self.data.rows() - 1:
            result.write(self.border_style.render(self.border.middle_left))
            var i = 0
            while i < len(self.widths):
                result.write(self.border_style.render(self.border.middle * self.widths[i]))
                if i < len(self.widths) - 1 and self.border_column:
                    result.write(self.border_style.render(self.border.middle))

                i += 1
            result.write(self.border_style.render(self.border.middle_right) + "\n")

        return result


fn new_table() -> Table:
    """Returns a new Table, this is to bypass the compiler limitation on these args having default values.
    It seems like argument default values are handled at compile time, and mog Styles are not compile time constants,
    UNLESS a profile is specified ahead of time.

    Returns:
        A new Table.
    """
    return Table(style_function=default_styles, border_style=mog.Style())
