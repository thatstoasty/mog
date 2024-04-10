# Strings
fn count(text: String, substr: String) raises -> Int:
    var chunks = text.split(substr)

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


fn split(
    input_string: String, sep: String = " ", owned max_split: Int = -1
) raises -> List[String]:
    """The separator can be multiple characters long."""
    var result = List[String]()
    if max_split == 0:
        result.append(input_string)
        return result
    if max_split < 0:
        max_split = len(input_string)

    if not sep:
        return from_string(input_string)[0:max_split]

    var output = List[String]()
    var start = 0
    var split_count = 0

    for end in range(len(input_string) - len(sep) + 1):
        if input_string[end : end + len(sep)] == sep:
            output.append(input_string[start:end])
            start = end + len(sep)
            split_count += 1

            if max_split > 0 and split_count >= max_split:
                break

    output.append(input_string[start:])
    return output


fn join(separator: String, iterable: List[String]) raises -> String:
    var result: String = ""
    for i in range(iterable.__len__()):
        result += iterable[i]
        if i != iterable.__len__() - 1:
            result += separator
    return result


fn contains(vector: List[String], value: String) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False
