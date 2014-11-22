require! { sax, bytebuffer: ByteBuffer }

fromXML = (doc, done) !->
  ret      = []
  outlines = []
  tracks   = []
  var outline, track
  # thank you, sax
  parser = sax.parser (strict = true)
  parser.onopentag = (node) ->
    # parse path of the outline
    if outline
      switch node.name
        when \MoveTo
          outline.push do
            type: \M
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
        when \LineTo
          outline.push do
            type: \L
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
        when \CubicTo
          outline.push do
            type: \C
            begin:
              x: parseFloat node.attributes.x1
              y: parseFloat node.attributes.y1
            mid:
              x: parseFloat node.attributes.x2
              y: parseFloat node.attributes.y2
            end:
              x: parseFloat node.attributes.x3
              y: parseFloat node.attributes.y3
        when \QuadTo
          outline.push do
            type: \Q
            begin:
              x: parseFloat node.attributes.x1
              y: parseFloat node.attributes.y1
            end:
              x: parseFloat node.attributes.x2
              y: parseFloat node.attributes.y2
    # parse path of the track
    else if track
      switch node.name
        when \MoveTo
          curr =
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
            size: if node.attributes.size then parseFloat(node.attributes.size) else undefined
          if prev = track[*-1]
            dx = curr.x - prev.x
            dy = curr.y - prev.y
            prev.length = Math.sqrt dx * dx + dy * dy
          track.push curr
    # not in any outline or track
    else
      if node.name is \Outline
        outline := []
      if node.name is \Track
        track := []
  # end of parser.onopentag
  parser.onclosetag = (name) ->
    if name is \Outline
      outlines.push outline
      outline := null
    if name is \Track
      tracks.push track
      track := null
  parser.onend = ->
    for i, outline of outlines
      track = tracks[i]
      ret.push do
        outline: outline
        track: track
    done null, ret
  parser.onerror = done
  parser.write(doc).close!



undelta = (xs) ->
  results = [xs[0]]
  for i from 1 til xs.length
    results.push (results[i-1] + xs[i] + 256) % 256
  results
undeltaR = (result, current) ->
  prev = if result.length isnt 0 then result[result.length-1] else 0
  result.concat [(prev + current + 256) % 256]
scale = (v) -> v * 2060.0px / 256 # hard coded DDDD:
size = M: 1, L: 1, Q: 2, C: 3

fromBinary = (buffer, done) !->
  #start = 1 + path.lastIndexOf \/
  #dir = path.substr 0, start
  #packed = path.substr path.length-6, 2
  #file_id = parseInt path.substring(start, path.length-6), 16
  #p = cache-binary.get dir, packed
  #p.fail     -> d.reject it
  # .progress -> d.notify it
  #bin <- p.then
  ByteBuffer.DEFAULT_ENDIAN = ByteBuffer.LITTLE_ENDIAN
  bb = ByteBuffer.wrap buffer
  num-words = bb.readUint16!
  ids = []
  offsets = [] # will not be used in this version
  for til num-words
    ids.push bb.readUint16!
    offsets.push bb.readUint32!
  data = for til num-words
    num-strokes = bb.readUint8!
    for til num-strokes
      num-cmds = bb.readUint8!
      num-coords = 0
      outline = for til num-cmds
        type = bb.readString 1
        num-coords += size[type]
        { type }
      xs = undelta(for til num-coords => bb.readUint8!)map scale
      ys = undelta(for til num-coords => bb.readUint8!)map scale
      i = 0
      for cmd in outline
        switch cmd.type
          when \M
            cmd.x = xs[i]
            cmd.y = ys[i++]
          when \L
            cmd.x = xs[i]
            cmd.y = ys[i++]
          when \Q
            cmd.begin = x: xs[i], y: ys[i++]
            cmd.end   = x: xs[i], y: ys[i++]
          when \C
            cmd.begin = x: xs[i], y: ys[i++]
            cmd.mid   = x: xs[i], y: ys[i++]
            cmd.end   = x: xs[i], y: ys[i++]
      num-tracks = bb.readUint8!
      num-sizes = bb.readUint8!
      idx-sizes = for til num-sizes => bb.readUint8!
      xs = undelta(for from 0 til num-tracks => bb.readUint8!)map scale
      ys = undelta(for from 0 til num-tracks => bb.readUint8!)map scale
      ss = (for from 0 til num-sizes => bb.readUint8!)map scale
      track = []
      for i til num-tracks
        curr = x: xs[i], y: ys[i]
        if prev = track[*-1]
          dx = curr.x - prev.x
          dy = curr.y - prev.y
          prev.length = Math.sqrt dx * dx + dy * dy
        track.push curr
      i = 0
      for idx in idx-sizes => track[idx]size = ss[i++]
      outline: outline, track: track
  bb.flip!
  result = {}
  for i of ids => result[ids[i]] := data[i]
  done null, result



fromScanline = (txt, done) !->
  strokes = []
  stroke = []
  data = null
  lines = txt.split /\r+\n+/
  for line in lines
    if r = /^([0|1]),(\d+)$/exec line
      if r.1 is '0' and r.2 is '0'
        stroke.push data
        strokes.push stroke
        stroke = []
        data = null
      else
        stroke.push data if data
        data =
          direction: +r.1
          lines: []
    else if r = /^(\d+),(\d+),(\d+)$/exec line
      data.lines.push idx: +r.1, start: +r.2, end: +r.3
  done null, strokes



computeLength = (word) ->
  length = 0
  for stroke in word
    len = 0
    for i, curr of stroke.track
      if prev = stroke.track[i-1]
        if not prev.length
          dx = curr.x - prev.x
          dy = curr.y - prev.y
          prev.length = Math.sqrt dx * dx + dy * dy
        len += prev.length
    length += stroke.length = len
  { word, length }



module.exports = { fromXML, fromBinary, fromScanline, computeLength }
