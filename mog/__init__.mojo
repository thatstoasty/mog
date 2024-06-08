from .style import Style, NO_TAB_CONVERSION, get_lines, new_style
from .border import Border
from .table import Table, new_table, new_string_data, default_styles
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
