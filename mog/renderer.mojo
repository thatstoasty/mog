from stormlight.mist import Profile


@value
struct Renderer:
    var color_profile: Profile

    fn __init__(inout self) raises:
        self.color_profile = Profile()

    fn set_color_profile(inout self, setting: String):
        self.color_profile.setting = setting
