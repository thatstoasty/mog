from std import testing
from std.testing import TestSuite
import mog
from mog.table import Table, Data


def test_table_render() raises:
    var s = mog.Style(mog.Profile.ANSI).foreground(mog.Color(240))
    var data = Data([["Bubble Tea", s.render("Milky")]])
    var table = Table(data=data^)
    table.width = 50
    comptime result = """╭──────────────────────────┬─────────────────────╮
│Bubble Tea                │\x1b[90mMilky\x1b[0m                │
╰──────────────────────────┴─────────────────────╯"""
    testing.assert_equal(s.render("Milky"), "\x1b[90mMilky\x1b[0m")
    testing.assert_equal(String(table), result)


def test_table_plain() raises:
    testing.assert_equal(
        String(Table(data=Data([["a", "b"], ["c", "d"]]))),
        "╭─┬─╮\n│a│b│\n│c│d│\n╰─┴─╯",
    )


def test_table_multiline_cell() raises:
    """A cell spanning several lines sets the height of its whole row."""
    testing.assert_equal(
        String(Table(data=Data([["one\ntwo\nthree", "x"], ["y", "z"]]))),
        "╭─────┬─╮\n│one  │x│\n│two  │ │\n│three│ │\n│y    │z│\n╰─────┴─╯",
    )


def test_table_wide_glyphs() raises:
    """Columns are sized by display width, not byte or codepoint count."""
    testing.assert_equal(
        String(Table(data=Data([["フシギダネ", "x"], ["y", "z"]]))),
        "╭──────────┬─╮\n│フシギダネ│x│\n│y         │z│\n╰──────────┴─╯",
    )


def test_table_ansi_cell() raises:
    """A pre-styled cell keeps exactly the sequences it came with."""
    var s = mog.Style(mog.Profile.ANSI).foreground(mog.Color(240))
    testing.assert_equal(
        String(Table(data=Data([[s.render("Milky"), "x"]]))),
        "╭─────┬─╮\n│\x1b[90mMilky\x1b[0m│x│\n╰─────┴─╯",
    )


def test_table_tabs() raises:
    testing.assert_equal(
        String(Table(data=Data([["a\tb", "x"]]))),
        "╭──────┬─╮\n│a    b│x│\n╰──────┴─╯",
    )


def test_table_shrink_to_width() raises:
    """Columns too wide for the table are shrunk to fit it exactly."""
    var table = Table(data=Data([["hello world", "abcdefghij"]]))
    table.width = 12
    testing.assert_equal(String(table), "╭────┬─────╮\n│hel…│abcd…│\n╰────┴─────╯")


def test_table_narrower_than_columns() raises:
    """Below one cell per column the shrink loop cannot reach the target width, so the
    table-wide truncation backstop enforces it instead."""
    var table = Table(data=Data([["hello world", "abcdefghij"]]))
    table.width = 4
    testing.assert_equal(String(table), "╭─┬─\n│…│…\n╰─┴─")

    var narrow = Table(data=Data([["hello world", "abcdefghij"]]))
    narrow.width = 3
    testing.assert_equal(String(narrow), "╭─┬\n│…│\n╰─┴")


def padded_styler[columns: Int](data: Data[columns], row: UInt, col: UInt) -> mog.Style
    where columns > 0:
    """A style function that changes a cell's size, not just its appearance."""
    return mog.Style().padding(left=1, right=1)


def coloured_styler[columns: Int](data: Data[columns], row: UInt, col: UInt) -> mog.Style
    where columns > 0:
    """A style function that changes only appearance."""
    return mog.Style(mog.Profile.ANSI).foreground(mog.Color(240))


def test_table_style_function_affecting_layout() raises:
    """Columns must be sized from the styled cell when the style adds padding, not from
    the raw text."""
    testing.assert_equal(
        String(Table(data=Data([["a", "b"]]), style_function=padded_styler[2])),
        "╭───┬───╮\n│ a │ b │\n╰───┴───╯",
    )


def test_table_style_function_appearance_only() raises:
    """Colour is zero-width, so the columns are sized as if it were not there."""
    testing.assert_equal(
        String(Table(data=Data([["a", "b"]]), style_function=coloured_styler[2])),
        "╭─┬─╮\n│\x1b[90ma\x1b[0m│\x1b[90mb\x1b[0m│\n╰─┴─╯",
    )


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
