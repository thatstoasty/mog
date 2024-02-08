from ..stdlib_extensions.builtins._dict import dict, HashableStr


@value
struct URL(CollectionElement):
    var Scheme: String
    # var Opaque      String    # encoded opaque data
    # var User        *Userinfo # username and password information
    var Host: String  # host or host:port (see Hostname and Port methods)
    var Path: String  # path (relative paths may omit leading slash)
    # var RawPath     String    # encoded path hint (see EscapedPath method)
    # var OmitHost    Bool      # do not emit empty host (authority)
    # var ForceQuery  Bool      # append a query ('?') even if RawQuery is empty
    # var RawQuery: String    # encoded query values, without '?'
    # var Fragment    String    # fragment for references, without '#'
    # var RawFragment String    # encoded fragment hint (see EscapedFragment method)


# # Values maps a String key to a list of values.
# # It is typically used for query parameters and form values.
# # Unlike in the http.Header map, the keys in a Values map
# # are case-sensitive.
@value
struct Values(CollectionElement):
    var value: dict[HashableStr, DynamicVector[String]]
