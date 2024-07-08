fn btoi(b: Bool) -> Int:
    """Converts a boolean to an integer, 1 if true, 0 if false."""
    if b:
        return 1

    return 0


fn sum(numbers: List[Int]) -> Int:
    """Returns the sum of all integers in a slice."""
    var sum: Int = 0
    for i in range(len(numbers)):
        sum += numbers[i]

    return sum


fn median(n: List[Int]) -> Int:
    """Returns the median of a slice of integers."""
    var sorted = n
    sort(sorted)

    if len(sorted) <= 0:
        return 0

    if len(sorted) % 2 == 0:
        var middle = len(sorted) / 2
        var median = (sorted[int(middle) - 1] + sorted[int(middle)]) / 2
        return int(round(median))

    return sorted[int(len(sorted) / 2)]


fn largest(numbers: List[Int]) -> (Int, Int):
    """Returns the largest element and it's index from a slice of integers."""
    var largest: Int = 0
    var index: Int = 0

    for i in range(len(numbers)):
        var element = numbers[i]

        if numbers[i] > numbers[index]:
            largest = element
            index = i

    return index, largest
