# Strings
fn count(text: String, substr: String) raises -> Int:
    let chunks = text.split(substr)

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
