from ..stdlib_extensions.builtins._bytes import bytes, Byte


fn trim_null_characters(b: bytes) -> bytes:
    """Limits characters to the ASCII range of 1-127. Excludes null characters, extended characters, and unicode characters.
    """
    var new_b = bytes(len(b))
    for i in range(len(b)):
        if b[i] > 0 and b[i] < 127:
            new_b[i] = b[i]
    return new_b


fn copy(inout target: bytes, source: bytes) -> Int:
    var count = 0

    # TODO: End of strings include a null character which terminates the string. This is a hack to not write those to the buffer for now.
    for i in range(len(source)):
        if source[i] != 0:
            target._vector.append(source[i])
            count += 1

    target = trim_null_characters(target)
    return count


fn cap(buffer: bytes) -> Int:
    return buffer._vector.capacity
