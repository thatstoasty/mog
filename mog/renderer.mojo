from external.mist import Profile


@value
struct Renderer:
    var color_profile: Profile
    var dark_background: Bool
    var explicit_color_profile: Bool
    var explicit_background_color: Bool

    fn __init__(
        inout self,
        color_profile: Profile = Profile(),
        dark_background: Bool = False,
        explicit_color_profile: Bool = False,
        explicit_background_color: Bool = False,
    ):
        self.color_profile = color_profile
        self.dark_background = dark_background
        self.explicit_color_profile = explicit_color_profile
        self.explicit_background_color = explicit_background_color

    fn set_color_profile(inout self, value: Int):
        """Sets the color profile on the renderer. This function exists
        mostly for testing purposes so that you can assure you're testing against
        a specific profile.

        Outside of testing you likely won't want to use this function as the color
        profile will detect and cache the terminal's color capabilities and choose
        the best available profile.

        Available color profiles are:

            mist.ASCII      no color, 1-bit
            mist.ANSI      16 colors, 4-bit
            mist.ANSI256    256 colors, 8-bit
            mist.TRUE_COLOR  16,777,216 colors, 24-bit
        """
        self.color_profile.value = value
        self.explicit_color_profile = True

    fn has_dark_background(self) -> Bool:
        """Returns whether or not the renderer will render to a dark
        background. A dark background can either be auto-detected, or set explicitly
        on the renderer.
        """
        return self.dark_background

    fn set_dark_background(inout self, value: Bool):
        """Sets the background color detection value for the
        default renderer. This function exists mostly for testing purposes so that
        you can assure you're testing against a specific background color setting.

        Outside of testing you likely won't want to use this function as the
        backgrounds value will be automatically detected and cached against the
        terminal's current background color setting.
        """
        self.dark_background = value
        self.explicit_background_color = True
