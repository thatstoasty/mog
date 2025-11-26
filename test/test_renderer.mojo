import testing
from testing import TestSuite
from mog.renderer import Renderer

import mog
from mog import Profile


alias true_color_renderer = Renderer(Profile.TRUE_COLOR)
alias light_true_color_renderer = Renderer(Profile.TRUE_COLOR, dark_background=False)
alias ansi256_color_renderer = Renderer(Profile.ANSI256)
alias light_ansi256_color_renderer = Renderer(Profile.ANSI256, dark_background=False)
alias ansi_color_renderer = Renderer(Profile.ANSI)
alias light_ansi_color_renderer = Renderer(Profile.ANSI, dark_background=False)
alias ascii_renderer = Renderer(Profile.ASCII)
alias light_ascii_renderer = Renderer(Profile.ASCII, dark_background=False)


fn test_has_dark_background() raises:
    testing.assert_true(true_color_renderer.has_dark_background())
    testing.assert_false(light_true_color_renderer.has_dark_background())


fn main() raises -> None:
    TestSuite.discover_tests[__functions_in_module()]().run()
