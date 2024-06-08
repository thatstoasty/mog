# btoi converts a boolean to an integer, 1 if true, 0 if false.
fn btoi(b: Bool) -> Int:
    if b:
        return 1

    return 0


# sum returns the sum of all integers in a slice.
fn sum(numbers: List[Int]) -> Int:
    var sum: Int = 0
    for i in range(len(numbers)):
        sum += numbers[i]

    return sum


# median returns the median of a slice of integers.
fn median(n: List[Int]) -> Int:
    var sorted = n
    sort(sorted)

    if len(sorted) <= 0:
        return 0

    if len(sorted) % 2 == 0:
        var middle = len(sorted) / 2  # nolint:gomnd
        var median = (sorted[int(middle) - 1] + sorted[int(middle)]) / 2
        return int(round(median))  # nolint:gomnd

    return sorted[int(len(sorted) / 2)]


# largest returns the largest element and it's index from a slice of integers.
fn largest(numbers: List[Int]) -> (Int, Int):  # nolint:unparam
    var largest: Int = 0
    var index: Int = 0

    for i in range(len(numbers)):
        var element = numbers[i]

        if numbers[i] > numbers[index]:
            largest = element
            index = i

    return index, largest
