from .renderer import Renderer


@value
@register_passable("trivial")
struct Position:
    """Position represents a position along a horizontal or vertical axis. It's in
    situations where an axis is involved, like alignment, joining, placement and
    so on.

    A value of 0 represents the start (the left or top) and 1 represents the end
    (the right or bottom). 0.5 represents the center.

    There are constants `top`, `bottom`, `center`, `left` and `right` in this package that
    can be used to aid readability."""
    var value: Float64

    alias RIGHT: Position = Self(1.0)
    alias TOP: Position = Self(0.0)
    alias BOTTOM: Position = Self(1.0)
    alias CENTER: Position = Self(0.5)
    alias LEFT: Position = Self(0.0)

    @implicit
    fn __init__(out self, value: Float64):
        self.value = value
    
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    
    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value
