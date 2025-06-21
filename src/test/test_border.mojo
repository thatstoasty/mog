import testing
from mog.border import render_horizontal_edge


def test_render_horizontal_edge():
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 10), "<--------->")


def test_zero_width():
    testing.assert_equal(render_horizontal_edge("<", "-", ">", 0), "")


def test_middle_replacement():
    testing.assert_equal(render_horizontal_edge("<", "", ">", 10), "<         >")
