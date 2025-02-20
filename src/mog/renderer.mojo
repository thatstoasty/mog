from collections import Optional
import mist
from mog.position import Position


# Working on terminal background querying, currently it defaults to dark background terminal.
# If you need to set it to light, you can do so manually via the `set_dark_background` method.
@value
@register_passable("trivial")
struct Renderer:
    """Contains context for the color profile of the terminal and it's background.
    
    ### Attributes:
    * `profile`: The color profile to use for the renderer.
    * `dark_background`: Whether or not the renderer will render to a dark background.
    """

    var profile: mist.Profile
    """The color profile to use for the renderer."""
    var dark_background: Bool
    """Whether or not the renderer will render to a dark background."""

    fn __init__(
        out self,
        profile: Int = -1,
        *,
        dark_background: Bool = True,
    ):
        """Initializes a new renderer instance.

        Args:
            profile: The color profile to use for the renderer. Defaults to None.
            dark_background: Whether or not the renderer will render to a dark background. Defaults to True.
        """
        if profile != -1:
            self.profile = mist.Profile(profile)
        else:
            self.profile = mist.Profile()
        self.dark_background = dark_background

    fn has_dark_background(self) -> Bool:
        """Returns whether or not the renderer will render to a dark
        background. A dark background can either be auto-detected, or set explicitly
        on the renderer.

        Returns:
            Whether or not the renderer will render to a dark background.
        """
        return self.dark_background
    
    fn as_mist_style(self) -> mist.Style:
        """Returns a the `mist.Style` using the same profile as the for the style.

        Returns:
            The mist style.
        """
        return mist.Style(self.profile)

