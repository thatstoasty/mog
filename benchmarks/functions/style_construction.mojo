"""Benchmarks for the two ways of configuring a `Style`.

A setter returns a new `Style`, so a chain of them copies the style once per
call, where the constructor sets every field in one pass. These measure what
that costs, and what it costs to chain onto a style that already exists, which
is what the table does for every cell and what no constructor call can replace.
"""
import mog
from mog import Alignment, Border, Emphasis, Padding, Position, Profile


comptime WIDTH = 22
"""The width the styles below are built with."""


def build_chained():
    """Builds a style of eight properties by chaining setters onto a bare `Style`."""
    var style = (
        mog.Style(Profile.ansi)
        .width(WIDTH)
        .bold()
        .foreground(mog.Color(0xFAFAFA))
        .background(mog.Color(0x7D56F4))
        .height(3)
        .padding(1, 2)
        .text_alignment(Position.CENTER)
        .max_width(40, tail="…")
    )
    _ = style^


def build_constructor():
    """Builds the same eight-property style in a single constructor call."""
    var style = mog.Style(
        Profile.ansi,
        width=WIDTH,
        emphasis=Emphasis.bold,
        foreground=mog.Color(0xFAFAFA),
        background=mog.Color(0x7D56F4),
        height=3,
        padding=Padding(y=1, x=2),
        alignment=Alignment(Position.CENTER),
        max_width=40,
        tail="…",
    )
    _ = style^


comptime base_style = mog.Style(
    color_profile=Profile.ansi,
    foreground=mog.Color(0xFAFAFA),
    background=mog.Color(0x7D56F4),
    emphasis=Emphasis.bold,
    padding=Padding(y=1, x=2),
    alignment=Alignment(Position.CENTER),
    border=Border.ROUNDED,
)
"""A configured style, standing in for a theme or a table's cell style."""


def modify_chained():
    """Sizes an existing style, the way a table sizes each of its cells."""
    var style = base_style.height(3).max_height(3).width(WIDTH).max_width(WIDTH, tail="…")
    _ = style^
