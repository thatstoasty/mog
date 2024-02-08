from ..http.header import Header
from ..io import io
from ..stdlib_extensions.builtins._bytes import bytes, Byte


@value
struct DefaultReadCloser(io.ReadCloser):
    fn read(inout self, inout b: bytes) -> Int:
        # TODO: Implement
        return 1

    fn close(inout self, b: bytes) -> Int:
        # TODO: Implement
        return 1


@value
struct Response(CollectionElement):
    var Status: String  # e.g. "200 OK"
    var StatusCode: Int  # e.g. 200
    var Proto: String  # e.g. "HTTP/1.0"
    var ProtoMajor: Int  # e.g. 1
    var ProtoMinor: Int  # e.g. 0

    # Header maps header keys to values. If the response had multiple
    # headers with the same key, they may be concatenated, with comma
    # delimiters.  (RFC 7230, section 3.2.2 requires that multiple headers
    # be semantically equivalent to a comma-delimited sequence.) When
    # Header values are duplicated by other fields in this struct (e.g.,
    # ContentLength, TransferEncoding, Trailer), the field values are
    # authoritative.
    #
    # Keys in the map are canonicalized (see CanonicalHeaderKey).
    var Header: Header

    # Body represents the response body.
    #
    # The response body is streamed on demand as the Body field
    # is read. If the network connection fails or the server
    # terminates the response, Body.Read calls return an error.
    #
    # The http Client and Transport guarantee that Body is always
    # non-nil, even on responses without a body or responses with
    # a zero-length body. It is the caller's responsibility to
    # close Body. The default HTTP client's Transport may not
    # reuse HTTP/1.x "keep-alive" TCP connections if the Body is
    # not read to completion and closed.
    #
    # The Body is automatically dechunked if the server replied
    # with a "chunked" Transfer-Encoding.
    #
    # As of Go 1.12, the Body will also implement io.Writer
    # on a successful "101 Switching Protocols" response,
    # as used by WebSockets and HTTP/2's "h2c" mode.
    var Body: DefaultReadCloser  # TODO: This should be a concrete ReadCloser, not a trait

    # ContentLength records the length of the associated content. The
    # value -1 indicates that the length is unknown. Unless Request.Method
    # is "HEAD", values >= 0 indicate that the given number of bytes may
    # be read from Body.
    var ContentLength: Int64

    # # Contains transfer encodings from outer-most to inner-most. Value is
    # # nil, means that "identity" encoding is used.
    # TransferEncoding DynamicVector[String]

    # Close records whether the header directed that the connection be
    # closed after reading Body. The value is advice for clients: neither
    # ReadResponse nor Response.Write ever closes a connection.
    var Close: Bool

    # # Uncompressed reports whether the response was sent compressed but
    # # was decompressed by the http package. When true, reading from
    # # Body yields the uncompressed content instead of the compressed
    # # content actually set from the server, ContentLength is set to -1,
    # # and the "Content-Length" and "Content-Encoding" fields are deleted
    # # from the responseHeader. To get the original response from
    # # the server, set Transport.DisableCompression to true.
    # Uncompressed bool

    # # Trailer maps trailer keys to values in the same
    # # format as Header.
    # #
    # # The Trailer initially contains only nil values, one for
    # # each key specified in the server's "Trailer" header
    # # value. Those values are not added to Header.
    # #
    # # Trailer must not be accessed concurrently with Read calls
    # # on the Body.
    # #
    # # After Body.Read has returned io.EOF, Trailer will contain
    # # any trailer values sent by the server.
    # Trailer Header

    # Request is the request that was sent to obtain this Response.
    # Request's Body is nil (having already been consumed).
    # This is only populated for Client requests.
    # var Request: Request

    # # TLS contains information about the TLS connection on which the
    # # response was received. It is nil for unencrypted responses.
    # # The poInter is shared between responses and should not be
    # # modified.
    # TLS *tls.ConnectionState
