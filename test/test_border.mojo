from std import testing
from std.testing import TestSuite
from mog.border import render_horizontal_edge


def test_render_horizontal_edge() raises:
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 10), "<--------->")


def test_zero_width() raises:
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 0), "")


def test_middle_replacement() raises:
    testing.assert_equal(render_horizontal_edge("<", "", ">", 10), "<         >")


def test_multi_character_middle() raises:
    """A middle of more than one cell is repeated up to the width, not past it."""
    # The edge is `width` cells of middle plus the two corners, minus one; a middle
    # whose cell count does not divide that span evenly stops part way through.
    testing.assert_equal(render_horizontal_edge("+", "-=", "+", 10), "+-=-=-=-=-+")
    testing.assert_equal(render_horizontal_edge("+", "-=", "+", 11), "+-=-=-=-=-=+")
    testing.assert_equal(render_horizontal_edge("+", "abcd", "+", 7), "+abcdab+")


def test_multi_byte_middle() raises:
    """A multi-byte middle is repeated by character, not by byte."""
    testing.assert_equal(render_horizontal_edge("┌", "─", "┐", 5), "┌────┐")


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
