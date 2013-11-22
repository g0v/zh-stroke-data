String::codePointAt ?= (pos=0) ->
  str = String @
  code = str.charCodeAt(pos)
  if 0xD800 <= code <= 0xDBFF
    next = str.charCodeAt(pos + 1)
    if 0xDC00 <= next <= 0xDFFF
      return ((code - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000
  return code;

String::sortSurrogates ?= ->
  str = String @
# http://stackoverflow.com/questions/6885879/javascript-and-string-manipulation-w-utf-16-surrogate-pairs
# with @audreyt's help
  while str.length                              # loop till we've done the whole string
    if /[\uD800-\uDBFF]/.test str.0             # test the first character
                                                # High surrogate found low surrogate follows
      txt = str.substr 0 2
      str = str.substr 2
    else                                        # else BMP code point
      txt = str.substr 0 1
      str = str.substr 1
    txt
