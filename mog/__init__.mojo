from .style import Style, NO_TAB_CONVERSION, get_lines
from .border import (
    Border,
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


alias WHITESPACE = String(" ")
alias NEWLINE = String("\n")
