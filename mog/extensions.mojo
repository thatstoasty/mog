# Strings
fn count(text: String, substr: String) -> Int:
    var chunks: List[String]
    try:
        chunks = text.split(substr)
    except:
        chunks = List[String](text)

    return chunks.size


fn repeat(input_string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += input_string
    return result


fn from_string(input_value: String) -> List[String]:
    var result = List[String]()
    for i in range(len(input_value)):
        result.append(input_value[i])
    return result


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


fn contains(vector: List[String], value: String) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False
