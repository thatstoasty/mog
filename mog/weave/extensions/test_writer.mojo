from stormlight.weave.extensions.file import File
from stormlight.weave.extensions.read import BufReader
from stormlight.weave.extensions.write import BufWriter
from memory.buffer import Buffer
from utils.list import Dim


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
                    buf.data._as_scalar_pointer()
                    .bitcast[__mlir_type.`!pop.scalar<si8>`]()
                    .address,
                    bytes_read,
                )
            )
            let write_buf = Buffer[Dim(), DType.uint8](buf.data, bytes_read)
            let bytes_written = writer.write(write_buf)
            _ = bytes_written
