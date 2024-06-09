# Strings
@always_inline
fn split(text: String, sep: String, max_split: Int = -1) -> List[String]:
    var lines: List[String]
    try:
        lines = text.split(sep, max_split)
    except:
        lines = List[String](text)

    return lines


@always_inline
fn join(separator: String, iterable: List[String]) -> String:
    var result: String = ""
    for i in range(len(iterable)):
        result += iterable[i]
        if i != len(iterable) - 1:
            result += separator
    return result
