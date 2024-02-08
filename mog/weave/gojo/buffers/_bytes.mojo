from ..stdlib_extensions.builtins._bytes import bytes, Byte


fn to_string(bytes: bytes) -> String:
    var s: String = ""
    for i in range(len(bytes)):
        # TODO: Resizing isn't really working rn. The grow functions return the wrong index to append new bytes to.
        # This is a hack to ignore the 0 null characters that are used to resize the dynamicvector capacity.
        if bytes[i] != 0:
            let char = chr(int(bytes[i]))
            s += char
    return s


fn to_bytes(s: String) -> bytes:
    # TODO: Len of runes can be longer than one byte
    var b = bytes(size=len(s))
    for i in range(len(s)):
        b[i] = ord((s[i]))
    return b


fn index_byte(b: bytes, c: Byte) -> Int:
    let i = 0
    for i in range(len(b)):
        if b[i] == c:
            return i

    return -1


fn equal(a: bytes, b: bytes) -> Bool:
    return to_string(a) == to_string(b)


fn has_prefix(s: bytes, prefix: bytes) -> Bool:
    """Reports whether the byte slice s begins with prefix."""
    let len_comparison = len(s) >= len(prefix)
    let prefix_comparison = equal(s[0 : len(prefix)], prefix)
    return len_comparison and prefix_comparison


fn has_suffix(s: bytes, suffix: bytes) -> Bool:
    """Reports whether the byte slice s ends with suffix."""
    let len_comparison = len(s) >= len(suffix)
    let suffix_comparison = equal(s[len(s) - len(suffix) : len(s)], suffix)
    return len_comparison and suffix_comparison
