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
  filename = \total-unihan.json
  console.log "Creating #filename...."
  fs.write-file-sync "./#filename", minify TotalStrokes


  console.log "Reading total strokes from orginal chars."

  OrigChars = require \../orig-chars.json

  for char in OrigChars
    cp = char.codePointAt!
    out = "#{ cp.toString 16 }.json"
    if fs.exists-sync "../json/#out"
      len = require "../json/#out" .length
      if len isnt TotalStrokes[cp]
        #console.log "#char.totalStrokes is #len, not #{TotalStrokes[cp]}."
        TotalStrokes[cp] = len

  filename = \total-origin.json
  console.log "Creating #filename...."
  fs.write-file-sync "./#filename", minify TotalStrokes


  console.log "Guessing total strokes of comps."

  CharComp = require \../char_comp.json

  computed = []
  for own char, comps of CharComp
    total = TotalStrokes[char.codePointAt!]
    continue if not total?
    unknown =
      comps: []
      len: total
    for {c} in comps
      unknown.comps.push c
    computed.push unknown

  attempt = 0
  do
    strokes-found = 0
    new-computed = []
    guessing = {}
    for unknown in computed
      new-comps = []
      total = unknown.len
      for c in unknown.comps
        part = TotalStrokes[c.codePointAt!]
        if not part? then new-comps.push c else total -= part
      continue if new-comps.length is 0
      unknown.comps = new-comps
      unknown.len = total
      new-computed.push unknown
      if unknown.comps.length is 1 and unknown.len > 0
        c = unknown.comps.0
        guessing[c] = {} if not guessing[c]
        guessing[c][unknown.len] ?= 0
        guessing[c][unknown.len]++
    computed = new-computed

    console.log "Finding the most likely total strokes...."

    strokes = {}
    for own k, feqs of guessing
      max = 0
      result = 0
      for own len, feq of feqs
        if feq > max
          max = feq
          result = parseInt len, 10
      strokes-found++
      strokes[k] = result
      TotalStrokes[k.codePointAt!] = result

    console.log "Found #strokes-found comps"

    if strokes-found isnt 0
      filename = "maybe.#attempt.json"
      console.log "Creating #filename...."
      fs.write-file-sync "./log/#filename", JSON.stringify guessing,,2
      filename = "guessing.#attempt.json"
      console.log "Creating #filename...."
      fs.write-file-sync "./log/#filename", JSON.stringify strokes,,2

    attempt++
  while strokes-found isnt 0

  filename = "left.json"
  console.log "Creating #filename...."
  fs.write-file-sync "./log/#filename", JSON.stringify computed,,2

  filename = \total-strokes.json
  console.log "Creating #filename...."
  fs.write-file-sync "./#filename", minify TotalStrokes
