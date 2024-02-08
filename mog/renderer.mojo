from .mist import Profile


@value
struct Renderer:
    var color_profile: Profile

    fn __init__(inout self) raises:
        self.color_profile = Profile()

    fn set_color_profile(inout self, value: String):
        self.color_profile.value = value
