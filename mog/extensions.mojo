# Strings
fn count(text: String, substr: String) raises -> Int:
    var chunks = text.split(substr)

    return chunks.size


# Collections
fn get_slice[
    T: CollectionElement
](collection: DynamicVector[T], start: Int, end: Int) -> DynamicVector[T]:
    var slice = DynamicVector[T]()
    var i = start
    while i < end:
        slice.append(collection[i])
        i += 1

    return slice


fn __string__mul__(input_string: String, n: Int) -> String:
    var result: String = ""
    for _ in range(n):
        result += input_string
    return result


