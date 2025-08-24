import testing
from mog.renderer import Renderer

import mog


alias true_color_renderer = Renderer(mog.Profile.TRUE_COLOR)
alias light_true_color_renderer = Renderer(mog.Profile.TRUE_COLOR, dark_background=False)
alias ansi256_color_renderer = Renderer(mog.Profile.ANSI256)
alias light_ansi256_color_renderer = Renderer(mog.Profile.ANSI256, dark_background=False)
alias ansi_color_renderer = Renderer(mog.Profile.ANSI)
alias light_ansi_color_renderer = Renderer(mog.Profile.ANSI, dark_background=False)
alias ascii_renderer = Renderer(mog.Profile.ASCII)
alias light_ascii_renderer = Renderer(mog.Profile.ASCII, dark_background=False)


def test_has_dark_background():
    testing.assert_true(true_color_renderer.has_dark_background())
    testing.assert_false(light_true_color_renderer.has_dark_background())
