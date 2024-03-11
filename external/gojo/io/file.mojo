from ..builtins._bytes import Bytes, Byte
from ..builtins import copy


struct FileWrapper(io.ReadWriteSeeker, io.ByteReader):
    var handle: FileHandle

    fn __init__(inout self, path: String, mode: StringLiteral) raises:
        self.handle = open(path, mode)

    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle ^

    fn __del__(owned self):
        try:
            self.close()
        except Error:
            # TODO: __del__ can't raise, but there should be some fallback.
            print("Failed to close the file.")

    fn close(inout self) raises:
        self.handle.close()

    fn read(inout self, inout dest: Bytes) raises -> Int:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result = self.handle.read()
        if len(result) == 0:
            raise Error(io.EOF)

        var elements_copied = copy(dest, Bytes(result))
        dest = dest[:elements_copied]
        return elements_copied

    fn read(inout self, inout dest: Bytes, size: Int64) raises -> Int:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result = self.handle.read(size)
        if len(result) == 0:
            raise Error(io.EOF)

        var elements_copied = copy(dest, Bytes(result))
        dest = dest[:elements_copied]
        return elements_copied

    fn read_byte(inout self) raises -> Byte:
        return self.read_bytes(1)[0]

    fn read_bytes(inout self, size: Int64) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes(size)

    fn read_bytes(inout self) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes()

    fn stream_until_delimiter(
        inout self, inout dest: Bytes, delimiter: Int8, max_size: Int
    ) raises:
        for i in range(max_size):
            var byte = self.read_byte()
            if byte == delimiter:
                return
            dest.append(byte)
        raise Error("Stream too long")

    fn seek(inout self, offset: Int64, whence: Int = 0) raises -> Int64:
        return self.handle.seek(offset.cast[DType.uint64]()).cast[DType.int64]()

    fn write(inout self, src: Bytes) raises -> Int:
        self.handle.write(String(src))
        return len(src)
