"""A module for rendering tables in the terminal."""

from mist import Profile
from mist.transform import truncate
from mist.transform.ansi import printable_rune_width
from mog.border import ROUNDED_BORDER, Border
from mog.join import join_horizontal
from mog.position import Position
from mog.size import get_height, get_width
from mog.style import Style
from mog.table.rows import Data
from mog.table.util import largest, median, sum
from mog._extensions import DEFAULT_BUFFER_SIZE, SMALL_BUFFER_SIZE, NEWLINE


comptime StyleFn[columns: Int] where columns > 0 = def(data: Data[columns], row: UInt, col: UInt) thin -> Style
"""Styling function that determines the style of a Cell.

It takes the row and column of the cell as an input and determines the
lipgloss Style to use for that cell position.

#### Examples:
```mojo
import mog
from mog import Emphasis

def styler[columns: Int](data: mog.Data[columns], row: UInt, col: UInt) -> mog.Style
    where columns > 0:
    if row == 0:
        return mog.Style(emphasis=Emphasis.BOLD)
    elif row % 2 == 0:
        return mog.Style(emphasis=Emphasis.ITALIC)
    else:
        return mog.Style(emphasis=Emphasis.FAINT)

def main():
    var t = mog.Table(
        headers=["Name", "Age"],
        data=mog.Data([
            ["Kini", "4"],
            ["Eli", "1"],
            ["Iris", "102"],
        ]),
        style_function=styler
    )
    print(t)
```
"""


def default_styles[columns: Int](data: Data[columns], row: UInt, col: UInt) -> Style
    where columns > 0:
    """Returns a new Style with no attributes.

    Args:
        data: The data of the table.
        row: The row of the cell.
        col: The column of the cell.

    Returns:
        A new Style with no attributes.
    """
    return Style()


# TODO: Parametrize on data field, so other structs that implement `Data` can be used. For now it only support `StringData`.
struct Table[columns: Int](Copyable, Writable) where columns > 0:
    """Used to model and render tabular data as a table.

    Parameters:
        columns: Column count. Must be greater than 0.

    #### Examples:
    ```mojo
    import mog
    from mog import Emphasis

    def styler[columns: Int](data: mog.Data[columns], row: UInt, col: UInt) -> mog.Style
        where columns > 0:
        if row == 0:
            return mog.Style(emphasis=Emphasis.BOLD)
        elif row % 2 == 0:
            return mog.Style(emphasis=Emphasis.ITALIC)
        else:
            return mog.Style(emphasis=Emphasis.FAINT)

    def main():
        var t = mog.Table(
            headers=["Name", "Age"],
            data=mog.Data([
                ["Kini", "4"],
                ["Eli", "1"],
                ["Iris", "102"],
            ]),
            style_function=styler
        )
        print(t)
    ```
    """

    comptime column_count = UInt(Self.columns)
    """Column count, but as a UInt."""
    comptime DataType = Data[Self.columns]
    var _styler: StyleFn[Self.columns]
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
    var data: Data[Self.columns]
    """The data of the table."""
    var _headers: Optional[Array[String, Self.columns]] 
    """The headers of the table."""
    var width: UInt16
    """The width of the table."""
    var height: UInt16
    """The height of the table."""
    var _offset: UInt
    """The offset of the table."""

    def __init__(
        out self,
        *,
        style_function: StyleFn[Self.columns] = default_styles[Self.columns],
        border_style: Optional[Style] = None,
        border: Border = ROUNDED_BORDER,
        border_top: Bool = True,
        border_bottom: Bool = True,
        border_left: Bool = True,
        border_right: Bool = True,
        border_header: Bool = True,
        border_column: Bool = True,
        border_row: Bool = False,
        var headers: Array[String, Self.columns] = None,
        var data: Self.DataType = {},
        width: UInt16 = 0,
        height: UInt16 = 0,
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
        self._border_style = border_style.value().copy() if border_style else Style()
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

    # TODO: Duplicate init without headers field bc Mojo can't infer Self.columns on an optional
    # even though data uses the same parameter.
    def __init__(
        out self,
        *,
        style_function: StyleFn[Self.columns] = default_styles[Self.columns],
        border_style: Optional[Style] = None,
        border: Border = ROUNDED_BORDER,
        border_top: Bool = True,
        border_bottom: Bool = True,
        border_left: Bool = True,
        border_right: Bool = True,
        border_header: Bool = True,
        border_column: Bool = True,
        border_row: Bool = False,
        var data: Self.DataType = {},
        width: UInt16 = 0,
        height: UInt16 = 0,
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
            data: The data of the table.
            width: The width of the table.
            height: The height of the table.
        """
        self._styler = style_function
        self._border = border.copy()
        self._border_style = border_style.value().copy() if border_style else Style()
        self._border_top = border_top
        self._border_bottom = border_bottom
        self._border_left = border_left
        self._border_right = border_right
        self._border_header = border_header
        self._border_column = border_column
        self._border_row = border_row
        self._headers = None
        self.data = data^
        self.width = width
        self.height = height
        self._offset = 0

    def copy(self) -> Self:
        """Returns a copy of the Table.

        Returns:
            A copy of the Table.
        """
        if self._headers:
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
                headers=self._headers.value().copy(),
                data=self.data.copy(),
                width=self.width,
                height=self.height,
            )
        else:
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
                data=self.data.copy(),
                width=self.width,
                height=self.height,
            )

    def copy_without_data(self) -> Self:
        """Returns a copy of the Table with an empty Data attribute.

        Returns:
            A copy of the Table.
        """
        if self._headers:
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
                headers=self._headers.value().copy(),
                data=Self.DataType(),
                width=self.width,
                height=self.height,
            )
        else:
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
                data=Self.DataType(),
                width=self.width,
                height=self.height,
            )

    def clear_rows(self) -> Self:
        """Clears the table rows.

        Returns:
            The updated table.
        """
        return self.copy_without_data()

    def style(self, col: UInt, row: UInt) -> Style:
        """Returns the style for a cell based on it's position (row, column).

        Args:
            col: The column of the cell.
            row: The row of the cell.

        Returns:
            The style for the cell.
        """
        return self._styler(self.data, row, col)

    def set_headers(self, var headers: Array[String, Self.columns]) -> Self:
        """Sets the table headers.

        Args:
            headers: The headers to set.

        Returns:
            The updated table.
        """
        var new = self.copy()
        new._headers = headers^
        return new^
    
    def headers_length(self) -> Int:
        if self._headers:
            return len(self._headers.value())
        return 0

    def write_to(self, mut writer: Some[Writer]):
        """Writes the table to the writer.

        Args:
            writer: The writer to write to.
        """
        var header_offset = UInt(self._headers is not None)
        var row_count = UInt(len(self.data))
        if header_offset == 0 and row_count == 0:
            return

        var result = String(capacity=DEFAULT_BUFFER_SIZE)

        # Initialize the widths.
        var widths = Array[UInt16, Self.columns](fill=0)

        # Initialize the heights.
        var heights = List[UInt16](length=Int(header_offset + row_count), fill=0)

        # The style function may affect width of the table. It's possible to set
        # the StyleFunction after the headers and rows. Update the widths for a final
        # time.
        if self._headers:
            for i in range(Self.column_count):
                var header = self.style(i, 0).render(self._headers.unsafe_value()[i])
                widths[i] = get_width(header)
                heights[0] = get_height(header)

        for row in range(row_count):
            comptime for col in range(Self.column_count):
                var rendered = self.style(col, row + 1).render(self.data[col, row])
                var row_with_header_offset = row + header_offset
                heights[row_with_header_offset] = max(
                    heights[row_with_header_offset],
                    get_height(rendered),
                )
                widths[col] = max(widths[col], get_width(rendered))

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
        var target = UInt(self.width)
        if width < target and target > 0:
            # Table is too narrow, expand the columns evenly until it reaches the
            # desired width.
            var i = 0
            while width < target:
                widths[i] += 1
                width += 1
                i = (i + 1) % Self.columns

        elif width > target and target > 0:
            # Table is too wide, calculate the median non-whitespace length of each
            # column, and shrink the columns based on the largest difference.
            var column_medians = Array[UInt16, Self.columns](fill=0)
            comptime for i in range(Self.column_count):
                var trimmed_width = List[UInt16](capacity=Int(row_count))

                for r in range(row_count):
                    var rendered_cell = self.style(i, r + header_offset).render(self.data[i, r])
                    var non_whitespace_chars = get_width(rendered_cell.removesuffix(" "))
                    trimmed_width.append(non_whitespace_chars + 1)

                column_medians[i] = median(trimmed_width)

            # Find the biggest differences between the median and the column width.
            # Shrink the columns based on the largest difference.
            var differences = Array[UInt16, Self.columns](fill=0)
            comptime for i in range(Self.columns):
                if widths[i] > column_medians[i]:
                    differences[i] = widths[i] - column_medians[i]

            while width > target:
                var index, _ = largest(differences)
                if differences[index] < 1:
                    break

                var shrink = min(min(UInt(differences[index]), width - target), UInt(widths[index]))
                widths[index] -= UInt16(shrink)
                width -= shrink
                differences[index] = 0

            # Table is still too wide, begin shrinking the columns based on the
            # largest column.
            while width > target:
                var index, _ = largest(widths)
                # Stop before zeroing a column: a zero-width column still renders a cell's
                # worth of content, so the table would end up wider than `width` claims.
                # Leaving it at 1 lets the loop exit wide, which triggers the truncation
                # backstop below.
                if widths[index] <= 1:
                    break

                widths[index] -= 1
                width -= 1

        if self._border_top:
            result.write(self._construct_top_border(widths), NEWLINE)

        if header_offset > 0:
            result.write(self._construct_headers(widths, self._headers.value()), NEWLINE)

        for row in range(self._offset, row_count):
            result.write(self._construct_row(row, widths, heights, self._headers))

        if self._border_bottom:
            result.write(self._construct_bottom_border(widths))

        var height = Int(self._compute_height(heights))

        # The resize logic above already fits the columns to `self.width`, except when it
        # bails out early because no column can give up any more cells. That is the only
        # case needing a table-wide truncation, and the only case where the full `Style`
        # pass earns its cost.
        if target > 0 and width > target:
            Style(Profile.ASCII, max_height=height, max_width=Int(self.width)).render(result, writer=writer)
            return

        # Otherwise every row was built to a common width, so the height rule is all that
        # is left to enforce. Going through `Style` for that would re-align and re-style
        # every line to no effect, so slice the lines directly instead.
        var lines = result.splitlines()

        @parameter
        def rows_are_uniform() -> Bool:
            if len(lines) == 0:
                return True

            var expected = get_width(lines[0])
            for i in range(1, len(lines)):
                if get_width(lines[i]) != expected:
                    return False
            return True

        debug_assert[rows_are_uniform]("table rows should all be rendered to the same width")

        if len(lines) > height:
            writer.write(NEWLINE.join(lines[0:height]))
        else:
            writer.write(result)

    def _compute_width(self, widths: Array[UInt16, Self.columns]) -> UInt:
        """Computes the width of the table in it's current configuration.

        Args:
            widths: The widths of the columns.

        Returns:
            The width of the table.
        """
        var width = sum(widths) + UInt(self._border_left) + UInt(self._border_right)
        if self._border_column:
            width += UInt(Self.columns - 1)

        return width

    def _compute_height(self, heights: List[UInt16]) -> UInt:
        """Computes the height of the table in it's current configuration.

        Args:
            heights: The heights of the rows.

        Returns:
            The height of the table.
        """
        return (
            sum(heights)
            - 1
            + UInt(self.headers_length() > 0)
            + UInt(self._border_top)
            + UInt(self._border_bottom)
            + UInt(self._border_header)
            + UInt(len(self.data)) * UInt(self._border_row)
        )

    def _construct_top_border(self, widths: Array[UInt16, Self.columns]) -> String:
        """Constructs the top border for the table given it's current
        border configuration and data.

        Args:
            widths: The widths of the columns.

        Returns:
            The constructed top border as a string.
        """
        var result = String(capacity=SMALL_BUFFER_SIZE)
        if self._border_left:
            self._border_style.render(self._border.top_left, writer=result)

        comptime for col in range(Self.columns):
            self._border_style.render(self._border.top * Int(widths[col]), writer=result)
            if col < Self.columns - 1 and self._border_column:
                self._border_style.render(self._border.middle_top, writer=result)

        if self._border_right:
            self._border_style.render(self._border.top_right, writer=result)

        return result^

    def _construct_bottom_border(self, widths: Array[UInt16, Self.columns]) -> String:
        """Constructs the bottom border for the table given it's current
        border configuration and data.

        Args:
            widths: The widths of the columns.

        Returns:
            The constructed bottom border as a string.
        """
        var result = String(capacity=SMALL_BUFFER_SIZE)
        if self._border_left:
            self._border_style.render(self._border.bottom_left, writer=result)

        comptime for col in range(Self.columns):
            self._border_style.render(self._border.bottom * Int(widths[col]), writer=result)
            if col < Self.columns - 1 and self._border_column:
                self._border_style.render(self._border.middle_bottom, writer=result)

        if self._border_right:
            self._border_style.render(self._border.bottom_right, writer=result)

        return result^

    def _construct_headers(self, widths: Array[UInt16, Self.columns], headers: Array[String, Self.columns]) -> String:
        """Constructs the headers for the table given it's current
        header configuration and data.

        Args:
            widths: The widths of the columns.
            headers: The headers of the table.

        Returns:
            The constructed headers as a string.
        """
        var result = String(capacity=SMALL_BUFFER_SIZE)
        if self._border_left:
            self._border_style.render(self._border.left, writer=result)

        comptime for col in range(Self.column_count):
            ref width = widths[col]
            var style = self.style(col, 0).max_height(1).width(width).max_width(width, tail="…")

            ref header = headers[col]
            if UInt16(printable_rune_width(header)) > width:
                style.render(truncate(header, UInt(width), "…"), writer=result)
            else:
                style.render(header, writer=result)
            if (col < Self.column_count - 1) and self._border_column:
                self._border_style.render(self._border.left, writer=result)

        if self._border_header:
            if self._border_right:
                self._border_style.render(self._border.right, writer=result)

            result.write(NEWLINE)
            if self._border_left:
                self._border_style.render(self._border.middle_left, writer=result)

            comptime for col in range(Self.columns):
                self._border_style.render(self._border.bottom * Int(widths[col]), writer=result)
                comptime if col < Self.columns - 1:
                    if self._border_column:
                        self._border_style.render(self._border.middle, writer=result)

            if self._border_right:
                self._border_style.render(self._border.middle_right, writer=result)

        if self._border_right and not self._border_header:
            self._border_style.render(self._border.right, writer=result)

        return result^

    def _construct_row(self, index: UInt, widths: Array[UInt16, Self.columns], heights: List[UInt16], headers: Optional[Array[String, Self.columns]]) -> String:
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
        var result = String(capacity=DEFAULT_BUFFER_SIZE)

        var header_offset = UInt(self._headers is not None)
        var height = heights[index + header_offset]

        var cells = List[String]()
        var left = (self._border_style.render(self._border.left) + NEWLINE) * Int(height)
        if self._border_left:
            cells.append(left)

        comptime for col in range(Self.column_count):
            var style = (
                self.style(col, index + 1)
                .height(height)
                .max_height(height)
                .width((widths[col]))
                .max_width((widths[col]), tail="…")
            )
            # A cell holds at most `width * height` cells. Content beyond that is dropped by
            # the height rule, so truncate it here to get an ellipsis on the overflow. The
            # width check keeps this from rescanning content that already fits.
            ref content = self.data[col, index]
            var capacity = UInt(widths[col] * height)
            if printable_rune_width(content) > capacity:
                cells.append(style.render(truncate(content, capacity, "…")))
            else:
                cells.append(style.render(content))
            comptime if col < Self.column_count - 1:
                if self._border_column:
                    cells.append(left)

        if self._border_right:
            cells.append((self._border_style.render(self._border.right) + NEWLINE) * Int(height))

        for i in range(len(cells)):
            if cells[i].endswith(NEWLINE):
                var trimmed = String(cells[i].removesuffix(NEWLINE))
                cells[i] = trimmed^

        result.write(join_horizontal(Position.TOP, cells), NEWLINE)

        if self._border_row and index < UInt(len(self.data)) - 1:
            result.write(self._border_style.render(self._border.middle_left))
            comptime for col in range(Self.columns):
                result.write(self._border_style.render(self._border.middle * Int(widths[col])))
                if col < Self.columns - 1:
                    if self._border_column:
                        result.write(self._border_style.render(self._border.middle))

            result.write(self._border_style.render(self._border.middle_right), NEWLINE)

        return result^
