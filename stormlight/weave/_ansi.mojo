alias marker = '\x1B'
alias Rune = Int8


fn is_terminator(c: Rune) -> Bool:
    return (c >= 0x40 and c <= 0x5a) or (c >= 0x61 and c <= 0x7a)


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