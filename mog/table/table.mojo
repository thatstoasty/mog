from math import max, min
from external.weave import truncate
from external.gojo.strings import StringBuilder
from ..extensions import repeat
from ..style import Style
from ..border import rounded_border, Border
from ..position import top, bottom, left, right, center
from ..join import join_horizontal
from ..size import get_height, get_width
from .rows import StringData, new_string_data
from .util import btoi, median, largest, sum


fn trim_right(s: String, cutset: String) -> String:
    """Returns a slice of the string s, with all trailing
    Unicode code points contained in cutset removed.

    To remove a suffix, use [TrimSuffix] instead."""
    var index = s.find(cutset)
    if index == -1:
        return s

    return s[:index]


# StyleFunction is the style fntion that determines the style of a Cell.
#
# It takes the row and column of the cell as an input and determines the
# lipgloss Style to use for that cell position.
#
# Example:
#
# 	t = table.New().
# 	    Headers("Name", "Age").
# 	    Row("Kini", 4).
# 	    Row("Eli", 1).
# 	    Row("Iris", 102).
# 	    StyleFunction(fn(row, col Int) Style:
# 	        switch:
# 	           case row == 0:
# 	               return HeaderStyle
# 	           case row%2 == 0:
# 	               return Evenrowstyle
# 	           default:
# 	               return Oddrowstyle
#
# 	    )
alias StyleFunction = fn (row: Int, col: Int) raises escaping -> Style


fn default_styles(row: Int, col: Int) raises -> Style:
    """TableStyleFunction that returns a new Style with no attributes.

    Args:
        row: The row of the cell.
        col: The column of the cell.

    Returns:
        A new Style with no attributes.
    """
    return Style.new()


@value
struct Table:
    """Type for rendering tables."""

    var style_function: StyleFunction
    var border: Border

    var border_top: Bool
    var border_bottom: Bool
    var border_left: Bool
    var border_right: Bool
    var border_header: Bool
    var border_column: Bool
    var border_row: Bool

    var border_style: Style
    var headers: List[String]
    var data: StringData

    var width: Int
    # var height: Int
    var offset: Int

    # widths tracks the width of each column.
    var widths: List[Int]

    # heights tracks the height of each row.
    var heights: List[Int]

    fn __init__(
        inout self,
        style_function: StyleFunction,
        border: Border,
        border_style: Style,
        data: StringData,
        border_top: Bool = False,
        border_bottom: Bool = False,
        border_left: Bool = False,
        border_right: Bool = False,
        border_header: Bool = False,
        border_column: Bool = False,
        border_row: Bool = False,
        headers: List[String] = List[String](),
        width: Int = 0,
        # height: Int = 0,
        offset: Int = 0,
        widths: List[Int] = List[Int](),
        heights: List[Int] = List[Int](),
    ):
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
        # self.height = height
        self.offset = offset
        self.widths = widths
        self.heights = heights

    fn clear_rows(inout self):
        """Clears the table rows."""
        self.data = StringData(_rows=List[List[String]](), _columns=0)

    fn style(self, row: Int, col: Int) raises -> Style:
        """Returns the style for a cell based on it's position (row, column).

        Args:
            row: The row of the cell.
            col: The column of the cell.

        Returns:
            The style for the cell.
        """
        return self.style_function(row, col)

    fn rows(inout self, *rows: List[String]):
        """Returns the style for a cell based on it's position (row, column).

        Args:
            rows: The rows to add to the table.
        """
        for i in range(len(rows)):
            self.data.append(rows[i])

    fn rows(inout self, rows: List[List[String]]):
        """Returns the style for a cell based on it's position (row, column).

        Args:
            rows: The rows to add to the table.
        """
        for i in range(len(rows)):
            self.data.append(rows[i])

    fn row(inout self, *row: String):
        """Appends a row to the table data.

        Args:
            row: The row to append to the table.
        """
        var temp = List[String]()
        for element in row:
            temp.append(element[])
        self.data.append(temp)

    fn row(inout self, row: List[String]):
        """Appends a row to the table data.

        Args:
            row: The row to append to the table.
        """
        self.data.append(row)

    fn set_headers(inout self, *headers: String):
        """Sets the table headers.

        Args:
            headers: The headers to set.
        """
        var temp = List[String]()
        for element in headers:
            temp.append(element[])
        self.headers = temp

    fn set_headers(inout self, headers: List[String]):
        """Sets the table headers.

        Args:
            headers: The headers to set.
        """
        self.headers = headers

    fn __str__(inout self) raises -> String:
        """Returns the table as a String."""
        var has_headers = len(self.headers) > 0
        var has_rows = self.data.rows() > 0

        if not has_headers and not has_rows:
            return ""

        var builder = StringBuilder()

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
        for i in range(widths_len):
            self.widths.append(0)

        var heights_len = btoi(has_headers) + self.data.rows()
        self.heights = List[Int](capacity=heights_len)
        for i in range(heights_len):
            self.heights.append(0)

        # The style function may affect width of the table. It's possible to set
        # the StyleFunction after the headers and rows. Update the widths for a final
        # time.
        for i in range(len(self.headers)):
            self.widths[i] = get_width(self.style(0, i).render(self.headers[i]))
            self.heights[0] = get_height(self.style(0, i).render(self.headers[i]))

        var row_number: Int = 0
        while row_number < self.data.rows():
            var column_number: Int = 0
            while column_number < self.data.columns():
                var cell = self.data.at(row_number, column_number)
                var row_number_with_header_offset = row_number + btoi(has_headers)
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

                var r: Int = 0
                for r in range(self.data.rows()):
                    var rendered_cell = self.style(r + btoi(has_headers), i).render(self.data.at(r, i))
                    var non_whitespace_chars = get_width(trim_right(rendered_cell, " "))
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
            _ = builder.write_string(self.construct_top_border())
            _ = builder.write_string("\n")

        if has_headers:
            _ = builder.write_string(self.construct_headers())
            _ = builder.write_string("\n")

        var r = self.offset
        while r < self.data.rows():
            _ = builder.write_string(self.construct_row(r))
            r += 1

        if self.border_bottom:
            _ = builder.write_string(self.construct_bottom_border())

        return Style.new().max_height(self.compute_height()).max_width(self.width).render(str(builder))

    fn compute_width(self) -> Int:
        """Computes the width of the table in it's current configuration.

        Returns:
            The width of the table.
        """
        var width = sum(self.widths) + btoi(self.border_left) + btoi(self.border_right)
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
            + btoi(has_headers)
            + btoi(self.border_top)
            + btoi(self.border_bottom)
            + btoi(self.border_header)
            + self.data.rows() * btoi(self.border_row)
        )

    # render
    fn render(inout self) raises -> String:
        """Returns the table as a String.

        Returns:
            The table as a string.
        """
        return self.__str__()

    fn construct_top_border(self) raises -> String:
        """Constructs the top border for the table given it's current
        border configuration and data.

        Returns:
            The constructed top border as a string.
        """
        var builder = StringBuilder()
        if self.border_left:
            _ = builder.write_string(self.border_style.render(self.border.top_left))

        var i: Int = 0
        while i < len(self.widths):
            var l = self.border_style.render(repeat(self.border.top, self.widths[i]))
            _ = builder.write_string(self.border_style.render(repeat(self.border.top, self.widths[i])))
            if i < len(self.widths) - 1 and self.border_column:
                _ = builder.write_string(self.border_style.render(self.border.middle_top))
            i += 1

        if self.border_right:
            _ = builder.write_string(self.border_style.render(self.border.top_right))

        return str(builder)

    fn construct_bottom_border(self) raises -> String:
        """Constructs the bottom border for the table given it's current
        border configuration and data.

        Returns:
            The constructed bottom border as a string.
        """
        var builder = StringBuilder()
        if self.border_left:
            _ = builder.write_string(self.border_style.render(self.border.bottom_left))

        var i: Int = 0
        while i < len(self.widths):
            _ = builder.write_string(self.border_style.render(repeat(self.border.bottom, self.widths[i])))
            if i < len(self.widths) - 1 and self.border_column:
                _ = builder.write_string(self.border_style.render(self.border.middle_bottom))

            i += 1

        if self.border_right:
            _ = builder.write_string(self.border_style.render(self.border.bottom_right))

        return str(builder)

    fn construct_headers(self) raises -> String:
        """Constructs the headers for the table given it's current
        header configuration and data.

        Returns:
            The constructed headers as a string.
        """
        var builder = StringBuilder()
        if self.border_left:
            _ = builder.write_string(self.border_style.render(self.border.left))

        for i in range(len(self.headers)):
            var header = self.headers[i]
            var style = self.style(0, i).max_height(1).width(self.widths[i]).max_width(self.widths[i])

            _ = builder.write_string(
                style.render(truncate.apply_truncate_with_tail(header, UInt8(self.widths[i]), "…"))
            )

            if (i < len(self.headers) - 1) and (self.border_column):
                _ = builder.write_string(self.border_style.render(self.border.left))

        if self.border_header:
            if self.border_right:
                _ = builder.write_string(self.border_style.render(self.border.right))

            _ = builder.write_string("\n")
            if self.border_left:
                _ = builder.write_string(self.border_style.render(self.border.middle_left))

            var i: Int = 0
            while i < len(self.headers):
                _ = builder.write_string(self.border_style.render(repeat(self.border.bottom, self.widths[i])))
                if i < len(self.headers) - 1 and self.border_column:
                    _ = builder.write_string(self.border_style.render(self.border.middle))

                i += 1

            if self.border_right:
                _ = builder.write_string(self.border_style.render(self.border.middle_right))

        if self.border_right and not self.border_header:
            _ = builder.write_string(self.border_style.render(self.border.right))

        return str(builder)

    fn construct_row(self, index: Int) raises -> String:
        """Constructs the row for the table given an index and row data
        based on the current configuration.

        Args:
            index: The index of the row to construct.

        Returns:
            The constructed row as a string.
        """
        var builder = StringBuilder()

        var has_headers = len(self.headers) > 0
        var height = self.heights[index + btoi(has_headers)]

        var cells = List[String]()
        var left = repeat(self.border_style.render(self.border.left) + "\n", height)
        if self.border_left:
            cells.append(left)

        var c: Int = 0
        while c < self.data.columns():
            var cell = self.data.at(index, c)
            var style = self.style(index + 1, c).height(height).max_height(height).width(self.widths[c]).max_width(
                self.widths[c]
            )

            cells.append(style.render(truncate.apply_truncate_with_tail(cell, UInt8(self.widths[c] * height), "…")))

            if c < self.data.columns() - 1 and self.border_column:
                cells.append(left)

            c += 1

        if self.border_right:
            var right = repeat(self.border_style.render(self.border.right) + "\n", height)
            cells.append(right)

        for i in range(len(cells)):
            var cell = cells[i]
            cells[i] = trim_right(cell, "\n")

        _ = builder.write_string(join_horizontal(position.top, cells) + "\n")

        if self.border_row and index < self.data.rows() - 1:
            _ = builder.write_string(self.border_style.render(self.border.middle_left))
            var i: Int = 0
            while i < len(self.widths):
                _ = builder.write_string(self.border_style.render(repeat(self.border.middle, self.widths[i])))
                if i < len(self.widths) - 1 and self.border_column:
                    _ = builder.write_string(self.border_style.render(self.border.middle))

                i += 1
            _ = builder.write_string(self.border_style.render(self.border.middle_right) + "\n")

        return str(builder)


fn new_table() -> Table:
    """Returns a new Table that can be modified through different
    attributes.

    By default, a table has no border, no styling, and no rows."""
    return Table(
        style_function=default_styles,
        border=rounded_border(),
        border_style=Style.new(),
        border_bottom=True,
        border_column=True,
        border_header=True,
        border_left=True,
        border_right=True,
        border_top=True,
        data=new_string_data(),
    )
