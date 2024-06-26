import ..io
from ..builtins import copy
from ..syscall import FileDescriptorBase


struct FileWrapper(FileDescriptorBase, io.ByteReader):
    var handle: FileHandle

    @always_inline
    fn __init__(inout self, path: String, mode: String) raises:
        self.handle = open(path, mode)

    @always_inline
    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle^

    @always_inline
    fn __del__(owned self):
        var err = self.close()
        if err:
            # TODO: __del__ can't raise, but there should be some fallback.
            print(str(err))

    @always_inline
    fn close(inout self) -> Error:
        try:
            self.handle.close()
        except e:
            return e

        return Error()

    @always_inline
    fn _read(inout self, inout dest: Span[UInt8, True], capacity: Int) -> (Int, Error):
        """Read from the file handle into dest's pointer.
        Pretty hacky way to force the filehandle read into the defined trait, and it's unsafe since we're
        reading directly into the pointer.
        """
        # var bytes_to_read = dest.capacity - len(dest)
        var bytes_read: Int
        var result: List[UInt8]
        try:
            result = self.handle.read_bytes()
            bytes_read = len(result)
            # TODO: Need to raise an Issue for this. Reading with pointer does not return an accurate count of bytes_read :(
            # bytes_read = int(self.handle.read(DTypePointer[DType.uint8](dest.unsafe_ptr()) + dest.size))
        except e:
            return 0, e

        _ = copy(dest, Span(result), len(dest))

        if bytes_read == 0:
            return bytes_read, io.EOF

        return bytes_read, Error()

    @always_inline
    fn read(inout self, inout dest: List[UInt8]) -> (Int, Error):
        """Read from the file handle into dest's pointer.
        Pretty hacky way to force the filehandle read into the defined trait, and it's unsafe since we're
        reading directly into the pointer.
        """
        # var bytes_to_read = dest.capacity - len(dest)
        var bytes_read: Int
        var result: List[UInt8]
        try:
            result = self.handle.read_bytes()
            bytes_read = len(result)
            # TODO: Need to raise an Issue for this. Reading with pointer does not return an accurate count of bytes_read :(
            # bytes_read = int(self.handle.read(DTypePointer[DType.uint8](dest.unsafe_ptr()) + dest.size))
        except e:
            return 0, e

        _ = copy(dest, result, len(dest))

        if bytes_read == 0:
            return bytes_read, io.EOF

        return bytes_read, Error()

    @always_inline
    fn read_all(inout self) -> (List[UInt8], Error):
        var bytes = List[UInt8](capacity=io.BUFFER_SIZE)
        while True:
            var temp = List[UInt8](capacity=io.BUFFER_SIZE)
            _ = self.read(temp)

            # If new bytes will overflow the result, resize it.
            if len(bytes) + len(temp) > bytes.capacity:
                bytes.reserve(bytes.capacity * 2)
            bytes.extend(temp)

            if len(temp) < io.BUFFER_SIZE:
                return bytes, io.EOF

    @always_inline
    fn read_byte(inout self) -> (UInt8, Error):
        try:
            var bytes: List[UInt8]
            var err: Error
            bytes, err = self.read_bytes(1)
            return bytes[0], Error()
        except e:
            return UInt8(0), e

    @always_inline
    fn read_bytes(inout self, size: Int = -1) raises -> (List[UInt8], Error):
        try:
            return self.handle.read_bytes(size), Error()
        except e:
            return List[UInt8](), e

    @always_inline
    fn stream_until_delimiter(inout self, inout dest: List[UInt8], delimiter: UInt8, max_size: Int) -> Error:
        var byte: UInt8
        var err = Error()
        for _ in range(max_size):
            byte, err = self.read_byte()
            if err:
                return err

            if byte == delimiter:
                return err
            dest.append(byte)
        return Error("Stream too long")

    @always_inline
    fn seek(inout self, offset: Int, whence: Int = 0) -> (Int, Error):
        try:
            var position = self.handle.seek(UInt64(offset), whence)
            return int(position), Error()
        except e:
            return 0, e

    @always_inline
    fn _write(inout self, src: Span[UInt8]) -> (Int, Error):
        if len(src) == 0:
            return 0, Error("No data to write")

        try:
            self.handle.write(src.unsafe_ptr())
            return len(src), io.EOF
        except e:
            return 0, Error(str(e))

    @always_inline
    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        return self._write(Span(src))
