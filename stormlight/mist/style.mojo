from stormlight.mist.color import (
    Color,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    hex_to_rgb,
    hex_to_ansi256,
    ansi256_to_ansi,
)


fn sgr_format(n: String) -> String:
    """SGR formatting: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters.
    """
    return chr(27) + "[" + n + "m"


@value
struct Properties:
    # Escape character
    var escape: String
    # Bell
    var bell: String
    # Control Sequence Introducer
    var csi: String
    # Operating System Command
    var osc: String
    # String Terminator
    var st: String

    # Text formatting
    var bold: String
    var faint: String
    var underline: String
    var blink: String
    var reverse: String
    var crossout: String
    var overline: String
    var italic: String

    # Other
    var reset: String
    var clear: String

    fn __init__(inout self):
        self.escape = chr(27)
        self.bell = "\a"
        self.csi = self.escape + "["
        self.osc = self.escape + "]"
        self.st = self.escape + chr(
            92
        )  # Might not work, haven't tried. 92 should be a raw backslash

        self.reset = "0"
        self.bold = "1"
        self.faint = "2"
        self.italic = "3"
        self.underline = "4"
        self.blink = "5"
        self.reverse = "7"
        self.crossout = "9"
        self.overline = "53"

        # clear terminal and return cursor to top left
        self.clear = self.escape + "[2J" + self.escape + "[H"


@value
struct TerminalStyle:
    var styles: DynamicVector[String]
    var properties: Properties
    var profile: Profile

    fn __init__(inout self, profile: Profile):
        self.properties = Properties()
        self.styles = DynamicVector[String]()
        self.profile = profile

    fn color[T: Color](inout self, color: T) raises -> None:
        self.styles.push_back(color.sequence(False))

    fn bold(inout self) -> None:
        self.styles.push_back(self.properties.bold)

    fn italic(inout self) -> None:
        self.styles.push_back(self.properties.italic)

    fn underline(inout self) -> None:
        self.styles.push_back(self.properties.underline)

    fn blink(inout self) -> None:
        self.styles.push_back(self.properties.blink)

    fn reverse(inout self) -> None:
        self.styles.push_back(self.properties.reverse)

    fn crossout(inout self) -> None:
        self.styles.push_back(self.properties.crossout)

    fn overline(inout self) -> None:
        self.styles.push_back(self.properties.overline)

    fn background[T: Color](inout self, color: T) raises -> None:
        self.styles.push_back(color.sequence(True))

    fn foreground[T: Color](inout self, color: T) raises -> None:
        self.styles.push_back(color.sequence(False))

    fn render(self, input: String) -> String:
        var styling = String("")
        for i in range(len(self.styles)):
            styling = styling + sgr_format(self.styles[i])

        return styling + input + sgr_format(self.properties.reset)
