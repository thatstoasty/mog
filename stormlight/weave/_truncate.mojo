fn truncate(text: String, width: UInt8) -> String:
    var modified: String = ""
    var current_width: UInt8 = 0
    for i in range(len(text)):
        let char = text[i]
        current_width += len(char) # TODO: Rune length in the future

        if current_width > width:
            return modified
        
        modified += char
        
    return modified
