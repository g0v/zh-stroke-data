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
  console.log comp
  for {c, x, y, w, h} in comp
    if fs.exists-sync "json/#{ c.codePointAt!toString 16}.json"
      ss = require "./json/#{ c.codePointAt!toString 16}.json"
      for {outline} in ss => for s in outline
        if s.x
          min-x <?= s.x; min-y <?= s.y
          max-x >?= s.x; max-y >?= s.y
        else if s.end
          min-x <?= s.begin.x; min-y <?= s.begin.y
          max-x >?= s.begin.x; max-y >?= s.begin.y
          min-x <?= s.end.x; min-y <?= s.end.y
          max-x >?= s.end.x; max-y >?= s.end.y
      # TODO: Instead of just writing out missing, we should compose right here.
      # This allows us detect the boundaries of the component instead of
      # assuming a maxed-out configuration, which fails spectacularly on e.g. 日.
#      console.log min-x; console.log min-y
#      console.log max-x; console.log max-y
#      console.log h/S



      w-new = w / S
      h-new = h / S
      w-old = (max-x - min-x) / T
      h-old = (max-y - min-y) / T
      w-ratio = w-new / w-old
      h-ratio = h-new / h-old
      # W Ratio: 1.146417445482866
      # H Ratio: 0.47232472324723246
      x2048 = x / S*T
      y2048 = y / S*T
#      const S = 256
#      const T = 2048
      console.log "new:(w,h): (#w-new, #h-new)"
      console.log "old:(w,h): (#w-old, #h-old)"
      console.log "W Ratio: #w-ratio = (#w-new / #w-old)"
      console.log "H Ratio: #h-ratio = (#h-new / #h-old)"
#      console.log "H Ratio: #h-ratio = (#h-new / #h-old)"
      console.log "Min (X,Y): (#min-x, #min-y)"
#      console.log "Min Y: #min-y"
      console.log "(x2048, y2048): (#x2048, #y2048)"
      x-ratio = - min-x * w-ratio + x2048
      y-ratio = - min-y * h-ratio + y2048

      strokes.push { val: c, matrix: [
        #        w-ratio, 0, 0, h-ratio, -(x*w-ratio) + (min-x) , -(y*h-ratio) + (min-y)
        #        w-ratio, 0, 0, h-ratio, x2048, y2048
        w-ratio, 0, 0, h-ratio, x-ratio, y-ratio
      ] }
    else
      console.log "Missing char: #c"
      strokes = null
      break
  if strokes
    console.log "Writing #out"
    fs.write-file-sync "missing/#out" JSON.stringify { strokes, val: char }
