require! fs
require \./polyfill
TiebreakAdHoc = require \./tiebreak-ad-hoc
const S = 256
const T = 2048
const OrigChars = require \./orig-chars.json
const Results = require \./tiebreak-results.json
const Chars = require \./chars.json

missing = {}
found = {}

for char in Chars
  continue if char in OrigChars
  out = "#{ char.codePointAt!toString 16}.json"
  parts = Results[char]
  continue unless parts
  parts = parts.map TiebreakAdHoc
  strokes = []
  for {comp: c, whole: ref, idx: stroke-offset, len: stroke-length, x, y, w, h} in parts
    ref-hex = ref.codePointAt!toString 16
    stroke-offset = +stroke-offset
    stroke-length = +stroke-length
    if fs.exists-sync "json/#ref-hex.json"
      min-x = min-y = Infinity
      max-x = max-y = -Infinity
      ss = require "./json/#ref-hex.json"
      stroke-offset = Infinity if stroke-length is 0
      if stroke-offset isnt Infinity
        last = stroke-offset + stroke-length - 1
        last <?= ss.length - 1
        ss = ss[stroke-offset to last]
      min-x = min-y = Infinity
      max-x = max-y = -Infinity
      for part in ss | part => for s in part.outline
        if s.x
          min-x <?= s.x; min-y <?= s.y
          max-x >?= s.x; max-y >?= s.y
        else if s.end
          min-x <?= s.begin.x; min-y <?= s.begin.y
          max-x >?= s.begin.x; max-y >?= s.begin.y
          min-x <?= s.end.x; min-y <?= s.end.y
          max-x >?= s.end.x; max-y >?= s.end.y
      w-new = +w / S
      h-new = +h / S
      w-old = (max-x - min-x) / T
      h-old = (max-y - min-y) / T
      w-ratio = w-new / w-old
      h-ratio = h-new / h-old
      x2048 = +x / S*T
      y2048 = +y / S*T
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
      found[ref] = true
      part = { val: ref, matrix: [ w-ratio, 0, 0, h-ratio, x-ratio, y-ratio ] }
      part.indices = [stroke-offset to last] if stroke-offset isnt Infinity
      strokes.push part if part
    else
      console.log "Missing comp: #c(#ref-hex)"
      missing[char] = true
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
  data = fs.read-file-sync "./json/#{ cp.0.cp }.json"
  if data
    json = JSON.parse(data)
    part = WordStroker.utils.StrokeData.transform(json, source.matrix);
    if source.indices
      result.=concat source.indices.map (part.)
    else
      result.=concat part
    if i is rule.strokes.length - 1 and not failed
      console.log "Writing json/#out"
      fs.write-file-sync("json/#out", JSON.stringify(result,, 2));
#fs.write-file-sync "./scale-missing.json", JSON.stringify Object.keys missing
#fs.write-file-sync "./scale-found.json", JSON.stringify Object.keys found
