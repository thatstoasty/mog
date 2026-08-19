from mog.border import ASCII_BORDER, HIDDEN_BORDER, ROUNDED_BORDER, STAR_BORDER, Border
from mog.join import join_horizontal, join_vertical
from mog.style import Style

import mog
from mog import Position, Alignment, Padding
from mog.table import Data, Table
from mog.table.table import default_styles


def dummy_style_func[columns: Int](data: Data[columns], row: UInt, col: UInt) -> Style
    where columns > 0:
    var style = mog.Style(alignment=Alignment(Position.CENTER), padding=Padding(1, 0))
    if row == 0:
        return style.foreground(mog.Color(0xC9A0DC))
    elif row % 2 == 0:
        return style.foreground(mog.Color(0xE58006))
    else:
        return style^


def render_table():
    var border_style = mog.Style(foreground=mog.Color(0x39E506))
    var data = Data([
        ["French", "Bonjour", "Salut"],
        ["Russian", "Zdravstvuyte", "Privet"]
    ])

    var table = Table(
        style_function=dummy_style_func[data.columns],
        border=ROUNDED_BORDER,
        border_style=border_style,
        border_bottom=True,
        border_column=True,
        border_header=True,
        border_left=True,
        border_right=True,
        border_top=True,
        data=data^,
        width=50,
    )
    var t = String(table)
    _ = t^
