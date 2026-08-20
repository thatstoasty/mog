"""A module for representing positions along an axis."""


struct Position(Equatable, Writable, TrivialRegisterPassable):
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
    def __init__(out self, value: Float64):
        """Initializes a Position.

        Args:
            value: The value of the position. Values outside 0 to 1 are clamped into
                range, and NaN is treated as 0.

        Returns:
            A Position instance.
        """
        # Consumers scale a gap by this value and subtract the result from an unsigned
        # width. A value outside 0 to 1 makes that subtraction underflow to a huge
        # number, which then gets used as an allocation size, so the range is enforced
        # once here rather than at every use.
        if value != value:  # NaN compares unequal to itself.
            self.value = 0.0
        else:
            self.value = max(0.0, min(1.0, value))
