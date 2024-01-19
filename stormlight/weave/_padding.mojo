from stormlight.weave.stdlib.builtins.string import __string__mul__


fn pad(s: String, padding: UInt8) -> String:
    let text: String = s
    let text_length = len(text)
    var line_length: UInt8 = 0
    var total_length: UInt8 = 1
    var modified: String = ""

    for i in range(len(text)):
        let char = text[i]

        if char == "\n":
            add_pad(modified, padding, line_length)
            line_length = 0
            modified += char
            total_length += len(char)
        elif total_length == text_length and line_length < padding:
            modified += char
            line_length += len(char)
            total_length += len(char)
            add_pad(modified, padding, line_length)
        else:
            modified += char
            line_length += len(char)
            total_length += len(char)

    return modified


fn add_pad(inout text: String, padding: UInt8, line_length: UInt8):
    if padding > 0 and line_length < padding:
        text = text + __string__mul__(String(" "), int(padding - line_length))
