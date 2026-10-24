from std import testing
from std.testing import TestSuite
from mog.renderer import Renderer

import mog
from mog import Profile


comptime true_color_renderer = Renderer(Profile.true_color)
comptime light_true_color_renderer = Renderer(Profile.true_color, dark_background=False)
comptime ansi256_color_renderer = Renderer(Profile.ansi256)
comptime light_ansi256_color_renderer = Renderer(Profile.ansi256, dark_background=False)
comptime ansi_color_renderer = Renderer(Profile.ansi)
comptime light_ansi_color_renderer = Renderer(Profile.ansi, dark_background=False)
comptime ascii_renderer = Renderer(Profile.ascii)
comptime light_ascii_renderer = Renderer(Profile.ascii, dark_background=False)


def test_has_dark_background() raises:
    testing.assert_true(true_color_renderer.has_dark_background())
    testing.assert_false(light_true_color_renderer.has_dark_background())


def main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
