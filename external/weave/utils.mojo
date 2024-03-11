alias _ALL_WHITESPACES = " \t\n\r\x0b\f"


fn __string__mul__(input_string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += input_string
    return result


fn __str_contains__(smaller_string: String, bigger_string: String) -> Bool:
    if len(smaller_string) > len(bigger_string):
        return False
    for i in range(len(bigger_string) - len(smaller_string) + 1):
        if smaller_string == bigger_string[i : i + len(smaller_string)]:
            return True
    return False


fn lstrip(input_string: String, chars: String = _ALL_WHITESPACES) -> String:
    return input_string[_lstrip_index(input_string, chars) :]


fn rstrip(input_string: String, chars: String = _ALL_WHITESPACES) -> String:
    return input_string[: _rstrip_index(input_string, chars)]


fn _lstrip_index(input_string: String, chars: String) -> Int:
    for i in range(len(input_string)):
        if not (__str_contains__(input_string[i], chars)):
            return i
    return len(input_string)


fn _rstrip_index(input_string: String, chars: String) -> Int:
    for i in range(len(input_string) - 1, -1, -1):
        if not (__str_contains__(input_string[i], chars)):
            return i + 1
    return 0


fn strip(input_string: String, chars: String = _ALL_WHITESPACES) -> String:
    var lstrip_index = _lstrip_index(input_string, chars)
    var rstrip_index = _rstrip_index(input_string, chars)
    return input_string[lstrip_index:rstrip_index]
