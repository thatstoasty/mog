from std import testing
from std.testing import TestSuite
from mog.border import render_horizontal_edge


def test_render_horizontal_edge() raises:
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 10), "<--------->")


def test_zero_width() raises:
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 0), "")


def test_middle_replacement() raises:
    testing.assert_equal(render_horizontal_edge("<", "", ">", 10), "<         >")

def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
