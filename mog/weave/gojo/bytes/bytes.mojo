from mog.weave.gojo.collections import get_slice
from mog.weave.gojo.bytes.util import to_string

alias Byte = Int8


fn index_byte(b: DynamicVector[Byte], c: Byte) -> Int:
    let i = 0
    for i in range(b.size):
        if b[i] == c:
            return i

    return -1


fn equal(a: DynamicVector[Byte], b: DynamicVector[Byte]) -> Bool:
    return to_string(a) == to_string(b)


fn has_prefix(s: DynamicVector[Byte], prefix: DynamicVector[Byte]) -> Bool:
    """Reports whether the byte slice s begins with prefix."""
    let len_comparison = len(s) >= len(prefix)
    let prefix_comparison = equal(get_slice(s, 0, len(prefix)), prefix)
    return len_comparison and prefix_comparison


fn has_suffix(s: DynamicVector[Byte], suffix: DynamicVector[Byte]) -> Bool:
    """Reports whether the byte slice s ends with suffix."""
    let len_comparison = len(s) >= len(suffix)
    let suffix_comparison = equal(get_slice(s, len(s) - len(suffix), len(s)), suffix)
    return len_comparison and suffix_comparison
