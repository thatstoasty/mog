from ._bytes import Bytes, Byte


fn copy(
    inout target: DynamicVector[Int], source: DynamicVector[Int], start: Int = 0
) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.
    TODO: End of strings include a null character which terminates the string. This is a hack to not write those to the buffer for now.
    TODO: It appends additional values if the source is longer than the target, if not then it overwrites the target.
    """
    var count = 0

    for i in range(len(source)):
        if source[i] != 0:
            if len(target) <= i + start:
                target.append(source[i])
            else:
                target[i + start] = source[i]
            count += 1

    return count


fn copy(
    inout target: DynamicVector[String], source: DynamicVector[String], start: Int = 0
) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.
    TODO: End of strings include a null character which terminates the string. This is a hack to not write those to the buffer for now.
    TODO: It appends additional values if the source is longer than the target, if not then it overwrites the target.
    """
    var count = 0

    for i in range(len(source)):
        if source[i] != 0:
            if len(target) <= i + start:
                target.append(source[i])
            else:
                target[i + start] = source[i]
            count += 1

    return count


fn copy(inout target: Bytes, source: Bytes, start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.
    TODO: End of strings include a null character which terminates the string. This is a hack to not write those to the buffer for now.
    TODO: It appends additional values if the source is longer than the target, if not then it overwrites the target.
    """
    var count = 0

    for i in range(len(source)):
        if source[i] != 0:
            if len(target) <= i + start:
                target.append(source[i])
            else:
                target[i + start] = source[i]
            count += 1

    return count


fn cap(buffer: Bytes) -> Int:
    return buffer.capacity()


fn cap[T: CollectionElement](iterable: DynamicVector[T]) -> Int:
    return iterable.capacity
