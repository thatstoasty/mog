# btoi converts a boolean to an integer, 1 if true, 0 if false.
fn btoi(b: Bool) -> Int:
    if b:
        return 1

    return 0


# max returns the greater of two integers.
fn max(a: Int, b: Int) -> Int:
    if a > b:
        return a

    return b


# min returns the greater of two integers.
fn min(a: Int, b: Int) -> Int:
    if a < b:
        return a

    return b


# # sum returns the sum of all integers in a slice.
# fn sum(numbers: DynamicVector[Int]) -> Int:
# 	var sum: Int = 0
#     for number in numbers:
#         sum += number

# 	return sum


# # median returns the median of a slice of integers.
# fn median(n: DynamicVector[Int]) -> Int:
# 	sort.Ints(n)

# 	if len(n) <= 0:
# 		return 0

# 	if len(n)%2 == 0:
# 		h := len(n) / 2            #nolint:gomnd
# 		return (n[h-1] + n[h]) / 2 #nolint:gomnd

# 	return n[len(n)/2]


# largest returns the largest element and it's index from a slice of integers.
fn largest(numbers: DynamicVector[Int]) raises -> (Int, Int):  # nolint:unparam
    var largest: Int = 0
    var index: Int = 0

    for i in range(len(numbers)):
        let element = numbers[i]

        if numbers[i] > numbers[index]:
            largest = element
            index = i

    return index, largest
