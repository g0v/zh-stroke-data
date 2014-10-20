root = this

Q   = root.Q   or require \q
sax = root.sax or require \sax

# http://jsperf.com/alternative-isfunction-implementations/15
# Pure duck-typing implementation taken from Underscore.js.
is-function = ->
  it and it.constructor and it.call and it.apply

is-deferred = ->
  it and it.resolve and it.reject and it.promise

get = (path, d) ->
  d = Q.defer! if not is-deferred d
  if root.window # web
    $.ajax do
      type:      \GET
      url:       path
      data-type: \text
      progress:  !-> d.notify  it
    .done        !-> d.resolve it
    .fail        !-> d.reject  it
  else # node
    require! fs
    err, data <- fs.read-file path, encoding: \utf8
    if err then d.reject err else d.resolve data
  d.promise

# web only, for now
get-binary = (path, d) ->
  d = Q.defer! if not is-deferred d
  if root.window
    xhr = new XMLHttpRequest
    xhr.open \GET, path, true
    xhr.responseType = \arraybuffer
    xhr.onprogress = !-> d.notify it
    xhr.onreadystatechange = (e) !->
      if @readyState is 4
        if @status is 200
          d.resolve this.response
        else
          d.reject @status
    xhr.send!
  else
    d.reject new Error 'not implemented'
  d.promise

cache-binary = do ->
  cache = {}
  get: (dir, packed, d) ->
    if not cache[packed]
      d = Q.defer! if not is-deferred d
      get-binary "#dir#packed.bin", d
      cache[packed] = d.promise
    cache[packed]

callbackify = (loader) ->
  (path, success, fail, progress) ->
    d = if is-deferred success then success else Q.defer!
    p = d.promise
    p.then     success  if is-function success
    p.fail     fail     if is-function fail
    p.progress progress if is-function progress
    loader path, d
    d.promise

XMLLoader = (path, d) !->
  p = get path
  p.fail     -> d.reject it
   .progress -> d.notify it
  doc <- p.then
  ret      = []
  outlines = []
  tracks   = []
  var outline, track
  # thank you for this package! @isaacs
  strict = true
  parser = sax.parser strict
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
          track.push do
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
            size: if node.attributes.size then parseFloat(node.attributes.size) else undefined
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
    d.resolve ret
  parser.onerror = (err) ->
    d.reject err
  parser.write(doc).close!

JSONLoader = (path, d) !->
  get path .then     -> d.resolve JSON.parse it
           .fail     -> d.reject it
           .progress -> d.notify it

undelta = (xs) ->
  results = [xs[0]]
  for i from 1 til xs.length
    results.push (results[i-1] + xs[i] + 256) % 256
  results

undeltaR = (result, current) ->
  prev = if result.length isnt 0 then result[result.length-1] else 0
  result.concat [(prev + current + 256) % 256]

scale = (v) ->
  v * 2060.0px / 256 # hard coded DDDD:

BinaryLoader = (path, d) !->
  start = 1 + path.lastIndexOf \/
  dir = path.substr 0, start
  packed = path.substr path.length-6, 2
  file_id = parseInt path.substring(start, path.length-6), 16
  p = cache-binary.get dir, packed
  p.fail     -> d.reject it
   .progress -> d.notify it
  bin <- p.then
  var offset
  size = M: 1, L: 1, Q: 2, C: 3
  data_view = new DataView bin
  stroke_count = data_view.getUint16 0, true
  i = 0
  while i < stroke_count
    id = data_view.getUint16 2+i*6, true
    if id is file_id
      offset = data_view.getUint32 2+i*6+2, true
      break
  if i is stroke_count
    d.reject new Error "stroke not found"
    return
  p = 0
  ret = []
  strokes_len = data_view.getUint8 offset + p++
  for from 0 til strokes_len
    outline = []
    cmd_len = data_view.getUint8 offset + p++
    cood_len = 0
    for from 0 til cmd_len
      cmd = type: String.fromCharCode data_view.getUint8 offset + p++
      cood_len += size[cmd.type]
      outline.push cmd
    xs = []
    ys = []
    for from 0 til cood_len
      xs.push data_view.getUint8 offset + p++
    for from 0 til cood_len
      ys.push data_view.getUint8 offset + p++
    xs = undelta(xs).map scale
    ys = undelta(ys).map scale
    j = 0
    for cmd in outline
      switch cmd.type
        when \M
          cmd.x = xs[j]
          cmd.y = ys[j++]
        when \L
          cmd.x = xs[j]
          cmd.y = ys[j++]
        when \Q
          cmd.begin = x: xs[j], y: ys[j++]
          cmd.end   = x: xs[j], y: ys[j++]
        when \C
          cmd.begin = x: xs[j], y: ys[j++]
          cmd.mid   = x: xs[j], y: ys[j++]
          cmd.end   = x: xs[j], y: ys[j++]
    track = []
    track_len = data_view.getUint8 offset + p++
    size_indices = []
    size_len = data_view.getUint8 offset + p++
    for from 0 til size_len
      size_indices.push data_view.getUint8 offset + p++
    xs = []
    ys = []
    ss = []
    for from 0 til track_len
      xs.push data_view.getUint8 offset + p++
    for from 0 til track_len
      ys.push data_view.getUint8 offset + p++
    for from 0 til size_len
      ss.push data_view.getUint8 offset + p++
    xs = undelta(xs).map scale
    ys = undelta(ys).map scale
    ss = ss.map scale
    for j from 0 til track_len
      track.push x: xs[j], y: ys[j]
    j = 0
    for index in size_indices
      track[index].size = ss[j++]
    ret.push outline: outline, track: track
  d.resolve ret

ScanlineLoader = (path, d) !->
  get path .progress -> d.notify it
           .fail     -> d.reject it
           .then     ->
              strokes = []
              data = null
              lines = it.split /\r+\n+/
              for line in lines
                if r = /^([0|1]),(\d+)$/exec line
                  strokes.push data if data
                  break if r.1 is '0' and r.2 is '0'
                  data =
                    direction: +r.1
                    lines: []
                else if r = /^(\d+),(\d+),(\d+)$/exec line
                  data.lines.push idx: +r.1, start: +r.2, end: +r.3
              d.resolve strokes

loaders =
  XML:      callbackify XMLLoader
  JSON:     callbackify JSONLoader
  Binary:   callbackify BinaryLoader
  Scanline: callbackify ScanlineLoader

if root.window
  root.zh-stroke-data or= {}
  root.zh-stroke-data.loaders = loaders
else
  module.exports = loaders
