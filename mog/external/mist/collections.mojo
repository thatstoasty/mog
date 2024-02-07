from collections.dict import Dict, KeyElement


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s


fn contains(vector: DynamicVector[String], value: String) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False
