from std import testing
from std.testing import TestSuite
from mog import Position


def test_position_constants() raises:
    testing.assert_equal(Position.LEFT.value, 0.0)
    testing.assert_equal(Position.TOP.value, 0.0)
    testing.assert_equal(Position.CENTER.value, 0.5)
    testing.assert_equal(Position.RIGHT.value, 1.0)
    testing.assert_equal(Position.BOTTOM.value, 1.0)


def test_position_in_range_is_preserved() raises:
    testing.assert_equal(Position(0.0).value, 0.0)
    testing.assert_equal(Position(0.2).value, 0.2)
    testing.assert_equal(Position(1.0).value, 1.0)


def test_position_clamps_out_of_range() raises:
    """Out of range values are clamped rather than stored. Consumers scale a gap by this
    value and subtract it from an unsigned width, so a value above 1 or below 0 would
    underflow that subtraction into a huge allocation size."""
    testing.assert_equal(Position(1.5).value, 1.0)
    testing.assert_equal(Position(-0.5).value, 0.0)
    testing.assert_equal(Position(Float64("inf")).value, 1.0)
    testing.assert_equal(Position(Float64("-inf")).value, 0.0)


def test_position_nan_is_zero() raises:
    testing.assert_equal(Position(Float64("nan")).value, 0.0)


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
