# Strings
fn split(text: String, sep: String, max_split: Int = -1) -> List[String]:
    try:
        return text.split(sep, max_split)
    except:
        return List[String](text)


fn join(separator: String, iterable: List[String]) -> String:
    var result: String = ""
    for i in range(len(iterable)):
        result += iterable[i]
        if i != len(iterable) - 1:
            result += separator
    return result
