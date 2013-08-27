push = Array.prototype.push
scale_down = (val) -> return Math.floor val / 9

process.argv.forEach (path, index) ->
  return if index is 0 or index is 1
  result = []
  strokes = require path
  strokes.forEach (stroke) ->
    push.call result, 0
    stroke.outline.forEach (cmd) ->
      switch cmd.type
        when "M"
          push.call result, 4, scale_down(cmd.x), scale_down(cmd.y)
        when "L"
          push.call result, 5, scale_down(cmd.x), scale_down(cmd.y)
        when "Q"
          push.call result, 6,
            scale_down(cmd.begin.x), scale_down(cmd.begin.y),
            scale_down(cmd.end.x), scale_down(cmd.end.y)
        when "C"
          push.call result, 7,
            scale_down(cmd.begin.x), scale_down(cmd.begin.y),
            scale_down(cmd.mid.x), scale_down(cmd.mid.y),
            scale_down(cmd.end.x), scale_down(cmd.end.y)
    push.call result, 1
    stroke.track.forEach (pos) ->
      push.call result, scale_down(pos.x), scale_down(pos.y)
  process.stdout.write new Buffer result
