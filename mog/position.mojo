from .renderer import Renderer

# Position represents a position along a horizontal or vertical axis. It's in
# situations where an axis is involved, like alignment, joining, placement and
# so on.
#
# A value of 0 represents the start (the left or top) and 1 represents the end
# (the right or bottom). 0.5 represents the center.
#
# There are constants Top, Bottom, Center, Left and Right in this package that
# can be used to aid readability.
alias Position = Float64
alias right: Position = 1.0
alias top: Position = 0.0
alias bottom: Position = 1.0
alias center: Position = 0.5
alias left: Position = 0.0
