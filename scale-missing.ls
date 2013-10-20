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
Chars = require \./chars.json

for char in Chars
  out = "#{ char.codePointAt!toString 16}.json"
  continue if fs.exists-sync "json/#out"
  comp = CharComp[char]
  continue unless comp
  strokes = []
  min-x = min-y = Infinity
  max-x = max-y = -Infinity
  for {c, x, y, w, h} in comp
    ref = c
    stroke-offset = null
    if ref is \艹
      ref = \草
      stroke-offset = 0
      stroke-length = 4
    ref-hex = ref.codePointAt!toString 16
    if fs.exists-sync "json/#ref-hex.json"
      ss = require "./json/#ref-hex.json"
      ss = ss[stroke-offset to stroke-offset + stroke-length - 1] if stroke-offset?
      for {outline} in ss => for s in outline
        if s.x
          min-x <?= s.x; min-y <?= s.y
          max-x >?= s.x; max-y >?= s.y
        else if s.end
          min-x <?= s.begin.x; min-y <?= s.begin.y
          max-x >?= s.begin.x; max-y >?= s.begin.y
          min-x <?= s.end.x; min-y <?= s.end.y
          max-x >?= s.end.x; max-y >?= s.end.y
      w-new = w / S
      h-new = h / S
      w-old = (max-x - min-x) / T
      h-old = (max-y - min-y) / T
      w-ratio = w-new / w-old
      h-ratio = h-new / h-old
      x2048 = x / S*T
      y2048 = y / S*T
      /*
      console.log "new:(w,h): (#w-new, #h-new)"
      console.log "old:(w,h): (#w-old, #h-old)"
      console.log "W Ratio: #w-ratio = (#w-new / #w-old)"
      console.log "H Ratio: #h-ratio = (#h-new / #h-old)"
      console.log "Min (X,Y): (#min-x, #min-y)"
      console.log "(x2048, y2048): (#x2048, #y2048)"
      */
      x-ratio = - min-x * w-ratio + x2048
      y-ratio = - min-y * h-ratio + y2048
      part = { val: ref, matrix: [ w-ratio, 0, 0, h-ratio, x-ratio, y-ratio ] }
      part.indices = [stroke-offset to stroke-offset + stroke-length - 1] if stroke-offset?
      strokes.push part
    else
      #console.log "Missing char: #c"
      strokes = null
      break
  continue unless strokes
  rule = { strokes, val: char }
  fs.write-file-sync "missing/#out" JSON.stringify rule
  result = []
  failed = false
  WordStroker = require "./js/utils.stroke-words"
  source, i <- rule.strokes.forEach
  cp = WordStroker.utils.sortSurrogates source.val
  data = fs.read-file-sync "./json/#{ cp.0 }.json"
  if data
    json = JSON.parse(data)
    part = WordStroker.utils.StrokeData.transform(json, source.matrix);
    if source.indices
      result.=concat source.indices.map (part.)
    else
      result.=concat part
    if i is rule.strokes.length - 1 and not failed
      console.log "Writing json/#out"
      fs.write-file-sync("json/#out", JSON.stringify(result, null, "  "));
