from collections.optional import Optional
from ..io import io
from ..stdlib_extensions.builtins._dict import dict, HashableStr


alias Byte = UInt8


fn valid_header_field_byte(char: Byte) raises -> Bool:
	# mask is a 128-bit bitmap with 1s for allowed bytes,
	# so that the byte c can be tested with a shift and an and.
	# If c >= 128, then 1<<c and 1<<(c-64) will both be zero,
	# and this function will return false.
	var mask = 0 |
		(1<<(10)-1)<<atol('0') |
		(1<<(26)-1)<<atol('a') |
		(1<<(26)-1)<<atol('A') |
		1<<atol('!') |
		1<<atol('#') |
		1<<atol('$') |
		1<<atol('%') |
		1<<atol('&') |
		1<<atol('\'') |
		1<<atol('*') |
		1<<atol('+') |
		1<<atol('-') |
		1<<atol('.') |
		1<<atol('^') |
		1<<atol('_') |
		1<<atol('`') |
		1<<atol('|') |
		1<<atol('~')
	return ((UInt64(1) << char.cast[DType.uint64]())&(mask&(1<<64-1)) | (UInt64(1)<<(char.cast[DType.uint64]()-64))&(mask>>64)) != 0


# canonical_mime_header_key returns the canonical format of the
# MIME header key s. The canonicalization converts the first
# letter and any letter following a hyphen to upper case;
# the rest are converted to lowercase. For example, the
# canonical key for "accept-encoding" is "Accept-Encoding".
# MIME header keys are assumed to be ASCII only.
# If s contains a space or invalid header field bytes, it is
# returned without modifications.
fn canonical_mime_header_key(inout header_key: String) raises -> String:
    var upper = True
    var i = 0
    while i < len(header_key):
        let char = header_key[i]
        if not valid_header_field_byte(ord(char)):
            return header_key
        
        if (upper) and (ord('a') <= ord(char)) and (ord(char) <= ord('z')):
            header_key = canonical_mime_header_key(header_key)
            return header_key
        
        if (not upper) and (ord('A') <= ord(char)) and (ord(char) <= ord('Z')):
            header_key = canonical_mime_header_key(header_key)
            return header_key
        
        upper = (char == '-')
        i += 1
    
    return header_key

# A MIMEHeader represents a MIME-style header mapping
# keys to sets of values.
@value
struct MIMEHeader(CollectionElement):
    var value: dict[HashableStr, DynamicVector[String]]

    # Add adds the key, value pair to the header.
    # It appends to any existing values associated with key.
    fn add(inout self, inout key: String, value: String) raises:
        let mime_key = canonical_mime_header_key(key)
        self.value[mime_key].append(value)
    

    # set sets the header entries associated with key to
    # the single element value. It replaces any existing
    # values associated with key.
    fn set(inout self, inout key: String, value: String) raises:
        var keys = DynamicVector[String]()
        keys.append(value)
        self.value[canonical_mime_header_key(key)] = keys
    

    # Get gets the first value associated with the given key.
    # It is case insensitive; [canonical_mime_header_key] is used
    # to canonicalize the provided key.
    # If there are no values associated with the key, Get returns "".
    # To use non-canonical keys, access the map directly.
    fn get(self, inout key: String) raises -> String:
        if len(self.value) == 0:
            return ""
        
        let v = self.value[canonical_mime_header_key(key)]
        if len(v) == 0:
            return ""
        
        return v[0]
    

    # Values returns all values associated with the given key.
    # It is case insensitive; [canonical_mime_header_key] is
    # used to canonicalize the provided key. To use non-canonical
    # keys, access the map directly.
    # The returned slice is not a copy.
    fn values(self, inout key: String) raises -> Optional[DynamicVector[String]]:
        if len(self.value) == 0:
            return None
        
        return self.value[canonical_mime_header_key(key)]
    

    # Del deletes the values associated with key.
    fn Del(inout self, inout key: String) raises:
        _ = self.value.pop(canonical_mime_header_key(key))
    

@value
struct Header(CollectionElement):
    var value: dict[HashableStr, DynamicVector[String]]

    # Add adds the key, value pair to the header.
    # It appends to any existing values associated with key.
    # The key is case insensitive; it is canonicalized by
    # [CanonicalHeaderKey].
    fn add(inout self, inout key: String, value: String) raises:
        var mime_header = MIMEHeader(self.value)
        mime_header.add(key, value)

    # set sets the header entries associated with key to the
    # single element value. It replaces any existing values
    # associated with key. The key is case insensitive; it is
    # canonicalized by [canonical_mime_header_key].
    # To use non-canonical keys, assign to the map directly.
    fn set(inout self, inout key: String, value: String) raises:
        var mime_header = MIMEHeader(self.value)
        mime_header.set(key, value)

    # Get gets the first value associated with the given key. If
    # there are no values associated with the key, Get returns "".
    # It is case insensitive; [canonical_mime_header_key] is
    # used to canonicalize the provided key. Get assumes that all
    # keys are stored in canonical form. To use non-canonical keys,
    # access the map directly.
    fn get(self, inout key: String) raises -> String:
        var mime_header = MIMEHeader(self.value)
        return mime_header.get(key)

    # Values returns all values associated with the given key.
    # It is case insensitive; [canonical_mime_header_key] is
    # used to canonicalize the provided key. To use non-canonical
    # keys, access the map directly.
    # The returned slice is not a copy.
    fn values(self, inout key: String) raises -> Optional[DynamicVector[String]]:
        var mime_header = MIMEHeader(self.value)
        return mime_header.values(key)

    # get is like Get, but key must already be in CanonicalHeaderKey form.
    fn _get(self, key: String) raises -> String:
        let v = self.value[key]
        if len(v) > 0:
            return v[0]
        
        return ""

    # has reports whether h has the provided key defined, even if it's
    # set to 0-length slice.
    fn has(self, key: String) -> Bool:
        var default_value = DynamicVector[String]()
        default_value.append("default")
        let result = self.value.get(key, DynamicVector[String]())

        if len(result) == 1 and result[0] == "default":
            return False
        
        return True
    
    # Del deletes the values associated with key.
    # The key is case insensitive; it is canonicalized by
    # [CanonicalHeaderKey].
    fn Del(self, inout key: String) raises:
        var mime_header = MIMEHeader(self.value)
        mime_header.Del(key)

    # Write writes a header in wire format.
    fn write[W: io.StringWriter](self, w: W):
        return self._write(w)
    

    fn _write[W: io.StringWriter](self, w: W):
        return self.write_subset(w)
    

    # # Clone returns a copy of h or nil if h is nil.
    # fn Clone() -> Header:
    #     if h == nil:
    #         return nil
        

    #     # Find total number of values.
    #     nv := 0
    #     for _, vv := range h:
    #         nv += len(vv)
        
    #     sv := make(DynamicVector[String], nv) # shared backing array for headers' values
    #     h2 := make(Header, len(h))
    #     for k, vv := range h:
    #         if vv == nil:
    #             # Preserve nil values. ReverseProxy distinguishes
    #             # between nil and zero-length header values.
    #             h2[k] = nil
    #             continue
            
    #         n := copy(sv, vv)
    #         h2[k] = sv[:n:n]
    #         sv = sv[n:]
        
    #     return h2
    

    # # sortedKeyValues returns h's keys sorted in the returned kvs
    # # slice. The headerSorter used to sort is also returned, for possible
    # # return to headerSorterCache.
    # fn sortedKeyValues(exclude map[String]bool) (kvs []keyValues, hs *headerSorter):
    #     hs = headerSorterPool.Get().(*headerSorter)
    #     if cap(hs.kvs) < len(h):
    #         hs.kvs = make([]keyValues, 0, len(h))
        
    #     kvs = hs.kvs[:0]
    #     for k, vv := range h:
    #         if !exclude[k]:
    #             kvs = append(kvs, keyValues{k, vv)
            
        
    #     hs.kvs = kvs
    #     sort.Sort(hs)
    #     return kvs, hs
    

    # # WriteSubset writes a header in wire format.
    # # If exclude is not nil, keys where exclude[key] == true are not written.
    # # Keys are not canonicalized before checking the exclude map.
    # fn WriteSubset(w io.Writer, exclude map[String]bool):
    #     return h.writeSubset(w, exclude, nil)
    

    # TODO: Implement the key sorter stuff
    fn write_subset[W: io.StringWriter](self, w: W):
        for item in self.value.items():
            let values = item.value
            for i in range(len(values)):
                let value = values[i]
                _ = w.write_string(String(item.key) + ": " + value + "\r\n")

        # ws, ok := w.(io.StringWriter)
        # if !ok:
        #     ws = stringWriter{w
        
        # kvs, sorter := h.sortedKeyValues(exclude)
        # var formattedVals DynamicVector[String]
        # for _, kv := range kvs:
        #     if !httpguts.ValidHeaderFieldName(kv.key):
        #         # This could be an error. In the common case of
        #         # writing response headers, however, we have no good
        #         # way to provide the error back to the server
        #         # handler, so just drop invalid headers instead.
        #         continue
            
        #     for _, v := range kv.values:
        #         v = headerNewlineToSpace.Replace(v)
        #         v = TrimString(v)
        #         for _, s := range DynamicVector[String]{kv.key, ": ", v, "\r\n":
        #             if _, err := ws.WriteString(s); err != nil:
        #                 headerSorterPool.Put(sorter)
        #                 return err
                    
                
        #         if trace != nil && trace.WroteHeaderField != nil:
        #             formattedVals = append(formattedVals, v)
                
            
        #     if trace != nil && trace.WroteHeaderField != nil:
        #         trace.WroteHeaderField(kv.key, formattedVals)
        #         formattedVals = nil
            
        
        # headerSorterPool.Put(sorter)
    

# # CanonicalHeaderKey returns the canonical format of the
# # header key s. The canonicalization converts the first
# # letter and any letter following a hyphen to upper case;
# # the rest are converted to lowercase. For example, the
# # canonical key for "accept-encoding" is "Accept-Encoding".
# # If s contains a space or invalid header field bytes, it is
# # returned without modifications.
# fn CanonicalHeaderKey(s: String) -> String:
#     return canonical_mime_header_key(s) 

# # hasToken reports whether token appears with v, ASCII
# # case-insensitive, with space or comma boundaries.
# # token must be all lowercase.
# # v may contain mixed cased.
# fn hasToken(v, token String) bool:
#     if len(token) > len(v) || token == "":
#         return false
    
#     if v == token:
#         return true
    
#     for sp := 0; sp <= len(v)-len(token); sp++:
#         # Check that first character is good.
#         # The token is ASCII, so checking only a single byte
#         # is sufficient. We skip this potential starting
#         # position if both the first byte and its potential
#         # ASCII uppercase equivalent (b|0x20) don't match.
#         # False positives ('^' => '~') are caught by EqualFold.
#         if b := v[sp]; b != token[0] && b|0x20 != token[0]:
#             continue
        
#         # Check that start pos is on a valid token boundary.
#         if sp > 0 && !isTokenBoundary(v[sp-1]):
#             continue
        
#         # Check that end pos is on a valid token boundary.
#         if endPos := sp + len(token); endPos != len(v) && !isTokenBoundary(v[endPos]):
#             continue
        
#         if ascii.EqualFold(v[sp:sp+len(token)], token):
#             return true
        
    
#     return false


# fn isTokenBoundary(b byte) bool:
#     return b == ' ') || b == ',') || b == '\t'



# var timeFormats = DynamicVector[String]{
#         TimeFormat,
#         time.RFC850,
#         time.ANSIC,
    

# # ParseTime parses a time header (such as the Date: header),
# # trying each of the three formats allowed by HTTP/1.1:
# # [TimeFormat], [time.RFC850], and [time.ANSIC].
# fn ParseTime(text String) (t time.Time, err error):
#     for _, layout := range timeFormats:
#         t, err = time.Parse(layout, text)
#         if err == nil:
#             return
        
    
#     return


# var headerNewlineToSpace = strings.NewReplacer("\n", " ", "\r", " ")

# # stringWriter implements WriteString on a Writer.
# type stringWriter struct:
#     w io.Writer


# fn (w stringWriter) WriteString(s String) (n int, err error):
#     return w.w.Write([]byte(s))


# type keyValues struct:
#     key    String
#     values DynamicVector[String]


# # A headerSorter implements sort.Interface by sorting a []keyValues
# # by key. It's used as a pointer, so it can fit in a sort.Interface
# # interface value without allocation.
# type headerSorter struct:
#     kvs []keyValues


# fn (s *headerSorter) Len() int          : return len(s.kvs) 
# fn (s *headerSorter) Swap(i, j int)     : s.kvs[i], s.kvs[j] = s.kvs[j], s.kvs[i] 
# fn (s *headerSorter) Less(i, j int) bool: return s.kvs[i].key < s.kvs[j].key 

# var headerSorterPool = sync.Pool{
#     New: fn() any: return new(headerSorter) ,

