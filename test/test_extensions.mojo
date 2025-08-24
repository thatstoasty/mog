import mist
import testing
from mog._extensions import get_lines, get_widest_line, pad_left, pad_right


alias ascii_style = mist.Style(mist.Profile.ASCII)
alias white_space_style = mist.Style(mist.Profile.ANSI).background(15)


def test_pad_left():
    testing.assert_equal(pad_left("hello", 10, ascii_style), "          hello")
    testing.assert_equal(pad_left("hello", 10, white_space_style), "\x1b[107m          \x1b[0mhello")
    testing.assert_equal(pad_left("\n\n\n\n\n", 3, ascii_style), "   \n   \n   \n   \n   ")


def test_pad_right():
    testing.assert_equal(pad_right("hello", 10, ascii_style), "hello          ")
    testing.assert_equal(pad_right("hello", 10, white_space_style), "hello\x1b[107m          \x1b[0m")
    testing.assert_equal(pad_right("\n\n\n\n\n", 3, ascii_style), "   \n   \n   \n   \n   ")


def test_get_lines():
    lines, widest_line = get_lines("hello\nworld")
    testing.assert_equal(len(lines), 2)
    testing.assert_equal(lines, List[StringSlice[StaticConstantOrigin]]("hello", "world"))
    testing.assert_equal(widest_line, 5)


def test_get_lines_empty_string():
    lines, widest_line = get_lines("")
    testing.assert_equal(len(lines), 1)
    testing.assert_equal(lines, List[StringSlice[StaticConstantOrigin]](""))
    testing.assert_equal(widest_line, 0)


# def test_get_lines_view():
#     lines, widest_line = get_lines_view("hello\nworld")
#     testing.assert_equal(String(lines[0]), "hello")
#     testing.assert_equal(String(lines[1]), "world")
#     testing.assert_equal(widest_line, 5)


# def test_get_lines_view_trailing_newlines():
#     lines, widest_line = get_lines_view("hello\nworld\n\n\n\n\n")
#     testing.assert_equal(len(lines), 6)
#     testing.assert_equal(String(lines[0]), "hello")
#     testing.assert_equal(String(lines[1]), "world")
#     testing.assert_equal(widest_line, 5)


# def test_get_lines_view_empty_string():
#     lines, widest_line = get_lines_view("")
#     testing.assert_equal(len(lines), 0)
#     testing.assert_equal(String(lines[0]), "")
#     testing.assert_equal(widest_line, 0)


def test_get_widest_line():
    widest_line = get_widest_line("hello\nworld!")
    testing.assert_equal(widest_line, 6)

    widest_line = get_widest_line("\n\n\n\n")
    testing.assert_equal(widest_line, 0)
