from collections import InlineList


fn copy[T: CollectionElement](inout target: List[T], source: List[T], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        target: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(len(source)):
        if i + start > len(target):
            target[i + start] = source[i]
        else:
            target.append(source[i])
        count += 1

    return count


fn copy[T: CollectionElement](inout target_span: Span[T, True], source_span: Span[T], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        target_span: The buffer to copy into.
        source_span: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(len(source_span)):
        target_span[i + start] = source_span[i]
        count += 1

    target_span._len += count
    return count


fn copy[T: CollectionElement](inout target_span: Span[T, True], source: InlineList[T], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        target_span: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(len(source)):
        target_span[i + start] = source[i]
        count += 1

    target_span._len += count
    return count


fn test(inout dest: List[UInt8]):
    var source = List[UInt8](1, 2, 3)
    var target = Span[UInt8](dest)

    _ = copy(target, Span(source), start=0)


fn copy[T: CollectionElement](inout list: InlineList[T], source: Span[T], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        list: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(len(source)):
        if i + start > len(list):
            list[i + start] = source[i]
        else:
            list.append(source[i])
        count += 1

    return count


fn copy(
    inout target: List[UInt8],
    source: DTypePointer[DType.uint8],
    source_start: Int,
    source_end: Int,
    target_start: Int = 0,
) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    Added a start parameter to specify the index to start copying into.

    Args:
        target: The buffer to copy into.
        source: The buffer to copy from.
        source_start: The index to start copying from.
        source_end: The index to stop copying at.
        target_start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(source_start, source_end):
        if i + target_start > len(target):
            target[i + target_start] = source[i]
        else:
            target.append(source[i])
        count += 1

    return count


fn cap[T: CollectionElement](iterable: List[T]) -> Int:
    """Returns the capacity of the List.

    Args:
        iterable: The List to get the capacity of.
    """
    return iterable.capacity
