from .weave.truncate import string
from .weave.gojo.bytes.buffer import Buffer
from .stdlib_extensions.builtins._bytes import bytes
from .stdlib_extensions.builtinstring_builder.string import __string__mul__
from mog import Style, Border
from .border import ascii_border
from .position import top, bottom, left, right, center
from .join import join_horizontal
from .table.rows import StringData
from .size import get_height, get_width
from .table.util import btoi

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
alias StyleFunction = fn (row: Int, col: Int) -> Style


# default_styles is a TableStyleFunction that returns a new Style with no attributes.
fn default_styles() -> Style:
    return Style()


# Table is a type for rendering tables.
struct Table:
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
    var headers: DynamicVector[String]
    var data: StringData

    var width: Int
    var height: Int
    var offset: Int

    # widths tracks the width of each column.
    var widths: DynamicVector[Int]

    # heights tracks the height of each row.
    var heights: DynamicVector[Int]

    # Clearrows clears the table rows.
    fn clear_rows(self):
        self.data = StringData(_rows=DynamicVector[DynamicVector[String]](), _columns=0)

    # style returns the style for a cell based on it's position (row, column).
    fn style(self, row: Int, col: Int) -> Style:
        if self.StyleFunction == nil:
            return NewStyle()

        return self.StyleFunction(row, col)

    # rows appends rows to the table data.
    fn rows(self, *rows: DynamicVector[String]):
        for i in range(len(rows)):
            self.data.append(rows[i])

    fn rows(self, rows: DynamicVector[DynamicVector[String]]):
        for i in range(len(rows)):
            self.data.append(rows[i])

    # Row appends a row to the table data.
    fn row(self, *row: String):
        var temp = DynamicVector[String]()
        for element in row:
            temp.append(element[])
        self.data.append(temp)

    # Row appends a row to the table data.
    fn row(inout self, row: DynamicVector[String]):
        self.data.append(row)

    # Headers sets the table headers.
    fn set_headers(inout self, *headers: String):
        var temp = DynamicVector[String]()
        for element in headers:
            temp.append(element[])
        self.headers = temp

    fn set_headers(inout self, headers: DynamicVector[String]):
        self.headers = headers

    # String returns the table as a String.
    fn string(self) -> String:
        let has_headers = len(self.headers) > 0
        let has_rows = self.data.rows() > 0

        if not has_headers and not has_rows:
            return ""

        var buffer = bytes()
        var string_builder = Buffer(buffer)

        # Add empty cells to the headers, until it's the same length as the longest
        # row (only if there are at headers in the first place).
        if has_headers:
            var i = len(self.headers)
            while i < self.data.columns():
                self.headers.append("")
                i += 1

        # Initialize the widths.
        self.widths = DynamicVector[Int](max(len(self.headers), self.data.columns()))
        self.heights = DynamicVector[Int](btoi(has_headers) + self.data.rows())

        # The style fntion may affect width of the table. It's possible to set
        # the StyleFunction after the headers and rows. Update the widths for a final
        # time.
        for i in range(len(self.headers)):
            let cell = self.headers[i]
            self.widths[i] = max(
                self.widths[i], get_width(self.style(0, i).render(cell))
            )
            self.heights[0] = max(
                self.heights[0], get_height(self.style(0, i).render(cell))
            )

        let row_number: Int = 0
        let column_number: Int = 0
        while row_number < self.data.rows():
            while column_number < self.data.columns():
                let cell = self.data.at(r, column_number)
                let row_number_with_header_offset = btoi(has_headers)
                let rendered = self.style(row_number_with_header_offset, c).render(cell)

                self.heights[row_number_with_header_offset] = max(
                    self.heights[row_number_with_header_offset], get_height(rendered)
                )
                self.widths[column_number] = max(
                    self.widths[column_number], get_width(rendered)
                )
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
            var column_medians = DynamicVector[Int](len(self.widths))
            for i in range(len(self.widths)):
                var trimmed_width = DynamicVector[Int](self.data.rows())

                var r: Int = 0
                for r in range(self.data.rows()):
                    var rendered_cell = self.style(r + btoi(has_headers), i).render(
                        self.data.At(r, i)
                    )
                    var non_whitespace_chars = get_width(
                        strings.TrimRight(rendered_cell, " ")
                    )
                    trimmed_width[r] = non_whitespace_chars + 1

                column_medians[i] = median(trimmed_width)

            # Find the biggest differences between the median and the column width.
            # Shrink the columns based on the largest difference.
            var differences = DynamicVector[Int](len(self.widths))
            for i in range(len(self.widths)):
                differences[i] = self.widths[i] - column_medians[i]

            while width > self.width:
                var index = largest(differences)
                if differences[index] < 1:
                    break

                var shrink = min(differences[index], width - self.width)
                self.widths[index] -= shrink
                width -= shrink
                differences[index] = 0

            # Table is still too wide, begin shrinking the columns based on the
            # largest column.
            while width > self.width:
                index = largest(self.widths)
                if self.widths[index] < 1:
                    break

                self.widths[index] -= 1
                width -= 1

        if self.border_top:
            string_builder.write_string(self.constructTopBorder())
            string_builder.write_string("\n")

        if has_headers:
            string_builder.write_string(self.constructHeaders())
            string_builder.write_string("\n")

        var r = self.offset
        while r < self.data.rows():
            string_builder.write_string(self.construct_row(r))
            r += 1

        if self.border_bottom:
            string_builder.write_string(self.construct_bottom_border())

        var style = new_style()
        style.max_height = self.compute_height()
        style.max_width = self.width
        return style.render(string_builder.string())

    # compute_width computes the width of the table in it's current configuration.
    fn compute_width(self) -> Int:
        var width = sum(self.widths) + btoi(self.border_left) + btoi(self.border_right)
        if self.border_column:
            width += len(self.widths) - 1

        return width

    # compute_height computes the height of the table in it's current configuration.
    fn compute_height(self) -> Int:
        let has_headers = len(self.headers) > 0
        return (
            sum(self.heights)
            - 1
            + btoi(has_headers)
            + btoi(self.border_top)
            + btoi(self.border_bottom)
            + btoi(self.border_header)
            + self.data.rows() * btoi(self.border_row)
        )

    # render returns the table as a String.
    fn render(self) -> String:
        return self.string()

    # constructTopBorder constructs the top border for the table given it's current
    # border configuration and data.
    fn construct_top_border(self) -> String:
        var buffer = bytes()
        var string_builder = Buffer(buffer)

        if self.border_left:
            string_builder.write_string(self.border_style.render(self.border.top_left))

        var i: Int = 0
        while i < len(self.widths):
            string_builder.write_string(
                self.border_style.render(
                    __string__mul__(self.border.top, self.widths[i])
                )
            )
            if i < len(self.widths) - 1 and self.border_column:
                string_builder.write_string(
                    self.border_style.render(self.border.middle_top)
                )

            i += 1

        if self.border_right:
            string_builder.write_string(self.border_style.render(self.border.top_right))

        return string_builder.string()

    # construct_bottom_border constructs the bottom border for the table given it's current
    # border configuration and data.
    fn construct_bottom_border(self) -> String:
        var buffer = bytes()
        var string_builder = Buffer(buffer)
        if self.border_left:
            string_builder.write_string(
                self.border_style.render(self.border.bottom_left)
            )

        var i: Int = 0
        while i < len(self.widths):
            string_builder.write_string(
                self.border_style.render(
                    __string__mul__(self.border.bottom, self.widths[i])
                )
            )
            if i < len(self.widths) - 1 and self.border_column:
                string_builder.write_string(
                    self.border_style.render(self.border.middle_bottom)
                )

            i += 1

        if self.border_right:
            string_builder.write_string(
                self.border_style.render(self.border.bottom_right)
            )

        return string_builder.string()

    # constructHeaders constructs the headers for the table given it's current
    # header configuration and data.
    fn construct_headers(self) -> String:
        var buffer = bytes()
        var string_builder = Buffer(buffer)
        if self.border_left:
            string_builder.write_string(self.border_style.render(self.border.left))

        for i in range(len(self.headers)):
            let header = self.headers[i]
            string_builder.write_string(
                self.style(0, i)
                .max_height(1)
                .width(self.widths[i])
                .max_width(self.widths[i])
                .render(truncate.string_with_tail(header, uint(self.widths[i]), "…"))
            )
            if i < len(self.headers) - 1 and self.border_column:
                string_builder.write_string(self.border_style.render(self.border.left))

        if self.border_header:
            if self.border_right:
                string_builder.write_string(self.border_style.render(self.border.right))

            string_builder.write_string("\n")
            if self.border_left:
                string_builder.write_string(
                    self.border_style.render(self.border.middle_left)
                )

            var i: Int = 0
            while i < len(self.headers):
                string_builder.write_string(
                    self.border_style.render(
                        __string__mul__(self.border.bottom, self.widths[i])
                    )
                )
                if i < len(self.headers) - 1 and self.border_column:
                    string_builder.write_string(
                        self.border_style.render(self.border.middle)
                    )

                i += 1

            if self.border_right:
                string_builder.write_string(
                    self.border_style.render(self.border.middle_right)
                )

        if self.border_right and not self.border_header:
            string_builder.write_string(self.border_style.render(self.border.right))

        return string_builder.string()

    # construct_row constructs the row for the table given an index and row data
    # based on the current configuration.
    fn construct_row(self, index: Int) -> String:
        var buffer = bytes()
        var string_builder = Buffer(buffer)

        let has_headers = len(self.headers) > 0
        let height = self.heights[index + btoi(has_headers)]

        var cells = DynamicVector[String]()
        left = __string__mul__(
            self.border_style.render(self.border.left) + "\n", height
        )
        if self.border_left:
            cells.append(left)

        let c: Int = 0
        while c < self.data.columns():
            var cell = self.data.At(index, c)
            var style = self.style(index + 1, c)
            style.height(height)
            style.max_height(height)
            style.width(self.widths[c])
            style.max_width(self.widths[c])

            cells.append(
                style.render(
                    truncate.string_with_tail(cell, uint(self.widths[c] * height), "…")
                )
            )

            if c < self.data.columns() - 1 and self.border_column:
                cells = append(cells, left)

        if self.border_right:
            right = __string__mul__(
                self.border_style.render(self.border.right) + "\n", height
            )
            cells = append(cells, right)

        for i in range(len(cells)):
            let cell = cells[i]
            cells[i] = strings.TrimRight(cell, "\n")

        string_builder.write_string(join_horizontal(position.top, cells) + "\n")

        if self.border_row and index < self.data.rows() - 1:
            string_builder.write_string(
                self.border_style.render(self.border.middle_left)
            )
            var i: Int = 0
            while i < len(self.widths):
                string_builder.write_string(
                    self.border_style.render(
                        __string__mul__(self.border.middle, self.widths[i])
                    )
                )
                if i < len(self.widths) - 1 and self.border_column:
                    string_builder.write_string(
                        self.border_style.render(self.border.middle)
                    )

                i += 1
            string_builder.write_string(
                self.border_style.render(self.border.middle_right) + "\n"
            )

        return string_builder.string()


# New returns a new Table that can be modified through different
# attributes.
#
# By default, a table has no border, no styling, and no rows.
fn new_table() -> Table:
    return Table(
        StyleFunction=default_styles,
        border=ascii_border(),
        border_bottom=true,
        border_column=true,
        border_header=true,
        border_left=true,
        border_right=true,
        border_top=true,
        data=new_string_data(),
    )
