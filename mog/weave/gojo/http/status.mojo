alias StatusContinue = 100  # RFC 9110, 15.2.1
alias StatusSwitchingProtocols = 101  # RFC 9110, 15.2.2
alias StatusProcessing = 102  # RFC 2518, 10.1
alias StatusEarlyHints = 103  # RFC 8297

alias StatusOK = 200  # RFC 9110, 15.3.1
alias StatusCreated = 201  # RFC 9110, 15.3.2
alias StatusAccepted = 202  # RFC 9110, 15.3.3
alias StatusNonAuthoritativeInfo = 203  # RFC 9110, 15.3.4
alias StatusNoContent = 204  # RFC 9110, 15.3.5
alias StatusResetContent = 205  # RFC 9110, 15.3.6
alias StatusPartialContent = 206  # RFC 9110, 15.3.7
alias StatusMultiStatus = 207  # RFC 4918, 11.1
alias StatusAlreadyReported = 208  # RFC 5842, 7.1
alias StatusIMUsed = 226  # RFC 3229, 10.4.1

alias StatusMultipleChoices = 300  # RFC 9110, 15.4.1
alias StatusMovedPermanently = 301  # RFC 9110, 15.4.2
alias StatusFound = 302  # RFC 9110, 15.4.3
alias StatusSeeOther = 303  # RFC 9110, 15.4.4
alias StatusNotModified = 304  # RFC 9110, 15.4.5
alias StatusUseProxy = 305  # RFC 9110, 15.4.6
alias StatusUnused = 306  # RFC 9110, 15.4.7 (Unused)
alias StatusTemporaryRedirect = 307  # RFC 9110, 15.4.8
alias StatusPermanentRedirect = 308  # RFC 9110, 15.4.9

alias StatusBadRequest = 400  # RFC 9110, 15.5.1
alias StatusUnauthorized = 401  # RFC 9110, 15.5.2
alias StatusPaymentRequired = 402  # RFC 9110, 15.5.3
alias StatusForbidden = 403  # RFC 9110, 15.5.4
alias StatusNotFound = 404  # RFC 9110, 15.5.5
alias StatusMethodNotAllowed = 405  # RFC 9110, 15.5.6
alias StatusNotAcceptable = 406  # RFC 9110, 15.5.7
alias StatusProxyAuthRequired = 407  # RFC 9110, 15.5.8
alias StatusRequestTimeout = 408  # RFC 9110, 15.5.9
alias StatusConflict = 409  # RFC 9110, 15.5.10
alias StatusGone = 410  # RFC 9110, 15.5.11
alias StatusLengthRequired = 411  # RFC 9110, 15.5.12
alias StatusPreconditionFailed = 412  # RFC 9110, 15.5.13
alias StatusRequestEntityTooLarge = 413  # RFC 9110, 15.5.14
alias StatusRequestURITooLong = 414  # RFC 9110, 15.5.15
alias StatusUnsupportedMediaType = 415  # RFC 9110, 15.5.16
alias StatusRequestedRangeNotSatisfiable = 416  # RFC 9110, 15.5.17
alias StatusExpectationFailed = 417  # RFC 9110, 15.5.18
alias StatusTeapot = 418  # RFC 9110, 15.5.19 (Unused)
alias StatusMisdirectedRequest = 421  # RFC 9110, 15.5.20
alias StatusUnprocessableEntity = 422  # RFC 9110, 15.5.21
alias StatusLocked = 423  # RFC 4918, 11.3
alias StatusFailedDependency = 424  # RFC 4918, 11.4
alias StatusTooEarly = 425  # RFC 8470, 5.2.
alias StatusUpgradeRequired = 426  # RFC 9110, 15.5.22
alias StatusPreconditionRequired = 428  # RFC 6585, 3
alias StatusTooManyRequests = 429  # RFC 6585, 4
alias StatusRequestHeaderFieldsTooLarge = 431  # RFC 6585, 5
alias StatusUnavailableForLegalReasons = 451  # RFC 7725, 3

alias StatusInternalServerError = 500  # RFC 9110, 15.6.1
alias StatusNotImplemented = 501  # RFC 9110, 15.6.2
alias StatusBadGateway = 502  # RFC 9110, 15.6.3
alias StatusServiceUnavailable = 503  # RFC 9110, 15.6.4
alias StatusGatewayTimeout = 504  # RFC 9110, 15.6.5
alias StatusHTTPVersionNotSupported = 505  # RFC 9110, 15.6.6
alias StatusVariantAlsoNegotiates = 506  # RFC 2295, 8.1
alias StatusInsufficientStorage = 507  # RFC 4918, 11.5
alias StatusLoopDetected = 508  # RFC 5842, 7.2
alias StatusNotExtended = 510  # RFC 2774, 7
alias StatusNetworkAuthenticationRequired = 511  # RFC 6585, 6


# status_text returns a text for the HTTP status code. It returns the empty
# string if the code is unknown.
fn status_text(code: Int) -> String:
    if code == StatusContinue:
        return "Continue"
    elif code == StatusSwitchingProtocols:
        return "Switching Protocols"
    elif code == StatusProcessing:
        return "Processing"
    elif code == StatusEarlyHints:
        return "Early Hints"
    elif code == StatusOK:
        return "OK"
    elif code == StatusCreated:
        return "Created"
    elif code == StatusAccepted:
        return "Accepted"
    elif code == StatusNonAuthoritativeInfo:
        return "Non-Authoritative Information"
    elif code == StatusNoContent:
        return "No Content"
    elif code == StatusResetContent:
        return "Reset Content"
    elif code == StatusPartialContent:
        return "Partial Content"
    elif code == StatusMultiStatus:
        return "Multi-Status"
    elif code == StatusAlreadyReported:
        return "Already Reported"
    elif code == StatusIMUsed:
        return "IM Used"
    elif code == StatusMultipleChoices:
        return "Multiple Choices"
    elif code == StatusMovedPermanently:
        return "Moved Permanently"
    elif code == StatusFound:
        return "Found"
    elif code == StatusSeeOther:
        return "See Other"
    elif code == StatusNotModified:
        return "Not Modified"
    elif code == StatusUseProxy:
        return "Use Proxy"
    elif code == StatusTemporaryRedirect:
        return "Temporary Redirect"
    elif code == StatusPermanentRedirect:
        return "Permanent Redirect"
    elif code == StatusBadRequest:
        return "Bad Request"
    elif code == StatusUnauthorized:
        return "Unauthorized"
    elif code == StatusPaymentRequired:
        return "Payment Required"
    elif code == StatusForbidden:
        return "Forbidden"
    elif code == StatusNotFound:
        return "Not Found"
    elif code == StatusMethodNotAllowed:
        return "Method Not Allowed"
    elif code == StatusNotAcceptable:
        return "Not Acceptable"
    elif code == StatusProxyAuthRequired:
        return "Proxy Authentication Required"
    elif code == StatusRequestTimeout:
        return "Request Timeout"
    elif code == StatusConflict:
        return "Conflict"
    elif code == StatusGone:
        return "Gone"
    elif code == StatusLengthRequired:
        return "Length Required"
    elif code == StatusPreconditionFailed:
        return "Precondition Failed"
    elif code == StatusRequestEntityTooLarge:
        return "Request Entity Too Large"
    elif code == StatusRequestURITooLong:
        return "Request URI Too Long"
    elif code == StatusUnsupportedMediaType:
        return "Unsupported Media Type"
    elif code == StatusRequestedRangeNotSatisfiable:
        return "Requested Range Not Satisfiable"
    elif code == StatusExpectationFailed:
        return "Expectation Failed"
    elif code == StatusTeapot:
        return "I'm a teapot"
    elif code == StatusMisdirectedRequest:
        return "Misdirected Request"
    elif code == StatusUnprocessableEntity:
        return "Unprocessable Entity"
    elif code == StatusLocked:
        return "Locked"
    elif code == StatusFailedDependency:
        return "Failed Dependency"
    elif code == StatusTooEarly:
        return "Too Early"
    elif code == StatusUpgradeRequired:
        return "Upgrade Required"
    elif code == StatusPreconditionRequired:
        return "Precondition Required"
    elif code == StatusTooManyRequests:
        return "Too Many Requests"
    elif code == StatusRequestHeaderFieldsTooLarge:
        return "Request Header Fields Too Large"
    elif code == StatusUnavailableForLegalReasons:
        return "Unavailable For Legal Reasons"
    elif code == StatusInternalServerError:
        return "Internal Server Error"
    elif code == StatusNotImplemented:
        return "Not Implemented"
    elif code == StatusBadGateway:
        return "Bad Gateway"
    elif code == StatusServiceUnavailable:
        return "Service Unavailable"
    elif code == StatusGatewayTimeout:
        return "Gateway Timeout"
    elif code == StatusHTTPVersionNotSupported:
        return "HTTP Version Not Supported"
    elif code == StatusVariantAlsoNegotiates:
        return "Variant Also Negotiates"
    elif code == StatusInsufficientStorage:
        return "Insufficient Storage"
    elif code == StatusLoopDetected:
        return "Loop Detected"
    elif code == StatusNotExtended:
        return "Not Extended"
    elif code == StatusNetworkAuthenticationRequired:
        return "Network Authentication Required"
    else:
        return ""
