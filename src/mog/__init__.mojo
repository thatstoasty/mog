from .style import Style, NO_TAB_CONVERSION
from .border import (
    Border,
    NORMAL_BORDER,
    ROUNDED_BORDER,
    DOUBLE_BORDER,
    ASCII_BORDER,
    STAR_BORDER,
    PLUS_BORDER,
    BLOCK_BORDER,
    OUTER_HALF_BLOCK_BORDER,
    INNER_HALF_BLOCK_BORDER,
    THICK_BORDER,
    HIDDEN_BORDER,
    NO_BORDER,
)
from .table import Table, default_styles, StringData, new_table, Data, Filter
from .position import top, bottom, center, left, right
from .size import get_height, get_width, get_size
from .color import (
    NoColor,
    Color,
    ANSIColor,
    AdaptiveColor,
    CompleteColor,
    CompleteAdaptiveColor,
    AnyTerminalColor,
)
from .renderer import Renderer
from .join import join_horizontal, join_vertical


alias WHITESPACE = String(" ")
alias NEWLINE = String("\n")

alias TRUE_COLOR = mist.TRUE_COLOR
alias ANSI256 = mist.ANSI256
alias ANSI = mist.ANSI
alias ASCII = mist.ASCII

fn raw_print(text: String) -> None:
    """Prints text without any formatting.

    Args:
        text: The text to print.
    """
    try:
        print(text.split("@").__str__())
    except:
        print(text)
