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


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
    pass
