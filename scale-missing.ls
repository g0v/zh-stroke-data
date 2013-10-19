String::codePointAt ?= (pos=0) ->
  str = String @
  code = str.charCodeAt(pos)
  if 0xD800 <= code <= 0xDBFF
    next = str.charCodeAt(pos + 1)
    if 0xDC00 <= next <= 0xDFFF
      return ((code - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000
  return code;

require! fs
const S = 256
const T = 2048
const CharComp = require \./char_comp.json
const Chars = require \./chars.json

for char in Chars
  console.log char
  out = "#{ char.codePointAt!toString 16}.json"
  continue if fs.exists-sync "json/#out"
  comp = CharComp[char]
  continue unless comp
  strokes = []
  for {c, x, y, w, h} in comp
    if fs.exists-sync "json/#{ c.codePointAt!toString 16}.json"
      # TODO: Instead of just writing out missing, we should compose right here.
      # This allows us detect the boundaries of the component instead of
      # assuming a maxed-out configuration, which fails spectacularly on e.g. 日.
      strokes.push { val: c, matrix: [w/S, 0, 0, h/S, x/S*T, y/S*T] }
    else
      console.log "Missing char: #c"
      strokes = null
      break
  if strokes
    console.log "Writing #out"
    fs.write-file-sync "missing/#out" JSON.stringify { strokes, val: char }
