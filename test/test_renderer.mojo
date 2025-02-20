import testing
import mog
from mog.renderer import Renderer


alias true_color_renderer = Renderer(mog.TRUE_COLOR)
alias light_true_color_renderer = Renderer(mog.TRUE_COLOR, dark_background=False)
alias ansi256_color_renderer = Renderer(mog.ANSI256)
alias light_ansi256_color_renderer = Renderer(mog.ANSI256, dark_background=False)
alias ansi_color_renderer = Renderer(mog.ANSI)
alias light_ansi_color_renderer = Renderer(mog.ANSI, dark_background=False)
alias ascii_renderer = Renderer(mog.ASCII)
alias light_ascii_renderer = Renderer(mog.ASCII, dark_background=False)


def test_has_dark_background():
    testing.assert_true(true_color_renderer.has_dark_background())
    testing.assert_false(light_true_color_renderer.has_dark_background())
