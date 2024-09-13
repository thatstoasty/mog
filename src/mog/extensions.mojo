from weave.ansi import printable_rune_width
from utils import StringSlice

# fn split_lines(text: StringSlice, keepends: Bool = False) -> List[String]:
#     """Split the string at line boundaries. This corresponds to Python's
#     [universal newlines](
#         https://docs.python.org/3/library/stdtypes.html#str.splitlines)
#     `"\\t\\n\\r\\r\\n\\f\\v\\x1c\\x1d\\x1e\\x85\\u2028\\u2029"`.

#     Args:
#         keepends: If True, line breaks are kept in the resulting strings.

#     Returns:
#         A List of Strings containing the input split by line boundaries.
#     """
#     var output = List[String]()
#     var length = text.byte_length()
#     var current_offset = 0
#     var ptr = text.unsafe_ptr()

#     while current_offset < length:
#         var eol_location = length - current_offset
#         var eol_length = 0
#         var curr_ptr = ptr.offset(current_offset)

#         for i in range(current_offset, length):
#             var read_ahead = 3 if i < length - 2 else (
#                 2 if i < length - 1 else 1
#             )
#             var res = _is_newline_start(ptr.offset(i), read_ahead)
#             if res[0]:
#                 eol_location = i - current_offset
#                 eol_length = res[1]
#                 break

#         var str_len: Int
#         var end_of_string = False
#         if current_offset >= length:
#             end_of_string = True
#             str_len = 0
#         elif keepends:
#             str_len = eol_location + eol_length
#         else:
#             str_len = eol_location

#         output.append(
#             String(Self(unsafe_from_utf8_ptr=curr_ptr, len=str_len))
#         )

#         if end_of_string:
#             break
#         current_offset += eol_location + eol_length

#     return output^


fn get_lines(text: String) -> Tuple[List[String], Int]:
    """Split a string into lines.

    Args:
        text: The string to split.

    Returns:
        A tuple containing the lines and the width of the widest line.
    """
    var lines = split_lines(text)
    var widest_line: Int = 0
    for i in range(len(lines)):
        if printable_rune_width(lines[i]) > widest_line:
            widest_line = printable_rune_width(lines[i])

    return lines, widest_line


fn split_lines(text: String) -> List[String]:
    return text.as_string_slice().splitlines()


fn join(separator: String, iterable: List[String]) -> String:
    var result: String = ""
    for i in range(len(iterable)):
        result += iterable[i]
        if i != len(iterable) - 1:
            result += separator
    return result
