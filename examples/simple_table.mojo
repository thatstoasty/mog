from mog.join import join_vertical, join_horizontal
from mog.table import Table, StringData
from mog.table.table import default_styles
from mog.border import (
    STAR_BORDER,
    ASCII_BORDER,
    Border,
    ROUNDED_BORDER,
    HIDDEN_BORDER,
)
from mog.style import Style
from mog import Position
import mog
from time import perf_counter_ns


fn dummy_style_func(row: Int, col: Int) -> Style:
    var style = mog.Style().horizontal_alignment(Position.CENTER).vertical_alignment(Position.CENTER).padding(0, 1)
    if row == 0:
        return style.foreground(mog.Color(0xC9A0DC))
    elif row % 2 == 0:
        return style.foreground(mog.Color(0xE58006))
    else:
        return style^


def main():
    var border_style = mog.Style().foreground(mog.Color(0x39E506))

    var table = Table(
        style_function=default_styles,
        border=ROUNDED_BORDER,
        border_style=border_style,
        border_bottom=True,
        border_column=True,
        border_header=True,
        border_left=True,
        border_right=True,
        border_top=True,
        data=StringData(),
        width=50,
    ).set_style(dummy_style_func).row("French", "Bonjour", "Salut").row("Russian", "Zdravstvuyte", "Privet")

    var headerless_start_time = perf_counter_ns()
    print(table)
    var headerless_execution_time = perf_counter_ns() - headerless_start_time

    table = table.set_headers("LANGUAGE", "FORMAL", "INFORMAL")
    var headered_start_time = perf_counter_ns()
    print(table)
    var headered_execution_time = perf_counter_ns() - headered_start_time

    print(
        "Headerless Execution Time: ",
        headerless_execution_time,
        headerless_execution_time / 1e9,
    )
    print(
        "Headered Execution Time: ",
        headered_execution_time,
        headered_execution_time / 1e9,
    )