String::codePointAt ?= (pos=0) ->
  str = String @
  code = str.charCodeAt(pos)
  if 0xD800 <= code <= 0xDBFF
    next = str.charCodeAt(pos + 1)
    if 0xDC00 <= next <= 0xDFFF
      return ((code - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000
  return code;

const CharComp = require \./char_comp.json
const Comp = require \./components.json
const TotalStrokes = require \./total-strokes.json
const ScaleMissing = require \./scale-missing.json

out = {}

for char in ScaleMissing
  for {c} in CharComp[char]
    out[c] = true if not out[c]
for comp of out
  result = "\"#comp\",\"#{TotalStrokes[comp.codePointAt(0)]}\","
  for whole, start of Comp[comp]
    result += "\"#whole\",\"#start\"," if start
  console.log result.substring(0, result.length - 1)
