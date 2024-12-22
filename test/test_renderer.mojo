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


def test_place_horizontal():
    testing.assert_equal(true_color_renderer.place_horizontal(18, mog.center, "Hello, World!"), "   Hello, World!  ")

    # Text longer than width, return same string
    testing.assert_equal(true_color_renderer.place_horizontal(10, mog.center, "Hello, World!"), "Hello, World!")


def test_place_horizontal_left():
    testing.assert_equal(true_color_renderer.place_horizontal(18, mog.left, "Hello, World!"), "Hello, World!     ")


def test_place_horizontal_right():
    testing.assert_equal(true_color_renderer.place_horizontal(18, mog.right, "Hello, World!"), "     Hello, World!")


def test_place_horizontal_fractional():
    # 0 ---------- 1
    # left ----- right
    testing.assert_equal(true_color_renderer.place_horizontal(18, 0.2, "Hello, World!"), " Hello, World!    ")
    testing.assert_equal(true_color_renderer.place_horizontal(18, 0.8, "Hello, World!"), "    Hello, World! ")


def test_place_vertical():
    testing.assert_equal(true_color_renderer.place_vertical(3, mog.center, "Hello, World!"), "             \nHello, World!\n             ")

    # Text taller than height, return same string
    testing.assert_equal(true_color_renderer.place_vertical(1, mog.center, "\nHello, World!\n"), "\nHello, World!\n")


def test_place_vertical_top():
    testing.assert_equal(true_color_renderer.place_vertical(3, mog.top, "Hello, World!"), "Hello, World!\n             \n             ")


def test_place_vertical_bottom():
    testing.assert_equal(true_color_renderer.place_vertical(3, mog.bottom, "Hello, World!"), "             \n             \nHello, World!")


def test_place_vertical_fractional():
    testing.assert_equal(true_color_renderer.place_vertical(5, 0.2, "Hello, World!"), "             \nHello, World!\n             \n             \n             ")
    testing.assert_equal(true_color_renderer.place_vertical(5, 0.8, "Hello, World!"), "             \n             \n             \nHello, World!\n             ")


def test_place():
    testing.assert_equal(true_color_renderer.place(18, 3, mog.center, mog.center, "Hello, World!"), "                  \n   Hello, World!  \n                  ")

    # Text taller than height, return width padded string
    testing.assert_equal(true_color_renderer.place(18, 1, mog.center, mog.center, "Hello, World!"), "   Hello, World!  ")

    # Text wider than width, return height padded string. Remember it's a box, so every line will have equal width.
    testing.assert_equal(true_color_renderer.place(1, 3, mog.center, mog.center, "Hello, World!"), "             \nHello, World!\n             ")

    # Text taller than height and wider than width, return same string
    testing.assert_equal(true_color_renderer.place(1, 1, mog.center, mog.center, "Hello, World!"), "Hello, World!")
