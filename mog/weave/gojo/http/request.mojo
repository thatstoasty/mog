from ..http.url import URL
from ..http.response import Response, DefaultReadCloser
from ..http.header import Header


@value
struct Request(Movable, Copyable):
    # Method specifies the HTTP method (GET, POST, PUT, etc.).
    # For client requests, an empty String means GET.
    var method: String

    # URL specifies either the URI being requested (for server
    # requests) or the URL to access (for client requests).
    #
    # For server requests, the URL is parsed from the URI
    # supplied on the Request-Line as stored in RequestURI.  For
    # most requests, fields other than Path and RawQuery will be
    # empty. (See RFC 7230, Section 5.3)
    #
    # For client requests, the URL's Host specifies the server to
    # connect to, while the Request's Host field optionally
    # specifies the Host header value to send in the HTTP
    # request.
    var url: url.URL

    # The protocol version for incoming server requests.
    #
    # For client requests, these fields are ignored. The HTTP
    # client code always uses either HTTP/1.1 or HTTP/2.
    # See the docs on Transport for details.
    var proto: String  # "HTTP/1.0"
    var proto_major: Int  # 1
    var proto_minor: Int  # 0

    # Header contains the request header fields either received
    # by the server or to be sent by the client.
    #
    # If a server received a request with header lines,
    #
    # 	Host: example.com
    # 	accept-encoding: gzip, deflate
    # 	Accept-Language: en-us
    # 	fOO: Bar
    # 	foo: two
    #
    # then
    #
    # 	Header = map[String][]String{
    # 		"Accept-Encoding": {"gzip, deflate"},
    # 		"Accept-Language": {"en-us"},
    # 		"Foo": {"Bar", "two"},
    # 	}
    #
    # For incoming requests, the Host header is promoted to the
    # Request.Host field and removed from the Header map.
    #
    # HTTP defines that header names are case-insensitive. The
    # request parser implements this by using CanonicalHeaderKey,
    # making the first character and any characters following a
    # hyphen uppercase and the rest lowercase.
    #
    # For client requests, certain headers such as Content-Length
    # and Connection are automatically written when needed and
    # values in Header may be ignored. See the documentation
    # for the Request.Write method.
    var header: Header

    # Body is the request's body.
    #
    # For client requests, a nil body means the request has no
    # body, such as a GET request. The HTTP Client's Transport
    # is responsible for calling the Close method.
    #
    # For server requests, the Request Body is always non-nil
    # but will return EOF immediately when no body is present.
    # The Server will close the request body. The ServeHTTP
    # Handler does not need to.
    #
    # Body must allow Read to be called concurrently with Close.
    # In particular, calling Close should unblock a Read waiting
    # for input.
    var body: DefaultReadCloser

    # # GetBody defines an optional func to return a new copy of
    # # Body. It is used for client requests when a redirect requires
    # # reading the body more than once. Use of GetBody still
    # # requires setting Body.
    # #
    # # For server requests, it is unused.
    # var GetBody: fn() raises -> io.ReadCloser

    # ContentLength records the length of the associated content.
    # The value -1 indicates that the length is unknown.
    # Values >= 0 indicate that the given number of bytes may
    # be read from Body.
    #
    # For client requests, a value of 0 with a non-nil Body is
    # also treated as unknown.
    var content_length: Int64

    # # TransferEncoding lists the transfer encodings from outermost to
    # # innermost. An empty list denotes the "identity" encoding.
    # # TransferEncoding can usually be ignored; chunked encoding is
    # # automatically added and removed as necessary when sending and
    # # receiving requests.
    # var TransferEncoding []String

    # Close indicates whether to close the connection after
    # replying to this request (for servers) or after sending this
    # request and reading its response (for clients).
    #
    # For server requests, the HTTP server handles this automatically
    # and this field is not needed by Handlers.
    #
    # For client requests, setting this field prevents re-use of
    # TCP connections between requests to the same hosts, as if
    # Transport.DisableKeepAlives were set.
    var close: Bool

    # For server requests, Host specifies the host on which the
    # URL is sought. For HTTP/1 (per RFC 7230, section 5.4), this
    # is either the value of the "Host" header or the host name
    # given in the URL itself. For HTTP/2, it is the value of the
    # ":authority" pseudo-header field.
    # It may be of the form "host:port". For International domain
    # names, Host may be in Punycode or Unicode form. Use
    # golang.org/x/net/idna to convert it to either format if
    # needed.
    # To prevent DNS rebinding attacks, server Handlers should
    # validate that the Host header has a value for which the
    # Handler considers itself authoritative. The included
    # ServeMux supports patterns registered to particular host
    # names and thus protects its registered Handlers.
    #
    # For client requests, Host optionally overrides the Host
    # header to send. If empty, the Request.Write method uses
    # the value of URL.Host. Host may contain an International
    # domain name.
    var host: String

    # # Form contains the parsed form data, including both the URL
    # # field's query parameters and the PATCH, POST, or PUT form data.
    # # This field is only available after ParseForm is called.
    # # The HTTP client ignores Form and uses Body instead.
    # var Form: url.Values

    # # PostForm contains the parsed form data from PATCH, POST
    # # or PUT body parameters.
    # #
    # # This field is only available after ParseForm is called.
    # # The HTTP client ignores PostForm and uses Body instead.
    # var PostForm: url.Values

    # # MultipartForm is the parsed multipart form, including file uploads.
    # # This field is only available after ParseMultipartForm is called.
    # # The HTTP client ignores MultipartForm and uses Body instead.
    # var MultipartForm: *multipart.Form

    # # Trailer specifies additional headers that are sent after the request
    # # body.
    # #
    # # For server requests, the Trailer map initially contains only the
    # # trailer keys, with nil values. (The client declares which trailers it
    # # will later send.)  While the handler is reading from Body, it must
    # # not reference Trailer. After reading from Body returns EOF, Trailer
    # # can be read again and will contain non-nil values, if they were sent
    # # by the client.
    # #
    # # For client requests, Trailer must be initialized to a map containing
    # # the trailer keys to later send. The values may be nil or their final
    # # values. The ContentLength must be 0 or -1, to send a chunked request.
    # # After the HTTP request is sent the map values can be updated while
    # # the request body is read. Once the body returns EOF, the caller must
    # # not mutate Trailer.
    # #
    # # Few HTTP clients, servers, or proxies support HTTP trailers.
    # Trailer Header

    # RemoteAddr allows HTTP servers and other software to record
    # the network address that sent the request, usually for
    # logging. This field is not filled in by ReadRequest and
    # has no defined format. The HTTP server in this package
    # sets RemoteAddr to an "IP:port" address before invoking a
    # handler.
    # This field is ignored by the HTTP client.
    var remote_addr: String

    # RequestURI is the unmodified request-target of the
    # Request-Line (RFC 7230, Section 3.1.1) as sent by the client
    # to a server. Usually the URL field should be used instead.
    # It is an error to set this field in an HTTP client request.
    var request_uri: String

    # # TLS allows HTTP servers and other software to record
    # # information about the TLS connection on which the request
    # # was received. This field is not filled in by ReadRequest.
    # # The HTTP server in this package sets the field for
    # # TLS-enabled connections before invoking a handler;
    # # otherwise it leaves the field nil.
    # # This field is ignored by the HTTP client.
    # var TLS: tls.ConnectionState

    # # Cancel is an optional channel whose closure indicates that the client
    # # request should be regarded as canceled. Not all implementations of
    # # RoundTripper may support Cancel.
    # #
    # # For server requests, this field is not applicable.
    # #
    # # Deprecated: Set the Request's context with NewRequestWithContext
    # # instead. If a Request's Cancel field and context are both
    # # set, it is undefined whether Cancel is respected.
    # Cancel <-chan struct{}

    # Response is the redirect response which caused this request
    # to be created. This field is only populated during client
    # redirects.
    var response: Response

    # # ctx is either the client or server context. It should only
    # # be modified via copying the whole Request using Clone or WithContext.
    # # It is unexported to prevent people from using Context wrong
    # # and mutating the contexts held by callers of the same request.
    # ctx context.Context

    # # The following fields are for requests matched by ServeMux.
    # pat         *pattern          # the pattern that matched
    # matches     []String          # values for the matching wildcards in pat
    # otherValues map[String]String # for calls to SetPathValue that don't match a wildcard
