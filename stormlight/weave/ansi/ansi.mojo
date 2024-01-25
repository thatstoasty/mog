from stormlight.weave.gojo.bytes.bytes import Byte

alias Marker = "\x1B"
alias Rune = Int32


fn is_terminator(c: Byte) -> Bool:
    return (c >= 0x40 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A)


fn len_without_ansi(s: String) -> Int:
    """Returns the length of a string without ANSI escape codes."""
    var length = 0
    var in_ansi = False
    for i in range(len(s)):
        let char = s[i]
        if char == "\x1b":
            in_ansi = True
        elif in_ansi and char == "m":
            in_ansi = False
        elif not in_ansi:
            length += 1
    return length


fn len_without_ansi(s: DynamicVector[Byte]) -> Int:
    """Returns the length of a string without ANSI escape codes."""
    var length = 0
    var in_ansi = False
    for i in range(len(s)):
        let char = s[i]
        if char == ord(Marker):
            in_ansi = True
        elif in_ansi and char == ord("m"):
            in_ansi = False
        elif not in_ansi:
            length += 1
    return length