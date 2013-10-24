require! readline

the-comment = /^\s*#/
the-total-strokes = /\s*kTotalStrokes\s*/

rl = readline.createInterface process.stdin, process.stdout
out = {}


rl.on \close, -> console.log JSON.stringify out
line <- rl.on \line
if not line.match the-comment and line.match the-total-strokes
  data = line.split the-total-strokes
  out[parseInt data[0].substr(2), 16] = parseInt data[1], 10
