fn dedent(s: String) -> String:
    let indent = min_indent(s)
    if indent == 0:
        return s

    return apply_dedent(s, indent)


fn min_indent(s: String) -> Int:
    var cur_indent: Int = 0
    var min_indent: Int = 0
    var should_append: Bool = True

    var i: Int = 0
    while i < len(s):
        if (s[i] == " " or s[i] == "\t") and should_append:
            cur_indent += 1
        elif s[i] == "\n":
            cur_indent = 0
            should_append = True
        else:
            if cur_indent > 0 and (min_indent == 0 or cur_indent < min_indent):
                min_indent = cur_indent
                cur_indent = 0
            should_append = False
        i += 1

    return min_indent


fn apply_dedent(s: String, indent: Int) -> String:
    var modified: String = ""
    var omitted: Int = 0

    var i: Int = 0
    while i < len(s):
        # Omit space or tab if we haven't omitted enough to match the target dedent.
        # On a new line, reset the omitted counter.
        if s[i] == " " or s[i] == "\t":
            if omitted < indent:
                omitted += 1
            else:
                modified += s[i]
        elif s[i] == "\n":
            omitted = 0
            modified += s[i]
        else:
            modified += s[i]
        i += 1

    return modified
