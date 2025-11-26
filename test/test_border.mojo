import testing
from testing import TestSuite
from mog.border import render_horizontal_edge


fn test_render_horizontal_edge() raises:
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 10), "<--------->")


fn test_zero_width() raises:
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 0), "")


fn test_middle_replacement() raises:
    testing.assert_equal(render_horizontal_edge("<", "", ">", 10), "<         >")

fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
