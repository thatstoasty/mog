from time import perf_counter_ns

from mog.border import ASCII_BORDER, HIDDEN_BORDER, ROUNDED_BORDER, STAR_BORDER, Border
from mog.join import join_horizontal, join_vertical
from mog.style import Style

import mog
from mog import Position
from mog.table import Data, Table
from mog.table.table import default_styles


def test_horizontal_joined_paragraphs():
    var style_build_start = perf_counter_ns()
    var style = mog.Style().bold().width(50).padding(1, 1, 1, 1).horizontal_alignment(Position.CENTER).border(
        ROUNDED_BORDER
    ).foreground(mog.Color(0xC9A0DC)).border_foreground(mog.Color(0x39E506))
    var style_build_duration = perf_counter_ns() - style_build_start
    print("Style build duration: ", style_build_duration, style_build_duration / 1e9)
    var start_time = perf_counter_ns()

    print(style.render("You should be able to join blocks of different heights"))
    print(
        join_horizontal(
            Position.TOP,
            style.render("You should be able to join blocks of different heights"),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
    print(
        join_horizontal(
            Position.BOTTOM,
            style.render("You should be able to join blocks of different heights"),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
    print(
        join_horizontal(
            Position.CENTER,
            style.render("You should be able to join blocks of different heights"),
            style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )
    var execution_time = perf_counter_ns() - start_time
    print("Block execution time: ", execution_time, execution_time / 1e9)


def test_borderless_paragraph():
    var borderless_style = mog.Style().width(50).padding(1, 2).horizontal_alignment(Position.CENTER).border(
        HIDDEN_BORDER
    ).background(mog.Color(0xC9A0DC))

    print(
        join_horizontal(
            Position.CENTER,
            borderless_style.render("You should be able to join blocks of different heights"),
            borderless_style.render(
                "Hello World!\nThis is a test of the mog style system. Which"
                " can wrap lines that are longer than the limit.\n\nYep."
            ),
            borderless_style.render(
                "This is to validate that more than three blocks can be"
                " joined.\nI hope this works!\n Lines that are longer than the"
                " limit can be a pain.\n\nSome more text."
            ),
        )
    )

def main():
    test_horizontal_joined_paragraphs()
    test_borderless_paragraph()
