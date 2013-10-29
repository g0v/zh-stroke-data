require! fs
require \./polyfill
TiebreakAdHoc = require \./tiebreak-ad-hoc
const CharComp = require \./char_comp.json
const RevisedStrokes = require \./revised-strokes.json
const TotalStrokes = require \./total-strokes/total-strokes.json
const OrigChars = require \./orig-chars.json

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
    comp = comp{comp: c, x, y, w, h}
    comp.whole = char
    comp.len = RevisedStrokes[comp.comp.codePointAt(0)] || TotalStrokes[comp.comp.codePointAt(0)]
    comp = TiebreakAdHoc comp
    comp-strokes = +(comp.len)
    if not comp-strokes
      if not missing[comp.c]
        missing[comp.c] = true
        missing-json.push comp.comp
    else if not isNaN strokes and ~OrigChars.indexOf char
      lookup = out.get comp.comp
      lookup.len ?= comp-strokes
      lookup.src[char] = strokes
    strokes += comp-strokes

console.log JSON.stringify out.comps,,2
fs.write-file-sync \missing-strokes.json, JSON.stringify missing-json,,2

