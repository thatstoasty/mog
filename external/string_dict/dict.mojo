from bit import pop_count, bit_width
from memory import memset_zero, memcpy
from collections import List
from .string_eq import eq
from .keys_container import KeysContainer
from .ahasher import ahash


struct Dict[
    V: CollectionElement,
    hash: fn (String) -> UInt64 = ahash,
    KeyCountType: DType = DType.uint32,
    KeyOffsetType: DType = DType.uint32,
    destructive: Bool = True,
    caching_hashes: Bool = True,
](Sized):
    var keys: KeysContainer[KeyOffsetType]
    var key_hashes: DTypePointer[KeyCountType]
    var values: List[V]
    var slot_to_index: DTypePointer[KeyCountType]
    var deleted_mask: DTypePointer[DType.uint8]
    var count: Int
    var capacity: Int

    fn __init__(inout self, capacity: Int = 16):
        constrained[
            KeyCountType == DType.uint8
            or KeyCountType == DType.uint16
            or KeyCountType == DType.uint32
            or KeyCountType == DType.uint64,
            "KeyCountType needs to be an unsigned integer",
        ]()
        self.count = 0
        if capacity <= 8:
            self.capacity = 8
        else:
            var icapacity = Int64(capacity)
            self.capacity = capacity if pop_count(icapacity) == 1 else 1 << int(bit_width(icapacity))
        self.keys = KeysContainer[KeyOffsetType](capacity)

        @parameter
        if caching_hashes:
            self.key_hashes = DTypePointer[KeyCountType].alloc(self.capacity)
        else:
            self.key_hashes = DTypePointer[KeyCountType].alloc(0)
        self.values = List[V](capacity=capacity)
        self.slot_to_index = DTypePointer[KeyCountType].alloc(self.capacity)
        memset_zero(self.slot_to_index, self.capacity)

        @parameter
        if destructive:
            self.deleted_mask = DTypePointer[DType.uint8].alloc(self.capacity >> 3)
            memset_zero(self.deleted_mask, self.capacity >> 3)
        else:
            self.deleted_mask = DTypePointer[DType.uint8].alloc(0)

    fn __copyinit__(inout self, existing: Self):
        self.count = existing.count
        self.capacity = existing.capacity
        self.keys = existing.keys

        @parameter
        if caching_hashes:
            self.key_hashes = DTypePointer[KeyCountType].alloc(self.capacity)
            memcpy(self.key_hashes, existing.key_hashes, self.capacity)
        else:
            self.key_hashes = DTypePointer[KeyCountType].alloc(0)
        self.values = existing.values
        self.slot_to_index = DTypePointer[KeyCountType].alloc(self.capacity)
        memcpy(self.slot_to_index, existing.slot_to_index, self.capacity)

        @parameter
        if destructive:
            self.deleted_mask = DTypePointer[DType.uint8].alloc(self.capacity >> 3)
            memcpy(self.deleted_mask, existing.deleted_mask, self.capacity >> 3)
        else:
            self.deleted_mask = DTypePointer[DType.uint8].alloc(0)

    fn __moveinit__(inout self, owned existing: Self):
        self.count = existing.count
        self.capacity = existing.capacity
        self.keys = existing.keys^
        self.key_hashes = existing.key_hashes
        self.values = existing.values^
        self.slot_to_index = existing.slot_to_index
        self.deleted_mask = existing.deleted_mask

    fn __del__(owned self):
        self.slot_to_index.free()
        self.deleted_mask.free()
        self.key_hashes.free()

    fn __len__(self) -> Int:
        return self.count

    @always_inline
    fn __contains__(inout self, key: String) -> Bool:
        return self._find_key_index(key) != 0

    fn put(inout self, key: String, value: V):
        if self.count / self.capacity >= 0.87:
            self._rehash()

        var key_hash = hash(key).cast[KeyCountType]()
        var modulo_mask = self.capacity - 1
        var slot = int(key_hash & modulo_mask)
        while True:
            var key_index = int(self.slot_to_index.load(slot))
            if key_index == 0:
                self.keys.add(key)

                @parameter
                if caching_hashes:
                    self.key_hashes.store(slot, key_hash)
                self.values.append(value)
                self.count += 1
                self.slot_to_index.store(slot, SIMD[KeyCountType, 1](self.keys.count))
                return

            @parameter
            if caching_hashes:
                var other_key_hash = self.key_hashes[slot]
                if other_key_hash == key_hash:
                    var other_key = self.keys[key_index - 1]
                    if eq(other_key, key):
                        self.values[key_index - 1] = value  # replace value

                        @parameter
                        if destructive:
                            if self._is_deleted(key_index - 1):
                                self.count += 1
                                self._not_deleted(key_index - 1)
                        return
            else:
                var other_key = self.keys[key_index - 1]
                if eq(other_key, key):
                    self.values[key_index - 1] = value  # replace value

                    @parameter
                    if destructive:
                        if self._is_deleted(key_index - 1):
                            self.count += 1
                            self._not_deleted(key_index - 1)
                    return

            slot = (slot + 1) & modulo_mask

    @always_inline
    fn _is_deleted(self, index: Int) -> Bool:
        var offset = index >> 3
        var bit_index = index & 7
        return self.deleted_mask.offset(offset).load() & (1 << bit_index) != 0

    @always_inline
    fn _deleted(self, index: Int):
        var offset = index >> 3
        var bit_index = index & 7
        var p = self.deleted_mask.offset(offset)
        var mask = p.load()
        p.store(mask | (1 << bit_index))

    @always_inline
    fn _not_deleted(self, index: Int):
        var offset = index >> 3
        var bit_index = index & 7
        var p = self.deleted_mask.offset(offset)
        var mask = p.load()
        p.store(mask & ~(1 << bit_index))

    @always_inline
    fn _rehash(inout self):
        var old_slot_to_index = self.slot_to_index
        var old_capacity = self.capacity
        self.capacity <<= 1
        var mask_capacity = self.capacity >> 3
        self.slot_to_index = DTypePointer[KeyCountType].alloc(self.capacity)
        memset_zero(self.slot_to_index, self.capacity)

        var key_hashes = self.key_hashes

        @parameter
        if caching_hashes:
            key_hashes = DTypePointer[KeyCountType].alloc(self.capacity)

        @parameter
        if destructive:
            var deleted_mask = DTypePointer[DType.uint8].alloc(mask_capacity)
            memset_zero(deleted_mask, mask_capacity)
            memcpy(deleted_mask, self.deleted_mask, old_capacity >> 3)
            self.deleted_mask.free()
            self.deleted_mask = deleted_mask

        var modulo_mask = self.capacity - 1
        for i in range(old_capacity):
            if old_slot_to_index[i] == 0:
                continue
            var key_hash = SIMD[KeyCountType, 1](0)

            @parameter
            if caching_hashes:
                key_hash = self.key_hashes[i]
            else:
                key_hash = hash(self.keys[int(old_slot_to_index[i] - 1)]).cast[KeyCountType]()

            var slot = int(key_hash & modulo_mask)

            # var searching = True
            while True:
                var key_index = int(self.slot_to_index.load(slot))

                if key_index == 0:
                    self.slot_to_index.store(slot, old_slot_to_index[i])
                    break
                    # searching = False

                else:
                    slot = (slot + 1) & modulo_mask

            @parameter
            if caching_hashes:
                key_hashes[slot] = key_hash

        @parameter
        if caching_hashes:
            self.key_hashes.free()
            self.key_hashes = key_hashes
        old_slot_to_index.free()

    fn get(self, key: String, default: V) -> V:
        var key_index = self._find_key_index(key)
        if key_index == 0:
            return default

        @parameter
        if destructive:
            if self._is_deleted(key_index - 1):
                return default
        return self.values[key_index - 1]

    fn delete(inout self, key: String):
        @parameter
        if not destructive:
            return

        var key_index = self._find_key_index(key)
        if key_index == 0:
            return
        if not self._is_deleted(key_index - 1):
            self.count -= 1
        self._deleted(key_index - 1)

    fn upsert(inout self, key: String, update: fn (value: Optional[V]) -> V):
        var key_index = self._find_key_index(key)
        if key_index == 0:
            var value = update(None)
            self.put(key, value)
        else:
            key_index -= 1

            @parameter
            if destructive:
                if self._is_deleted(key_index):
                    self.values[key_index] = update(None)
                    return

            self.values[key_index] = update(self.values[key_index])

    fn clear(inout self):
        self.values.clear()
        self.keys.clear()
        memset_zero(self.slot_to_index, self.capacity)

        @parameter
        if destructive:
            memset_zero(self.deleted_mask, self.capacity >> 3)
        self.count = 0

    @always_inline
    fn _find_key_index(self, key: String) -> Int:
        var key_hash = hash(key).cast[KeyCountType]()
        var modulo_mask = self.capacity - 1

        var slot = int(key_hash & modulo_mask)
        while True:
            var key_index = int(self.slot_to_index.load(slot))
            if key_index == 0:
                return key_index

            @parameter
            if caching_hashes:
                var other_key_hash = self.key_hashes[slot]
                if key_hash == other_key_hash:
                    var other_key = self.keys[key_index - 1]
                    if eq(other_key, key):
                        return key_index
            else:
                var other_key = self.keys[key_index - 1]
                if eq(other_key, key):
                    return key_index

            slot = (slot + 1) & modulo_mask

    fn debug(self):
        print("Dict count:", self.count, "and capacity:", self.capacity)
        print("KeyMap:")
        for i in range(self.capacity):
            var end = ", " if i < self.capacity - 1 else "\n"
            print(self.slot_to_index.load(i), end=end)
        print("Keys:")
        self.keys.print_keys()

        @parameter
        if caching_hashes:
            print("KeyHashes:")
            for i in range(self.capacity):
                var end = ", " if i < self.capacity - 1 else "\n"
                if self.slot_to_index.load(i) > 0:
                    print(self.key_hashes.load(i), end=end)
                else:
                    print(0, end=end)
