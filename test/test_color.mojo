import mist
import mist.color
import testing
from mist.color import ANSI256Color, RGBColor
from mog.color import AdaptiveColor, ANSIColor, Color, CompleteAdaptiveColor, CompleteColor, NoColor
from mog.renderer import Renderer


alias true_color_renderer = Renderer(mog.Profile.TRUE_COLOR)
alias light_true_color_renderer = Renderer(mog.Profile.TRUE_COLOR, dark_background=False)
alias ansi256_color_renderer = Renderer(mog.Profile.ANSI256)
alias light_ansi256_color_renderer = Renderer(mog.Profile.ANSI256, dark_background=False)
alias ansi_color_renderer = Renderer(mog.Profile.ANSI)
alias light_ansi_color_renderer = Renderer(mog.Profile.ANSI, dark_background=False)
alias ascii_renderer = Renderer(mog.Profile.ASCII)
alias light_ascii_renderer = Renderer(mog.Profile.ASCII, dark_background=False)


def test_no_color():
    testing.assert_true(NoColor().color(true_color_renderer).isa[color.NoColor]())
    testing.assert_true(NoColor().color(ansi256_color_renderer).isa[color.NoColor]())
    testing.assert_true(NoColor().color(ansi_color_renderer).isa[color.NoColor]())
    testing.assert_true(NoColor().color(ascii_renderer).isa[color.NoColor]())


def test_color():
    alias example_color = Color(0)
    testing.assert_true(example_color.color(true_color_renderer).isa[color.ANSIColor]())
    testing.assert_true(example_color.color(ansi256_color_renderer).isa[color.ANSIColor]())
    testing.assert_true(example_color.color(ansi_color_renderer).isa[color.ANSIColor]())
    testing.assert_true(example_color.color(ascii_renderer).isa[color.NoColor]())


def test_ansi_color():
    alias example_color = ANSIColor(0)
    testing.assert_true(example_color.color(true_color_renderer).isa[color.ANSIColor]())
    testing.assert_true(example_color.color(ansi256_color_renderer).isa[color.ANSIColor]())
    testing.assert_true(example_color.color(ansi_color_renderer).isa[color.ANSIColor]())
    testing.assert_true(example_color.color(ascii_renderer).isa[color.NoColor]())


def test_adaptive_color():
    alias example_color = AdaptiveColor(light=0, dark=1)

    # Test dark background renderer
    testing.assert_true(example_color.color(true_color_renderer).isa[color.ANSIColor]())
    testing.assert_equal(example_color.color(true_color_renderer)[color.ANSIColor].value, 1)

    # Test light background renderer
    testing.assert_equal(example_color.color(light_true_color_renderer)[color.ANSIColor].value, 0)


def test_complete_color():
    alias example_color = CompleteColor(true_color=0xffffff, ansi256=255, ansi=0)

    # Test true color renderer
    testing.assert_true(example_color.color(true_color_renderer).isa[RGBColor]())
    testing.assert_equal(example_color.color(true_color_renderer)[RGBColor].value, 0xffffff)
    
    # Test ansi256 color renderer
    testing.assert_true(example_color.color(ansi256_color_renderer).isa[ANSI256Color]())
    testing.assert_equal(example_color.color(ansi256_color_renderer)[ANSI256Color].value, 255)

    # Test ansi color renderer
    testing.assert_true(example_color.color(ansi_color_renderer).isa[color.ANSIColor]())
    testing.assert_equal(example_color.color(ansi_color_renderer)[color.ANSIColor].value, 0)

    # Test ASCII renderer
    testing.assert_true(example_color.color(ascii_renderer).isa[mist.NoColor]())


def test_complete_adaptive_color():
    alias example_color = CompleteAdaptiveColor(
        light=CompleteColor(true_color=0xffffff, ansi256=255, ansi=0),
        dark=CompleteColor(true_color=0xffff00, ansi256=100, ansi=13)
    )

    # Test true color renderer
    testing.assert_true(example_color.color(true_color_renderer).isa[color.RGBColor]())
    testing.assert_equal(example_color.color(true_color_renderer)[color.RGBColor].value, 0xffff00)
    testing.assert_true(example_color.color(light_true_color_renderer).isa[color.RGBColor]())
    testing.assert_equal(example_color.color(light_true_color_renderer)[color.RGBColor].value, 0xffffff)
    
    # Test ansi256 color renderer
    testing.assert_true(example_color.color(ansi256_color_renderer).isa[color.ANSI256Color]())
    testing.assert_equal(example_color.color(ansi256_color_renderer)[color.ANSI256Color].value, 100)
    testing.assert_true(example_color.color(light_ansi256_color_renderer).isa[color.ANSI256Color]())
    testing.assert_equal(example_color.color(light_ansi256_color_renderer)[color.ANSI256Color].value, 255)

    # Test ansi color renderer
    testing.assert_true(example_color.color(ansi_color_renderer).isa[color.ANSIColor]())
    testing.assert_equal(example_color.color(ansi_color_renderer)[color.ANSIColor].value, 13)
    testing.assert_true(example_color.color(light_ansi_color_renderer).isa[color.ANSIColor]())
    testing.assert_equal(example_color.color(light_ansi_color_renderer)[color.ANSIColor].value, 0)

    # Test ASCII renderer
    testing.assert_true(example_color.color(ascii_renderer).isa[color.NoColor]())
