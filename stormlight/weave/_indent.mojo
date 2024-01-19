from stormlight.weave.stdlib.builtins.string import __string__mul__


fn add_indent(inout text: String, indent: UInt8):
    text = text + __string__mul__(String(" "), int(indent))


fn indent(s: String, indent: UInt8) -> String:
    var modified: String = ""
    add_indent(modified, indent)

    for i in range(len(s)):
        modified += s[i]

        if s[i] == "\n":
            add_indent(modified, indent)

    return modified
