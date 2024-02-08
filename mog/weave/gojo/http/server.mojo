from ..stdlib_extensions.builtins._bytes import bytes, Byte
from ..http.header import Header

# from ..http.request import Request


trait ResponseWriter(Movable, Copyable):
    # Header returns the header map that will be sent by
    # [ResponseWriter.WriteHeader]. The [Header] map also is the mechanism with which
    # [Handler] implementations can set HTTP trailers.
    #
    # Changing the header map after a call to [ResponseWriter.WriteHeader] (or
    # [ResponseWriter.Write]) has no effect unless the HTTP status code was of the
    # 1xx class or the modified headers are trailers.
    #
    # There are two ways to set Trailers. The preferred way is to
    # predeclare in the headers which trailers you will later
    # send by setting the "Trailer" header to the names of the
    # trailer keys which will come later. In this case, those
    # keys of the Header map are treated as if they were
    # trailers. See the example. The second way, for trailer
    # keys not known to the [Handler] until after the first [ResponseWriter.Write],
    # is to prefix the [Header] map keys with the [TrailerPrefix]
    # constant value.
    #
    # To suppress automatic response headers (such as "Date"), set
    # their value to nil.
    fn header(self) -> Header:
        ...

    # Write writes the data to the connection as part of an HTTP reply.
    #
    # If [ResponseWriter.WriteHeader] has not yet been called, Write calls
    # WriteHeader(http.StatusOK) before writing the data. If the Header
    # does not contain a Content-Type line, Write adds a Content-Type set
    # to the result of passing the initial 512 bytes of written data to
    # [DetectContentType]. Additionally, if the total size of all written
    # data is under a few KB and there are no Flush calls, the
    # Content-Length header is added automatically.
    #
    # Depending on the HTTP protocol version and the client, calling
    # Write or WriteHeader may prevent future reads on the
    # Request.Body. For HTTP/1.x requests, handlers should read any
    # needed request body data before writing the response. Once the
    # headers have been flushed (due to either an explicit Flusher.Flush
    # call or writing enough data to trigger a flush), the request body
    # may be unavailable. For HTTP/2 requests, the Go HTTP server permits
    # handlers to continue to read the request body while concurrently
    # writing the response. However, such behavior may not be supported
    # by all HTTP/2 clients. Handlers should read before writing if
    # possible to maximize compatibility.
    fn write(self, data: bytes) -> Int:
        ...

    # WriteHeader sends an HTTP response header with the provided
    # status code.
    #
    # If WriteHeader is not called explicitly, the first call to Write
    # will trigger an implicit WriteHeader(http.StatusOK).
    # Thus explicit calls to WriteHeader are mainly used to
    # send error codes or 1xx informational responses.
    #
    # The provided code must be a valid HTTP 1xx-5xx status code.
    # Any number of 1xx headers may be written, followed by at most
    # one 2xx-5xx header. 1xx headers are sent immediately, but 2xx-5xx
    # headers may be buffered. Use the Flusher interface to send
    # buffered data. The header map is cleared when 2xx-5xx headers are
    # sent, but not with 1xx headers.
    #
    # The server will automatically send a 100 (Continue) header
    # on the first read from the request body if the request has
    # an "Expect: 100-continue" header.
    fn write_header(self, status_code: Int):
        ...


trait Handler(Movable, Copyable):
    fn serve_http(self, writer: ResponseWriter, request: request.Request):
        ...


@value
struct DefaultHandler(Handler):
    fn serve_http(self, writer: ResponseWriter, request: request.Request):
        pass


# A Server defines parameters for running an HTTP server.
# The zero value for Server is a valid configuration.
@value
struct Server(Movable, Copyable):
    # Addr optionally specifies the TCP address for the server to listen on,
    # in the form "host:port". If empty, ":http" (port 80) is used.
    # The service names are defined in RFC 6335 and assigned by IANA.
    # See net.Dial for details of the address format.
    var Addr: String
    var Handler: DefaultHandler  # handler to invoke, http.DefaultServeMux if nil

    # # DisableGeneralOptionsHandler, if true, passes "OPTIONS *" requests to the Handler,
    # # otherwise responds with 200 OK and Content-Length: 0.
    # DisableGeneralOptionsHandler bool

    # # TLSConfig optionally provides a TLS configuration for use
    # # by ServeTLS and ListenAndServeTLS. Note that this value is
    # # cloned by ServeTLS and ListenAndServeTLS, so it's not
    # # possible to modify the configuration with methods like
    # # tls.Config.SetSessionTicketKeys. To use
    # # SetSessionTicketKeys, use Server.Serve with a TLS Listener
    # # instead.
    # TLSConfig *tls.Config

    # # ReadTimeout is the maximum duration for reading the entire
    # # request, including the body. A zero or negative value means
    # # there will be no timeout.
    # #
    # # Because ReadTimeout does not let Handlers make per-request
    # # decisions on each request body's acceptable deadline or
    # # upload rate, most users will prefer to use
    # # ReadHeaderTimeout. It is valid to use them both.
    # ReadTimeout time.Duration

    # # ReadHeaderTimeout is the amount of time allowed to read
    # # request headers. The connection's read deadline is reset
    # # after reading the headers and the Handler can decide what
    # # is considered too slow for the body. If ReadHeaderTimeout
    # # is zero, the value of ReadTimeout is used. If both are
    # # zero, there is no timeout.
    # ReadHeaderTimeout time.Duration

    # # WriteTimeout is the maximum duration before timing out
    # # writes of the response. It is reset whenever a new
    # # request's header is read. Like ReadTimeout, it does not
    # # let Handlers make decisions on a per-request basis.
    # # A zero or negative value means there will be no timeout.
    # WriteTimeout time.Duration

    # # IdleTimeout is the maximum amount of time to wait for the
    # # next request when keep-alives are enabled. If IdleTimeout
    # # is zero, the value of ReadTimeout is used. If both are
    # # zero, there is no timeout.
    # IdleTimeout time.Duration

    # # MaxHeaderBytes controls the maximum number of bytes the
    # # server will read parsing the request header's keys and
    # # values, including the request line. It does not limit the
    # # size of the request body.
    # # If zero, DefaultMaxHeaderBytes is used.
    # MaxHeaderBytes int

    # # TLSNextProto optionally specifies a function to take over
    # # ownership of the provided TLS connection when an ALPN
    # # protocol upgrade has occurred. The map key is the protocol
    # # name negotiated. The Handler argument should be used to
    # # handle HTTP requests and will initialize the Request's TLS
    # # and RemoteAddr if not already set. The connection is
    # # automatically closed when the function returns.
    # # If TLSNextProto is not nil, HTTP/2 support is not enabled
    # # automatically.
    # TLSNextProto map[string]func(*Server, *tls.Conn, Handler)

    # # ConnState specifies an optional callback function that is
    # # called when a client connection changes state. See the
    # # ConnState type and associated constants for details.
    # ConnState func(net.Conn, ConnState)

    # # ErrorLog specifies an optional logger for errors accepting
    # # connections, unexpected behavior from handlers, and
    # # underlying FileSystem errors.
    # # If nil, logging is done via the log package's standard logger.
    # ErrorLog *log.Logger

    # # BaseContext optionally specifies a function that returns
    # # the base context for incoming requests on this server.
    # # The provided Listener is the specific Listener that's
    # # about to start accepting requests.
    # # If BaseContext is nil, the default is context.Background().
    # # If non-nil, it must return a non-nil context.
    # BaseContext func(net.Listener) context.Context

    # # ConnContext optionally specifies a function that modifies
    # # the context used for a new connection c. The provided ctx
    # # is derived from the base context and has a ServerContextKey
    # # value.
    # ConnContext func(ctx context.Context, c net.Conn) context.Context

    # inShutdown atomic.Bool # true when server is in shutdown

    # disableKeepAlives atomic.Bool
    # nextProtoOnce     sync.Once # guards setupHTTP2_* init
    # nextProtoErr      error     # result of http2.ConfigureServer if used

    # mu         sync.Mutex
    # listeners  map[*net.Listener]struct{}
    # activeConn map[*conn]struct{}
    # onShutdown []func()

    # listenerGroup sync.WaitGroup
