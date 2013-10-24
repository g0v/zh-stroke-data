String::codePointAt ?= (pos=0) ->
  str = String @
  code = str.charCodeAt(pos)
  if 0xD800 <= code <= 0xDBFF
    next = str.charCodeAt(pos + 1)
    if 0xDC00 <= next <= 0xDFFF
      return ((code - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000
  return code;

require! readline
const Comp = require \./components.json
const TotalStrokes = require \./total-strokes.json

the-missing-comp = /",*"*/

rl = readline.createInterface process.stdin, process.stdout

line <- rl.on \line
if line.match the-missing-comp
  char = line.split the-missing-comp .1
  out = "\"#{char}\",\"#{TotalStrokes[char.codePointAt(0)]}\","
  for whole, start of Comp[char]
    out += "\"#{whole}\",\"#{start}\"," if start
  console.log out.substring(0, out.length - 1)
