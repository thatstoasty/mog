import testing
import mist
from mog.extensions import pad_left, pad_right, get_lines, get_lines_view, get_widest_line


alias ascii_style = mist.Style(mist.ASCII)
alias white_space_style = mist.Style(mist.ANSI).background(15)


def test_pad_left():
    testing.assert_equal(pad_left("hello", 10, ascii_style), "          hello")
    testing.assert_equal(pad_left("hello", 10, white_space_style), "\x1b[;107m          \x1b[0mhello")
    testing.assert_equal(pad_left("\n\n\n\n\n", 3, ascii_style), "   \n   \n   \n   \n   ")


def test_pad_right():
    testing.assert_equal(pad_right("hello", 10, ascii_style), "hello          ")
    testing.assert_equal(pad_right("hello", 10, white_space_style), "hello\x1b[;107m          \x1b[0m")
    testing.assert_equal(pad_right("\n\n\n\n\n", 3, ascii_style), "   \n   \n   \n   \n   ")


def test_get_lines():
    lines, widest_line = get_lines("hello\nworld")
    testing.assert_equal(lines, List[String]("hello", "world"))
    testing.assert_equal(widest_line, 5)


def test_get_lines_empty_string():
    lines, widest_line = get_lines("")
    testing.assert_equal(lines, List[String](""))
    testing.assert_equal(widest_line, 0)


def test_get_lines_view():
    lines, widest_line = get_lines_view("hello\nworld")
    testing.assert_equal(String(lines[0]), "hello")
    testing.assert_equal(String(lines[1]), "world")
    testing.assert_equal(widest_line, 5)


def test_get_lines_view_empty_string():
    lines, widest_line = get_lines_view("")
    testing.assert_equal(String(lines[0]), "")
    testing.assert_equal(widest_line, 0)


def test_get_widest_line():
    widest_line = get_widest_line("hello\nworld!")
    testing.assert_equal(widest_line, 6)

    widest_line = get_widest_line("\n\n\n\n")
    testing.assert_equal(widest_line, 0)
