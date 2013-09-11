fs = require "fs"

push = Array.prototype.push

scale_factor = 2060.0 / 256

scale = (num) ->
  throw "coordinate out of range: #{num}" if num >= 2060
  return ~~((num + scale_factor/2) / scale_factor)

hexFromNumber = (num) ->
  ret = num.toString(16)
  if ret.length < 2 then "0" + ret else ret

process.argv.forEach (packed, index) ->
  return if index is 0 or index is 1
  stroke_count = 0
  offsets = {}
  results = {}
  for i in [0..0x0fff]
    strokes = undefined
    cp = (i << 8) + parseInt(packed, 16)
    path = "./json/#{cp.toString(16)}.json"
    if fs.existsSync path
      stroke_count += 1
      results[i] = []
      strokes = require path
      results[i].push strokes.length
      strokes.forEach (stroke) ->
        throw "outline length out of range: #{stroke.outline.length}" if stroke.outline.length >= 256
        types = []
        xs = []
        ys = []
        results[i].push stroke.outline.length
        stroke.outline.forEach (cmd) ->
          types.push cmd.type.charCodeAt(0)
          switch cmd.type
            when "M"
              xs.push cmd.x
              ys.push cmd.y
            when "L"
              xs.push cmd.x
              ys.push cmd.y
            when "Q"
              xs.push cmd.begin.x
              ys.push cmd.begin.y
              xs.push cmd.end.x
              ys.push cmd.end.y
            when "C"
              xs.push cmd.begin.x
              xs.push cmd.begin.x
              ys.push cmd.mid.y
              ys.push cmd.mid.y
              xs.push cmd.end.x
              ys.push cmd.end.y
            else
              throw "unknow path type: #{cmd.type}"
        xs = xs.map scale
        ys = ys.map scale
        push.apply results[i], types
        push.apply results[i], xs
        push.apply results[i], ys
        throw "track length out of range: #{stroke.track.length}" if stroke.outline.length >= 256
        with_size = []
        xs = []
        ys = []
        ss = []
        results[i].push stroke.track.length
        stroke.track.forEach (node, index) ->
          xs.push node.x
          ys.push node.y
          if node.size isnt undefined
            with_size.push index
            ss.push node.size
        xs = xs.map scale
        ys = ys.map scale
        ss = ss.map scale
        results[i].push with_size.length
        push.apply results[i], with_size
        push.apply results[i], xs
        push.apply results[i], ys
        push.apply results[i], ss
        # save size of each word
        offsets[i] = results[i].length
  i = 0
  prev = 2 + stroke_count * 6
  offsetsBuffer = new Buffer prev
  offsetsBuffer.writeUInt16LE stroke_count, 0
  for own key of offsets
    offset = offsets[key]
    offsets[key] = prev
    offsetsBuffer.writeUInt16LE key, 2 + i * 6
    offsetsBuffer.writeUInt32LE prev, 2 + i * 6 + 2
    prev += offset
    i += 1
  process.stdout.write offsetsBuffer
  for own i of results
    result = results[i]
    buffer = new Buffer result
    throw "buffer is not a pure uint8 buffer" if buffer.length isnt result.length
    process.stdout.write new Buffer result
