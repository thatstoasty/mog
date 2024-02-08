from ..buffers._bytes import to_bytes
from ..stdlib_extensions.builtins._bytes import bytes, Byte

alias Rune = Int32

# Copyright 2009 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Package io provides basic interfaces to I/O primitives.
# Its primary job is to wrap existing implementations of such primitives,
# such as those in package os, into shared public interfaces that
# abstract the fntionality, plus some other related primitives.
#
# Because these interfaces and primitives wrap lower-level operations with
# various implementations, unless otherwise informed clients should not
# assume they are safe for parallel execution.
# Seek whence values.
alias seek_start: UInt8 = 0  # seek relative to the origin of the file
alias seek_current: UInt8 = 1  # seek relative to the current offset
alias seek_end: UInt8 = 2  # seek relative to the end

# ErrShortWrite means that a write accepted fewer bytes than requested
# but failed to return an explicit error.
alias ErrShortWrite = "short write"

# errInvalidWrite means that a write returned an impossible count.
alias errInvalidWrite = "invalid write result"

# ErrShortBuffer means that a read required a longer buffer than was provided.
alias ErrShortBuffer = "short buffer"

# EOF is the error returned by Read when no more input is available.
# (Read must return EOF itself, not an error wrapping EOF,
# because callers will test for EOF using ==.)
# fntions should return EOF only to signal a graceful end of input.
# If the EOF occurs unexpectedly in a structured data stream,
# the appropriate error is either [ErrUnexpectedEOF] or some other error
# giving more detail.
alias EOF = "EOF"

# ErrUnexpectedEOF means that EOF was encountered in the
# middle of reading a fixed-size block or data structure.
alias ErrUnexpectedEOF = "unexpected EOF"

# ErrNoProgress is returned by some clients of a [Reader] when
# many calls to Read have failed to return any data or error,
# usually the sign of a broken [Reader] implementation.
alias ErrNoProgress = "multiple Read calls return no data or error"


# Reader is the interface that wraps the basic Read method.
#
# Read reads up to len(p) bytes into p. It returns the number of bytes
# read (0 <= n <= len(p)) and any error encountered. Even if Read
# returns n < len(p), it may use all of p as scratch space during the call.
# If some data is available but not len(p) bytes, Read conventionally
# returns what is available instead of waiting for more.
#
# When Read encounters an error or end-of-file condition after
# successfully reading n > 0 bytes, it returns the number of
# bytes read. It may return the (non-nil) error from the same call
# or return the error (and n == 0) from a subsequent call.
# An instance of this general case is that a Reader returning
# a non-zero number of bytes at the end of the input stream may
# return either err == EOF or err == nil. The next Read should
# return 0, EOF.
#
# Callers should always process the n > 0 bytes returned before
# considering the error err. Doing so correctly handles I/O errors
# that happen after reading some bytes and also both of the
# allowed EOF behaviors.
#
# If len(p) == 0, Read should always return n == 0. It may return a
# non-nil error if some error condition is known, such as EOF.
#
# Implementations of Read are discouraged from returning a
# zero byte count with a nil error, except when len(p) == 0.
# Callers should treat a return of 0 and nil as indicating that
# nothing happened; in particular it does not indicate EOF.
#
# Implementations must not retain p.
trait Reader(Movable, Copyable):
    fn read(inout self, inout b: bytes) -> Int:
        ...


# Writer is the interface that wraps the basic Write method.
#
# Write writes len(p) bytes from p to the underlying data stream.
# It returns the number of bytes written from p (0 <= n <= len(p))
# and any error encountered that caused the write to stop early.
# Write must return a non-nil error if it returns n < len(p).
# Write must not modify the slice data, even temporarily.
#
# Implementations must not retain p.
trait Writer(Movable, Copyable):
    fn write(inout self, b: bytes) raises -> Int:
        ...


# Closer is the interface that wraps the basic Close method.
#
# The behavior of Close after the first call is undefined.
# Specific implementations may document their own behavior.
trait Closer(Movable, Copyable):
    fn close(inout self, b: bytes) -> Int:
        ...


# Seeker is the interface that wraps the basic Seek method.
#
# Seek sets the offset for the next Read or Write to offset,
# interpreted according to whence:
# [seek_start] means relative to the start of the file,
# [seek_current] means relative to the current offset, and
# [seek_end] means relative to the end
# (for example, offset = -2 specifies the penultimate byte of the file).
# Seek returns the new offset relative to the start of the
# file or an error, if any.
#
# Seeking to an offset before the start of the file is an error.
# Seeking to any positive offset may be allowed, but if the new offset exceeds
# the size of the underlying object the behavior of subsequent I/O operations
# is implementation-dependent.
trait Seeker(Movable, Copyable):
    fn seek(inout self, offset: Int64, whence: Int) -> Int:
        ...


trait ReadWriter(Reader, Writer):
    ...


trait ReadCloser(Reader, Closer):
    ...


trait WriteCloser(Writer, Closer):
    ...


trait ReadWriteCloser(Reader, Writer, Closer):
    ...


trait ReadSeeker(Reader, Seeker):
    ...


trait ReadSeekCloser(Reader, Seeker, Closer):
    ...


trait WriteSeeker(Writer, Seeker):
    ...


trait ReadWriteSeeker(Reader, Writer, Seeker):
    ...


# ReaderFrom is the interface that wraps the ReadFrom method.
#
# ReadFrom reads data from r until EOF or error.
# The return value n is the number of bytes read.
# Any error except EOF encountered during the read is also returned.
#
# The [Copy] fntion uses [ReaderFrom] if available.
trait ReaderFrom:
    fn read_from[R: Reader](self, r: R) -> Int:
        ...


trait WriterReadFrom(Writer, ReaderFrom):
    ...


# WriterTo is the interface that wraps the WriteTo method.
#
# WriteTo writes data to w until there's no more data to write or
# when an error occurs. The return value n is the number of bytes
# written. Any error encountered during the write is also returned.
#
# The Copy fntion uses WriterTo if available.
trait WriterTo:
    fn write_to[W: Writer](self, w: W) -> Int:
        ...


trait ReaderWriteTo(Reader, WriterTo):
    ...


# ReaderAt is the interface that wraps the basic ReadAt method.
#
# ReadAt reads len(p) bytes into p starting at offset off in the
# underlying input source. It returns the number of bytes
# read (0 <= n <= len(p)) and any error encountered.
#
# When ReadAt returns n < len(p), it returns a non-nil error
# explaining why more bytes were not returned. In this respect,
# ReadAt is stricter than Read.
#
# Even if ReadAt returns n < len(p), it may use all of p as scratch
# space during the call. If some data is available but not len(p) bytes,
# ReadAt blocks until either all the data is available or an error occurs.
# In this respect ReadAt is different from Read.
#
# If the n = len(p) bytes returned by ReadAt are at the end of the
# input source, ReadAt may return either err == EOF or err == nil.
#
# If ReadAt is reading from an input source with a seek offset,
# ReadAt should not affect nor be affected by the underlying
# seek offset.
#
# Clients of ReadAt can execute parallel ReadAt calls on the
# same input source.
#
# Implementations must not retain p.
trait ReaderAt:
    fn read_at(self, b: bytes, off: Int64) -> Int:
        ...


# WriterAt is the interface that wraps the basic WriteAt method.
#
# WriteAt writes len(p) bytes from p to the underlying data stream
# at offset off. It returns the number of bytes written from p (0 <= n <= len(p))
# and any error encountered that caused the write to stop early.
# WriteAt must return a non-nil error if it returns n < len(p).
#
# If WriteAt is writing to a destination with a seek offset,
# WriteAt should not affect nor be affected by the underlying
# seek offset.
#
# Clients of WriteAt can execute parallel WriteAt calls on the same
# destination if the ranges do not overlap.
#
# Implementations must not retain p.
trait WriterAt:
    fn write_at(self, b: bytes, off: Int64) -> Int:
        ...


# ByteReader is the interface that wraps the ReadByte method.
#
# ReadByte reads and returns the next byte from the input or
# any error encountered. If ReadByte returns an error, no input
# byte was consumed, and the returned byte value is undefined.
#
# ReadByte provides an efficient interface for byte-at-time
# processing. A [Reader] that does not implement  ByteReader
# can be wrapped using bufio.NewReader to add this method.
trait ByteReader:
    fn read_byte(self) -> Byte:
        ...


# ByteScanner is the interface that adds the UnreadByte method to the
# basic ReadByte method.
#
# UnreadByte causes the next call to ReadByte to return the last byte read.
# If the last operation was not a successful call to ReadByte, UnreadByte may
# return an error, unread the last byte read (or the byte prior to the
# last-unread byte), or (in implementations that support the [Seeker] interface)
# seek to one byte before the current offset.
trait ByteScanner:
    fn unread_byte(self) -> Byte:
        ...


# ByteWriter is the interface that wraps the WriteByte method.
trait ByteWriter:
    fn write_byte(self, c: Byte) -> Int:
        ...


# RuneReader is the interface that wraps the ReadRune method.
#
# ReadRune reads a single encoded Unicode character
# and returns the rune and its size in bytes. If no character is
# available, err will be set.
trait RuneReader:
    fn read_rune(self) -> (Rune, Int):
        ...


# RuneScanner is the interface that adds the UnreadRune method to the
# basic ReadRune method.
#
# UnreadRune causes the next call to ReadRune to return the last rune read.
# If the last operation was not a successful call to ReadRune, UnreadRune may
# return an error, unread the last rune read (or the rune prior to the
# last-unread rune), or (in implementations that support the [Seeker] interface)
# seek to the start of the rune before the current offset.
trait RuneScanner(RuneReader):
    fn unread_rune(self) -> Rune:
        ...


# StringWriter is the interface that wraps the WriteString method.
trait StringWriter:
    fn write_string(self, s: String) -> Int:
        ...


# WriteString writes the contents of the string s to w, which accepts a slice of bytes.
# If w implements [StringWriter], [StringWriter.WriteString] is invoked directly.
# Otherwise, [Writer.Write] is called exactly once.
fn write_string[T: Writer](inout w: T, s: String) raises -> Int:
    var s_buffer = to_bytes(s)
    return w.write(s_buffer)


fn write_string[T: StringWriter](w: T, s: String) -> Int:
    return w.write_string(s)


# read_at_least reads from r into buf until it has read at least min bytes.
# It returns the number of bytes copied and an error if fewer bytes were read.
# The error is EOF only if no bytes were read.
# If an EOF happens after reading fewer than min bytes,
# read_at_least returns [ErrUnexpectedEOF].
# If min is greater than the length of buf, read_at_least returns [ErrShortBuffer].
# On return, n >= min if and only if err == nil.
# If r returns an error having read at least min bytes, the error is dropped.
fn read_at_least[R: Reader](inout r: R, buf: bytes, min: Int) raises -> Int:
    if len(buf) < min:
        raise Error(ErrShortBuffer)

    var n: Int = 0
    while n < min:
        var sl = buf[n:]
        let nn: Int = r.read(sl)
        n += nn

    return n


fn read_full[R: Reader](inout r: R, buf: bytes) raises -> Int:
    """Reads exactly len(buf) bytes from r into buf.
    It returns the number of bytes copied and an error if fewer bytes were read.
    The error is EOF only if no bytes were read.
    If an EOF happens after reading some but not all the bytes,
    read_full returns [ErrUnexpectedEOF].
    On return, n == len(buf) if and only if err == nil.
    If r returns an error having read at least len(buf) bytes, the error is dropped.
    """
    return read_at_least(r, buf, len(buf))


# fn copy_n[W: Writer, R: Reader](dst: W, src: R, n: Int64) raises -> Int64:
#     """Copies n bytes (or until an error) from src to dst.
#     It returns the number of bytes copied and the earliest
#     error encountered while copying.
#     On return, written == n if and only if err == nil.

#     If dst implements [ReaderFrom], the copy is implemented using it.
#     """
#     let written = copy(dst, LimitReader(src, n))
#     if written == n:
#         return n

#     if written < n:
#         # src stopped early; must have been EOF.
#         raise Error(ErrUnexpectedEOF)

#     return written


# fn copy[W: Writer, R: Reader](dst: W, src: R, n: Int64) -> Int64:
#     """Copy copies from src to dst until either EOF is reached
# on src or an error occurs. It returns the number of bytes
# copied and the first error encountered while copying, if any.

# A successful Copy returns err == nil, not err == EOF.
# Because Copy is defined to read from src until EOF, it does
# not treat an EOF from Read as an error to be reported.

# If src implements [WriterTo],
# the copy is implemented by calling src.WriteTo(dst).
# Otherwise, if dst implements [ReaderFrom],
# the copy is implemented by calling dst.ReadFrom(src).
# """
#     return copy_buffer(dst, src, nil)

# # CopyBuffer is identical to Copy except that it stages through the
# # provided buffer (if one is required) rather than allocating a
# # temporary one. If buf is nil, one is allocated; otherwise if it has
# # zero length, CopyBuffer panics.
# #
# # If either src implements [WriterTo] or dst implements [ReaderFrom],
# # buf will not be used to perform the copy.
# fn CopyBuffer(dst Writer, src Reader, buf bytes) (written int64, err error) {
# 	if buf != nil and len(buf) == 0 {
# 		panic("empty buffer in CopyBuffer")
# 	}
# 	return copy_buffer(dst, src, buf)
# }


# fn copy_buffer[W: Writer, R: Reader](dst: W, src: R, buf: bytes) raises -> Int64:
#     """Actual implementation of Copy and CopyBuffer.
#     if buf is nil, one is allocated.
#     """
#     let nr: Int
#     nr = src.read(buf)
#     while True:
#         if nr > 0:
#             let nw: Int
#             nw = dst.write(get_slice(buf, 0, nr))
#             if nw < 0 or nr < nw:
#                 nw = 0

#             let written = Int64(nw)
#             if nr != nw:
#                 raise Error(ErrShortWrite)

#     return written


# fn copy_buffer[W: Writer, R: ReaderWriteTo](dst: W, src: R, buf: bytes) -> Int64:
#     return src.write_to(dst)


# fn copy_buffer[W: WriterReadFrom, R: Reader](dst: W, src: R, buf: bytes) -> Int64:
#     return dst.read_from(src)

# # LimitReader returns a Reader that reads from r
# # but stops with EOF after n bytes.
# # The underlying implementation is a *LimitedReader.
# fn LimitReader(r Reader, n int64) Reader { return &LimitedReader{r, n} }

# # A LimitedReader reads from R but limits the amount of
# # data returned to just N bytes. Each call to Read
# # updates N to reflect the new amount remaining.
# # Read returns EOF when N <= 0 or when the underlying R returns EOF.
# struct LimitedReader():
# 	var R: Reader # underlying reader
# 	N int64  # max bytes remaining

# fn (l *LimitedReader) Read(p bytes) (n Int, err error) {
# 	if l.N <= 0 {
# 		return 0, EOF
# 	}
# 	if int64(len(p)) > l.N {
# 		p = p[0:l.N]
# 	}
# 	n, err = l.R.Read(p)
# 	l.N -= int64(n)
# 	return
# }

# # NewSectionReader returns a [SectionReader] that reads from r
# # starting at offset off and stops with EOF after n bytes.
# fn NewSectionReader(r ReaderAt, off int64, n int64) *SectionReader {
# 	var remaining int64
# 	const maxint64 = 1<<63 - 1
# 	if off <= maxint64-n {
# 		remaining = n + off
# 	} else {
# 		# Overflow, with no way to return error.
# 		# Assume we can read up to an offset of 1<<63 - 1.
# 		remaining = maxint64
# 	}
# 	return &SectionReader{r, off, off, remaining, n}
# }

# # SectionReader implements Read, Seek, and ReadAt on a section
# # of an underlying [ReaderAt].
# type SectionReader struct {
# 	r     ReaderAt # constant after creation
# 	base  int64    # constant after creation
# 	off   int64
# 	limit int64 # constant after creation
# 	n     int64 # constant after creation
# }

# fn (s *SectionReader) Read(p bytes) (n Int, err error) {
# 	if s.off >= s.limit {
# 		return 0, EOF
# 	}
# 	if max := s.limit - s.off; int64(len(p)) > max {
# 		p = p[0:max]
# 	}
# 	n, err = s.r.ReadAt(p, s.off)
# 	s.off += int64(n)
# 	return
# }

# alias errWhence = "Seek: invalid whence"
# alias errOffset = "Seek: invalid offset"

# fn (s *SectionReader) Seek(offset int64, whence Int) (int64, error) {
# 	switch whence {
# 	default:
# 		return 0, errWhence
# 	case seek_start:
# 		offset += s.base
# 	case seek_current:
# 		offset += s.off
# 	case seek_end:
# 		offset += s.limit
# 	}
# 	if offset < s.base {
# 		return 0, errOffset
# 	}
# 	s.off = offset
# 	return offset - s.base, nil
# }

# fn (s *SectionReader) ReadAt(p bytes, off int64) (n Int, err error) {
# 	if off < 0 or off >= s.Size() {
# 		return 0, EOF
# 	}
# 	off += s.base
# 	if max := s.limit - off; int64(len(p)) > max {
# 		p = p[0:max]
# 		n, err = s.r.ReadAt(p, off)
# 		if err == nil {
# 			err = EOF
# 		}
# 		return n, err
# 	}
# 	return s.r.ReadAt(p, off)
# }

# # Size returns the size of the section in bytes.
# fn (s *SectionReader) Size() int64 { return s.limit - s.base }

# # Outer returns the underlying [ReaderAt] and offsets for the section.
# #
# # The returned values are the same that were passed to [NewSectionReader]
# # when the [SectionReader] was created.
# fn (s *SectionReader) Outer() (r ReaderAt, off int64, n int64) {
# 	return s.r, s.base, s.n
# }

# # An OffsetWriter maps writes at offset base to offset base+off in the underlying writer.
# type OffsetWriter struct {
# 	w    WriterAt
# 	base int64 # the original offset
# 	off  int64 # the current offset
# }

# # NewOffsetWriter returns an [OffsetWriter] that writes to w
# # starting at offset off.
# fn NewOffsetWriter(w WriterAt, off int64) *OffsetWriter {
# 	return &OffsetWriter{w, off, off}
# }

# fn (o *OffsetWriter) Write(p bytes) (n Int, err error) {
# 	n, err = o.w.WriteAt(p, o.off)
# 	o.off += int64(n)
# 	return
# }

# fn (o *OffsetWriter) WriteAt(p bytes, off int64) (n Int, err error) {
# 	if off < 0 {
# 		return 0, errOffset
# 	}

# 	off += o.base
# 	return o.w.WriteAt(p, off)
# }

# fn (o *OffsetWriter) Seek(offset int64, whence Int) (int64, error) {
# 	switch whence {
# 	default:
# 		return 0, errWhence
# 	case seek_start:
# 		offset += o.base
# 	case seek_current:
# 		offset += o.off
# 	}
# 	if offset < o.base {
# 		return 0, errOffset
# 	}
# 	o.off = offset
# 	return offset - o.base, nil
# }

# # TeeReader returns a [Reader] that writes to w what it reads from r.
# # All reads from r performed through it are matched with
# # corresponding writes to w. There is no internal buffering -
# # the write must complete before the read completes.
# # Any error encountered while writing is reported as a read error.
# fn TeeReader(r Reader, w Writer) Reader {
# 	return &teeReader{r, w}
# }

# type teeReader struct {
# 	r Reader
# 	w Writer
# }

# fn (t *teeReader) Read(p bytes) (n Int, err error) {
# 	n, err = t.r.Read(p)
# 	if n > 0 {
# 		if n, err := t.w.Write(p[:n]); err != nil {
# 			return n, err
# 		}
# 	}
# 	return
# }

# # Discard is a [Writer] on which all Write calls succeed
# # without doing anything.
# var Discard Writer = discard{}

# type discard struct{}

# # discard implements ReaderFrom as an optimization so Copy to
# # io.Discard can avoid doing unnecessary work.
# var _ ReaderFrom = discard{}

# fn (discard) Write(p bytes) (Int, error) {
# 	return len(p), nil
# }

# fn (discard) WriteString(s string) (Int, error) {
# 	return len(s), nil
# }

# var blackHolePool = sync.Pool{
# 	New: fn() any {
# 		b := make(bytes, 8192)
# 		return &b
# 	},
# }

# fn (discard) ReadFrom(r Reader) (n int64, err error) {
# 	bufp := blackHolePool.Get().(*bytes)
# 	readSize := 0
# 	for {
# 		readSize, err = r.Read(*bufp)
# 		n += int64(readSize)
# 		if err != nil {
# 			blackHolePool.Put(bufp)
# 			if err == EOF {
# 				return n, nil
# 			}
# 			return
# 		}
# 	}
# }

# # NopCloser returns a [ReadCloser] with a no-op Close method wrapping
# # the provided [Reader] r.
# # If r implements [WriterTo], the returned [ReadCloser] will implement [WriterTo]
# # by forwarding calls to r.
# fn NopCloser(r Reader) ReadCloser {
# 	if _, ok := r.(WriterTo); ok {
# 		return nopCloserWriterTo{r}
# 	}
# 	return nopCloser{r}
# }

# type nopCloser struct {
# 	Reader
# }

# fn (nopCloser) Close() error { return nil }

# type nopCloserWriterTo struct {
# 	Reader
# }

# fn (nopCloserWriterTo) Close() error { return nil }

# fn (c nopCloserWriterTo) WriteTo(w Writer) (n int64, err error) {
# 	return c.Reader.(WriterTo).WriteTo(w)
# }

# # ReadAll reads from r until an error or EOF and returns the data it read.
# # A successful call returns err == nil, not err == EOF. Because ReadAll is
# # defined to read from src until EOF, it does not treat an EOF from Read
# # as an error to be reported.
# fn ReadAll(r Reader) (bytes, error) {
# 	b := make(bytes, 0, 512)
# 	for {
# 		n, err := r.Read(b[len(b):cap(b)])
# 		b = b[:len(b)+n]
# 		if err != nil {
# 			if err == EOF {
# 				err = nil
# 			}
# 			return b, err
# 		}

# 		if len(b) == cap(b) {
# 			# Add more capacity (let append pick how much).
# 			b = append(b, 0)[:len(b)]
# 		}
# 	}
# }
