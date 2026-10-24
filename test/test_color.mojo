import mist
from std import testing
from std.testing import TestSuite
from mog.color import (
    AdaptiveColor,
    ANSIColor,
    Color,
    CompleteAdaptiveColor,
    CompleteColor,
    NoColor,
)
from mog.renderer import Renderer
import mog


comptime true_color_renderer = Renderer(mog.Profile.true_color)
comptime light_true_color_renderer = Renderer(mog.Profile.true_color, dark_background=False)
comptime ansi256_color_renderer = Renderer(mog.Profile.ansi256)
comptime light_ansi256_color_renderer = Renderer(mog.Profile.ansi256, dark_background=False)
comptime ansi_color_renderer = Renderer(mog.Profile.ansi)
comptime light_ansi_color_renderer = Renderer(mog.Profile.ansi, dark_background=False)
comptime ascii_renderer = Renderer(mog.Profile.ascii)
comptime light_ascii_renderer = Renderer(mog.Profile.ascii, dark_background=False)


def assert_ascii(result: mist.Color) raises:
    """Asserts that `result` is a `mist.Color.ascii`."""
    match result:
        case .ascii:
            pass
        case _:
            raise Error("expected an ascii color, got ", result)


def assert_ansi(result: mist.Color, expected: UInt8) raises:
    """Asserts that `result` is a `mist.Color.ansi` holding `expected`."""
    match result:
        case .ansi(value):
            testing.assert_equal(value, expected)
        case _:
            raise Error("expected an ansi color, got ", result)


def assert_ansi256(result: mist.Color, expected: UInt8) raises:
    """Asserts that `result` is a `mist.Color.ansi256` holding `expected`."""
    match result:
        case .ansi256(value):
            testing.assert_equal(value, expected)
        case _:
            raise Error("expected an ansi256 color, got ", result)


def assert_rgb(result: mist.Color, expected: UInt32) raises:
    """Asserts that `result` is a `mist.Color.rgb` holding `expected`."""
    match result:
        case .rgb(value):
            testing.assert_equal(value, expected)
        case _:
            raise Error("expected an rgb color, got ", result)


def test_no_color() raises:
    assert_ascii(NoColor().color(true_color_renderer))
    assert_ascii(NoColor().color(ansi256_color_renderer))
    assert_ascii(NoColor().color(ansi_color_renderer))
    assert_ascii(NoColor().color(ascii_renderer))


def test_color() raises:
    comptime example_color = Color(0)
    assert_ansi(example_color.color(true_color_renderer), 0)
    assert_ansi(example_color.color(ansi256_color_renderer), 0)
    assert_ansi(example_color.color(ansi_color_renderer), 0)
    assert_ascii(example_color.color(ascii_renderer))


def test_ansi_color() raises:
    comptime example_color = ANSIColor(0)
    assert_ansi(example_color.color(true_color_renderer), 0)
    assert_ansi(example_color.color(ansi256_color_renderer), 0)
    assert_ansi(example_color.color(ansi_color_renderer), 0)
    assert_ascii(example_color.color(ascii_renderer))


def test_adaptive_color() raises:
    comptime example_color = AdaptiveColor(light=0, dark=1)

    # Test dark background renderer
    assert_ansi(example_color.color(true_color_renderer), 1)

    # Test light background renderer
    assert_ansi(example_color.color(light_true_color_renderer), 0)


def test_complete_color() raises:
    comptime example_color = CompleteColor(true_color=0xFFFFFF, ansi256=255, ansi=0)

    # Test true color renderer
    assert_rgb(example_color.color(true_color_renderer), 0xFFFFFF)

    # Test ansi256 color renderer
    assert_ansi256(example_color.color(ansi256_color_renderer), 255)

    # Test ansi color renderer
    assert_ansi(example_color.color(ansi_color_renderer), 0)

    # Test ASCII renderer
    assert_ascii(example_color.color(ascii_renderer))


def test_complete_adaptive_color() raises:
    comptime example_color = CompleteAdaptiveColor(
        light=CompleteColor(true_color=0xFFFFFF, ansi256=255, ansi=0),
        dark=CompleteColor(true_color=0xFFFF00, ansi256=100, ansi=13),
    )

    # Test true color renderer
    assert_rgb(example_color.color(true_color_renderer), 0xFFFF00)
    assert_rgb(example_color.color(light_true_color_renderer), 0xFFFFFF)

    # Test ansi256 color renderer
    assert_ansi256(example_color.color(ansi256_color_renderer), 100)
    assert_ansi256(example_color.color(light_ansi256_color_renderer), 255)

    # Test ansi color renderer
    assert_ansi(example_color.color(ansi_color_renderer), 13)
    assert_ansi(example_color.color(light_ansi_color_renderer), 0)

    # Test ASCII renderer
    assert_ascii(example_color.color(ascii_renderer))


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
