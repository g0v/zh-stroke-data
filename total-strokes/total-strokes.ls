String::codePointAt ?= (pos=0) ->
  str = String @
  code = str.charCodeAt(pos)
  if 0xD800 <= code <= 0xDBFF
    next = str.charCodeAt(pos + 1)
    if 0xDC00 <= next <= 0xDFFF
      return ((code - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000
  return code;

minify = (o) ->
  if process.argv.2 is \min
    JSON.stringify o
  else
    JSON.stringify o,,2

require! fs
require! readline


console.log "Reading kTotalStrokes from Unihan DB."

BlackHole = fs.createWriteStream "/dev/null"
DictionaryLikeData = fs.createReadStream "./Unihan/Unihan_DictionaryLikeData.txt", encoding: \utf8
TotalStrokes = {}

the-comment = /^\s*#/
the-total-strokes = /\s*kTotalStrokes\s*/

rl = readline.createInterface DictionaryLikeData, BlackHole
rl.on \line, (line) ->
  if not line.match the-comment and line.match the-total-strokes
    data = line.split the-total-strokes
    TotalStrokes[parseInt data[0].substr(2), 16] = parseInt data[1], 10
rl.on \close, ->
  console.log "Creating total-unihan.json...."
  fs.write-file-sync "./total-unihan.json", minify TotalStrokes


  console.log "Reading total strokes from orginal chars."

  OrigChars = require \../orig-chars.json

  for char in OrigChars
    cp = char.codePointAt!
    out = "#{ cp.toString 16 }.json"
    if fs.exists-sync "../json/#out"
      len = require "../json/#out" .length
      if len isnt TotalStrokes[cp]
        console.log "#char.totalStrokes is #len, not #{TotalStrokes[cp]}."
        TotalStrokes[cp] = len

  console.log "Creating total-origin.json...."
  fs.write-file-sync "./total-origin.json", minify TotalStrokes


  console.log "Guessing total strokes of comps."

  CharComp = require \../char_comp.json

  computed = []
  guessing = {}
  for own char, comps of CharComp
    total = TotalStrokes[char.codePointAt!]
    if total?
      unknown =
        comps: []
        len: total
      for {c} in comps
        part = TotalStrokes[c.codePointAt!]
        if not part? then unknown.comps.push c else unknown.len -= part
      computed.push unknown if unknown.len
      if unknown.comps.length is 1 and unknown.len > 0
        c = unknown.comps.0
        guessing[c] = [] if not guessing[c]
        guessing[c].push unknown.len

  console.log "Creating debug-computed.json...."
  fs.write-file-sync \./debug-computed.json, computed


  console.log "Finding the most likely total strokes...."

  strokes = {}
  for own k, v of guessing
    v.sort!
    result =
      len: 0
      feq: 0
    feq = 0
    prev = 0
    for current in v
      feq = 0 if prev isnt current
      feq++
      if feq > result.feq
        result.len = current
        result.feq = feq
      prev = current
    strokes[k] = result.len
    TotalStrokes[k.codePointAt!] = result.len

  console.log "Creating debug-maybe.json...."
  fs.write-file-sync \./debug-maybe.json, guessing
  console.log "Creating debug-guessing.json...."
  fs.write-file-sync "./debug-guessing.json", strokes
  console.log "Creating total-strokes.json...."
  fs.write-file-sync "./total-strokes.json", minify TotalStrokes
