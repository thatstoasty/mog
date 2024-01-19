"""
A port of Zig's BufferedReader.

Example:
========

from shims.file import File
from shims.read import BufReader
from shims.write import BufWriter
from memory.buffer import Buffer


fn main() raises:
    let f = File("a.txt", "r")
    let out_f = File("a2.txt", "w+")
    var reader = BufReader[4096](f ^)
    var writer = BufWriter[4096](out_f ^)
    let buf = Buffer[256, DType.uint8]().stack_allocation()
    var bytes_read = 1
    while bytes_read > 0:
        bytes_read = reader.read(buf)
        if bytes_read > 0:
            print(
                StringRef(
                    buf.data.as_scalar_pointer()
                    .bitcast[__mlir_type.`!pop.scalar<si8>`]()
                    .address,
                    bytes_read,
                )
            )
            let write_buf = Buffer[Dim(), DType.uint8](buf.data, bytes_read)
            let bytes_written = writer.write(write_buf)
            _ = bytes_written

"""
from stormlight.weave.extensions.file import File
from utils.list import Dim
from memory import memcpy


struct BufWriter[BUF_SIZE: Int]:
    var unbuffered_writer: File
    var data: DTypePointer[DType.uint8]
    var end: Int

    fn __init__(inout self, owned writer: File):
        self.unbuffered_writer = writer ^
        self.data = DTypePointer[DType.uint8]().alloc(BUF_SIZE)
        self.end = 0

    fn __del__(owned self):
        self.flush()

    fn flush(inout self):
        self.unbuffered_writer.write_all(
            Buffer[Dim(), DType.uint8](self.data, self.end)
        )
        self.end = 0

    fn write[D: Dim](inout self, bytes: Buffer[D, DType.uint8]) raises -> Int:
        if self.end + len(bytes) > BUF_SIZE:
            self.flush()
            if len(bytes) > BUF_SIZE:
                return self.unbuffered_writer.write(bytes)
        let new_end = self.end + len(bytes)
        memcpy(self.data.offset(self.end), bytes.data, new_end - self.end)
        self.end = new_end
        return len(bytes)

    fn write(inout self, str: StringRef) raises -> Int:
        var strbuf = DynamicVector[UInt8]()
        for i in range(len(str)):
            strbuf.push_back(ord(str[i]))
        let buf = Buffer[Dim(), DType.uint8](strbuf.data.value, len(strbuf))

        return self.write(buf)
