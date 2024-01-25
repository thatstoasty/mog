from stormlight.weave.gojo.bytes.bytes import Byte


fn trim_null_characters(b: DynamicVector[Byte]) -> DynamicVector[Byte]:
    """Limits characters to the ASCII range of 1-127. Excludes null characters, extended characters, and unicode characters.
    """
    var new_b = DynamicVector[Byte](b.size)
    for i in range(b.size):
        if b[i] > 0 and b[i] < 127:
            new_b.append(b[i])
    return new_b


fn to_string(b: DynamicVector[Byte]) -> String:
    var s: String = ""
    for i in range(b.size):
        # TODO: Resizing isn't really working rn. The grow functions return the wrong index to append new bytes to.
        # This is a hack to ignore the 0 null characters that are used to resize the dynamicvector capacity.
        if b[i] != 0:
            let char = chr(int(b[i]))
            s += char
    return s


fn copy(inout target: DynamicVector[Byte], source: DynamicVector[Byte]) -> Int:
    var count = 0

    # TODO: End of strings include a null character which terminates the string. This is a hack to not write those to the buffer for now.
    for i in range(source.size):
        if source[i] != 0:
            target.append(source[i])
            count += 1

    target = trim_null_characters(target)
    return count


# # ErrTooLarge is passed to panic if memory cannot be allocated to store data in a buffer.
# var ErrTooLarge = errors.New("buffer.Buffer: too large")
# var errNegativeRead = errors.New("buffer.Buffer: reader returned negative count from read")


fn cap(buffer: DynamicVector[Byte]) -> Int:
    return buffer.capacity
