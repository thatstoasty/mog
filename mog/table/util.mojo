fn sum(numbers: Span[UInt]) -> UInt:
    """Returns the sum of all integers in a list.

    Args:
        numbers: The list of integers.

    Returns:
        The sum of all integers in the list.
    """
    var sum: UInt = 0
    for i in range(len(numbers)):
        sum += numbers[i]

    return sum


fn median[origin: MutOrigin](numbers: Span[UInt, origin]) -> UInt:
    """Returns the median of a list of integers.

    Args:
        numbers: The list of integers.

    Returns:
        The median of the list.
    """
    sort(numbers)
    if len(numbers) <= 0:
        return 0

    if len(numbers) % 2 == 0:
        var middle = Int(len(numbers) / 2)
        var median = (numbers[middle - 1] + numbers[middle]) / 2
        return UInt(Int(median))

    return numbers[Int(len(numbers) / 2)]


fn largest(numbers: Span[UInt]) -> Tuple[UInt, UInt]:
    """Returns the largest element and it's index from a list of integers.

    Args:
        numbers: The list of integers.

    Returns:
        A tuple containing the index and the largest element.
    """
    var largest: UInt = 0
    var index: UInt = 0
    for i in range(UInt(len(numbers))):
        if numbers[i] > numbers[index]:
            largest = numbers[i]
            index = i

    return index, largest
