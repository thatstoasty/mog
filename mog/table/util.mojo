"""Utility functions for working with lists of integers."""


def sum[origin: ImmOrigin, //](numbers: Span[UInt16, origin]) -> UInt:
    """Returns the sum of all integers in a list.

    Args:
        numbers: The list of integers.

    Returns:
        The sum of all integers in the list.

    #### Notes:
    The total is accumulated at a wider type than the elements, since a table with
    enough columns can total well past what a `UInt16` holds.
    """
    var sum: UInt = 0
    for num in numbers:
        sum += UInt(num)

    return sum


def median[origin: MutOrigin, //](numbers: Span[UInt16, origin]) -> UInt16:
    """Returns the median of a list of integers.

    Parameters:
        origin: The origin of the span.

    Args:
        numbers: The list of integers.

    Returns:
        The median of the list.
    """
    debug_assert(len(numbers) > 0, "Cannot find the median element of an empty list.")
    sort(numbers)
    if len(numbers) % 2 == 0:
        var middle = Int(len(numbers) / 2)
        # Widen before adding: two `UInt16` values can sum past the type's range, and
        # the result is halved straight back into it.
        var median = (UInt(numbers[middle - 1]) + UInt(numbers[middle])) / 2
        return UInt16(median)

    return numbers[Int(len(numbers) / 2)]


def largest[origin: ImmOrigin, //](numbers: Span[UInt16, origin]) -> Tuple[UInt, UInt16]:
    """Returns the largest element and it's index from a list of integers.

    Args:
        numbers: The list of integers.

    Returns:
        A tuple containing the index and the largest element.
    """
    debug_assert(len(numbers) > 0, "Cannot find largest element of an empty list.")

    var largest: UInt16 = 0
    var index: UInt = 0
    for i in range(UInt(len(numbers))):
        if numbers[i] > numbers[index]:
            largest = numbers[i]
            index = i

    return index, largest
