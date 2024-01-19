from memory import memset
from math import min
from utils.list import Dim

from stormlight.weave.extensions.libc.stdio import fopen, fread, fclose, fwrite
from stormlight.weave.extensions.libc.string import strnlen

alias c_char = UInt8
alias FILE = UInt64
alias BUF_SIZE = 4096


fn to_char_ptr(s: String) -> Pointer[c_char]:
    """Only ASCII-based strings."""
    let ptr = Pointer[c_char]().alloc(len(s) + 1)
    for i in range(len(s)):
        ptr.store(i, ord(s[i]))
    ptr.store(len(s), ord("\0"))
    return ptr


struct File:
    var handle: Pointer[UInt64]
    var fname: Pointer[c_char]
    var mode: Pointer[c_char]

    fn __init__(inout self, filename: String, mode: StringLiteral):
        let fname = to_char_ptr(filename)

        let mode_cstr = to_char_ptr(mode)
        let handle = fopen(fname, mode_cstr)

        self.fname = fname
        self.mode = mode_cstr
        self.handle = handle

    fn __bool__(self) -> Bool:
        return self.handle.__bool__()

    fn __del__(owned self):
        if self.handle:
            pass
            # TODO: uncomment when external_call resolution bug is fixed
            # let c = fclose(self.handle)
            # if c != 0:
            #     raise Error("Failed to close file")
        if self.fname:
            self.fname.free()
        if self.mode:
            self.mode.free()

    fn __moveinit__(inout self, owned other: Self):
        self.fname = other.fname
        self.mode = other.mode
        self.handle = other.handle
        other.handle = Pointer[FILE]()
        other.fname = Pointer[c_char]()
        other.mode = Pointer[c_char]()

    fn do_nothing(self):
        pass

    fn read[D: Dim](self, buffer: Buffer[D, DType.uint8]) raises -> Int:
        return fread(
            buffer.data._as_scalar_pointer(), sizeof[UInt8](), BUF_SIZE, self.handle
        ).to_int()

    fn write[D: Dim](self, buffer: Buffer[D, DType.uint8]) -> Int:
        return fwrite(
            buffer.data._as_scalar_pointer(), sizeof[UInt8](), len(buffer), self.handle
        ).to_int()

    fn write_all[D: Dim](self, buffer: Buffer[D, DType.uint8]):
        var index = 0
        while index != len(buffer):
            index += self.write(buffer)

    fn write_byte(self, byte: UInt8) raises:
        let buf = Buffer[1, DType.uint8]().stack_allocation()
        buf[0] = byte
        self.write_all(buf)

    fn write_byte_n_times(self, byte: UInt8, n: Int) raises:
        var bytes = StaticTuple[256, UInt8]()
        let bytes_ptr = DTypePointer[DType.uint8](
            Pointer.address_of(bytes).bitcast[UInt8]()
        )
        memset[DType.uint8](
            bytes_ptr,
            byte,
            256,
        )
        var remaining = n
        while remaining > 0:
            let to_write = min(remaining, bytes.__len__())
            self.write_all(Buffer[Dim(), DType.uint8](bytes_ptr, to_write))
            remaining -= to_write
