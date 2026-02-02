@register_passable("trivial")
struct Position(Equatable, Copyable):
    """Position represents a position along a horizontal or vertical axis. It's in
    situations where an axis is involved, like alignment, joining, placement and
    so on.

    A value of 0 represents the start (the left or top) and 1 represents the end
    (the right or bottom). 0.5 represents the center.

    There are constants `top`, `bottom`, `center`, `left` and `right` in this package that
    can be used to aid readability."""

    var value: Float64
    """The value of the position, between 0 and 1 inclusive."""

    comptime RIGHT = Self(1.0)
    """Aligns to the right."""
    comptime TOP = Self(0.0)
    """Aligns to the top."""
    comptime BOTTOM = Self(1.0)
    """Aligns to the bottom."""
    comptime CENTER = Self(0.5)
    """Aligns to the center."""
    comptime LEFT = Self(0.0)
    """Aligns to the left."""

    @implicit
    fn __init__(out self, value: Float64):
        """Initializes a Position.

        Args:
            value: The value of the position, between 0 and 1 inclusive.

        Returns:
            A Position instance.
        """
        self.value = value

    fn __eq__(self, other: Self) -> Bool:
        """Check if two positions are equal.

        Args:
            other: The other position to compare with.

        Returns:
            True if the positions are equal, False otherwise.
        """
        return self.value == other.value
