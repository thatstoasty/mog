alias tab_width: String = "    "


fn add_newline(inout s: String):
    s += "\n"


# TODO: Probably pretty inefficient
fn add_word(inout s: String, word: String):
    if s == "" or s[-1].find("\n") != 1:
        s += word
    else:
        s += " " + word


fn wordwrap(s: String, limit: Int) raises -> String:
    var words: DynamicVector[String] = s.split(" ")

    for i in range(words.size):
        words[i] = words[i].replace("\t", tab_width)
        if len(words[i]) > limit:
            raise Error("Word too long to fit on line.")

    var modified: String = ""
    var line_length: Int = 0

    for i in range(len(words)):
        if line_length + len(words[i]) >= limit:
            add_newline(modified)
            line_length = 0
        add_word(modified, words[i])
        line_length += len(words[i]) + 1

    return modified
