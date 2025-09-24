fn sum(numbers: Span[Int]) -> Int:
    """Returns the sum of all integers in a list.

    Args:
        numbers: The list of integers.

    Returns:
        The sum of all integers in the list.
    """
    var sum = 0
    for i in range(len(numbers)):
        sum += numbers[i]

    return sum


fn median[origin: MutableOrigin](numbers: Span[Int, origin]) -> Int:
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
        var middle = len(numbers) / 2
        var median = (numbers[Int(middle) - 1] + numbers[Int(middle)]) / 2
        return Int(round(median))

    return numbers[Int(len(numbers) / 2)]


fn largest(numbers: Span[Int]) -> (Int, Int):
    """Returns the largest element and it's index from a list of integers.

    Args:
        numbers: The list of integers.

    Returns:
        A tuple containing the index and the largest element.
    """
    var largest = 0
    var index = 0
    for i in range(len(numbers)):
        if numbers[i] > numbers[index]:
            largest = numbers[i]
            index = i

    return index, largest
