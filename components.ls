String::codePointAt ?= (pos=0) ->
  str = String @
  code = str.charCodeAt(pos)
  if 0xD800 <= code <= 0xDBFF
    next = str.charCodeAt(pos + 1)
    if 0xDC00 <= next <= 0xDFFF
      return ((code - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000
  return code;

require! fs
const CharComp = require \./char_comp.json
const RevisedStrokes = require \./revised-strokes.json
const TotalStrokes = require \./total-strokes/total-strokes.json
const OrigChars = require \./orig-chars.json
const SpecialStrokes = { 艹: 4 }

missing = {}
missing-json = []
out =
  comps: {}
  get: (char) ->
    if not @comps[char]
      @comps[char] =
        len: null
        src: {}
    @comps[char]

for own char, comps of CharComp
  strokes = 0
  for comp in comps
    comp-strokes = SpecialStrokes[comp.c] || RevisedStrokes[comp.c.codePointAt(0)] || TotalStrokes[comp.c.codePointAt(0)]
    if not comp-strokes
      if not missing[comp.c]
        missing[comp.c] = true
        missing-json.push comp.c
    else if not isNaN strokes and ~OrigChars.indexOf char
      lookup = out.get comp.c
      lookup.len ?= comp-strokes
      lookup.src[char] = strokes
    strokes += comp-strokes

console.log JSON.stringify out.comps
fs.write-file-sync \missing-strokes.json, JSON.stringify missing-json

