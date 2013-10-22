root = this

sax = root.sax or require "sax"
glMatrix = root.glMatrix or require "./gl-matrix-min"

# jquery ajax progress by @englercj
# https://github.com/englercj/jquery-ajax-progress
fetchStrokeXml = (path, success, fail, progress) ->
  if root.window # web
    jQuery.ajax(
      type: "GET"
      url: path
      dataType: "text"
      progress: progress
    ).
    done(success).
    fail(fail)
  else # node
    fs = require "fs"
    fs.readFile path, { encoding: "utf8" }, (err, data) ->
      if err
        fail err
      else
        success data

fetchStrokeJSON = (path, success, fail, progress) ->
  if root.window # web
    jQuery.ajax(
      type: "GET"
      url: path
      dataType: "json"
      progress: progress
    ).
    done(success).
    fail(fail)
  else # node
    fs = require "fs"
    fs.readFile path, { encoding: "utf8" }, (err, data) ->
      if err
        fail err
      else
        success JSON.parse data

jsonFromXml = (doc, success, fail) ->
  ret = []
  outlines = []
  tracks = []
  outline = undefined
  track = undefined
  # thank you for this package! @isaacs
  strict = true
  parser = sax.parser strict
  parser.onopentag = (node) ->
    # parse path of the outline
    if outline isnt undefined
      switch node.name
        when "MoveTo"
          outline.push
            type: "M"
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
        when "LineTo"
          outline.push
            type: "L"
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
        when "CubicTo"
          outline.push
            type: "C"
            begin:
              x: parseFloat node.attributes.x1
              y: parseFloat node.attributes.y1
            mid:
              x: parseFloat node.attributes.x2
              y: parseFloat node.attributes.y2
            end:
              x: parseFloat node.attributes.x3
              y: parseFloat node.attributes.y3
        when "QuadTo"
          outline.push
            type: "Q"
            begin:
              x: parseFloat node.attributes.x1
              y: parseFloat node.attributes.y1
            end:
              x: parseFloat node.attributes.x2
              y: parseFloat node.attributes.y2
    # parse path of the track
    else if track isnt undefined
      switch node.name
        when "MoveTo"
          track.push
            x: parseFloat node.attributes.x
            y: parseFloat node.attributes.y
            size: if node.attributes.size then parseFloat(node.attributes.size) else undefined
    # not in any outline or track
    else
      if node.name is "Outline"
        outline = []
      if node.name is "Track"
        track = []
  # end of parser.onopentag
  parser.onclosetag = (name) ->
    if name is "Outline"
      outlines.push outline
      outline = undefined
    if name is "Track"
      tracks.push track
      track = undefined
  parser.onend = ->
    for outline, i in outlines
      track = tracks[i]
      ret.push
        outline: outline
        track: track
    success ret
  parser.onerror = (err) ->
    fail err
  parser.write(doc).close()

fetchStrokeJSONFromXml = (path, success, fail) ->
  fetchStrokeXml(path, (doc) ->
    jsonFromXml doc, success, fail
  , fail)

getBinary = (path, success, fail, progress) ->
  xhr = new XMLHttpRequest
  xhr.open "GET", path, true
  xhr.responseType = "arraybuffer"
  xhr.onprogress = progress
  xhr.onreadystatechange = (e) ->
    if @readyState is 4
      if @status is 200
        success? this.response
      else
        fail? @status
  xhr.send()

undelta = (xs) ->
  results = [xs[0]]
  for i in [1...xs.length]
    results.push (results[i-1] + xs[i] + 256) % 256
  results

undeltaR = (result, current) ->
  prev = if result.length isnt 0 then result[result.length - 1] else 0
  result.concat [(prev + current + 256) % 256]

scale = (v) ->
  v * 2060.0 / 256 # hard coded DDDD:

jsonFromBinary = (data, file_id, success, fail) ->
  size =
    "M": 1
    "L": 1
    "Q": 2
    "C": 3
  data_view = new DataView data
  stroke_count = data_view.getUint16 0, true
  for i in [0...stroke_count]
    id = data_view.getUint16 2 + i * 6, true
    if id is file_id
      offset = data_view.getUint32 2 + i * 6 + 2, true
      break
  return fail? new Error "stroke not found" if i is stroke_count
  p = 0
  ret = []
  strokes_len = data_view.getUint8 offset + p++
  for [0...strokes_len]
    outline = []
    cmd_len = data_view.getUint8 offset + p++
    cood_len = 0
    for [0...cmd_len]
      cmd =
        type: String.fromCharCode data_view.getUint8 offset + p++
      cood_len += size[cmd.type]
      outline.push cmd
    xs = []
    ys = []
    for [0...cood_len]
      xs.push data_view.getUint8 offset + p++
    for [0...cood_len]
      ys.push data_view.getUint8 offset + p++
    xs = undelta(xs).map scale
    ys = undelta(ys).map scale
    j = 0
    for cmd in outline
      switch cmd.type
        when "M"
          cmd.x = xs[j]
          cmd.y = ys[j++]
        when "L"
          cmd.x = xs[j]
          cmd.y = ys[j++]
        when "Q"
          cmd.begin =
            x: xs[j]
            y: ys[j++]
          cmd.end =
            x: xs[j]
            y: ys[j++]
        when "C"
          cmd.begin =
            x: xs[j]
            y: ys[j++]
          cmd.mid =
            x: xs[j]
            y: ys[j++]
          cmd.end =
            x: xs[j]
            y: ys[j++]
    track = []
    track_len = data_view.getUint8 offset + p++
    size_indices = []
    size_len = data_view.getUint8 offset + p++
    for [0...size_len]
      size_indices.push data_view.getUint8 offset + p++
    xs = []
    ys = []
    ss = []
    for [0...track_len]
      xs.push data_view.getUint8 offset + p++
    for [0...track_len]
      ys.push data_view.getUint8 offset + p++
    for [0...size_len]
      ss.push data_view.getUint8 offset + p++
    xs = undelta(xs).map scale
    ys = undelta(ys).map scale
    ss = ss.map scale
    for j in [0...track_len]
      track.push
        x: xs[j]
        y: ys[j]
    j = 0
    for index in size_indices
      track[index].size = ss[j++]
    ret.push
      outline: outline
      track: track
  success? ret

CacheBinary = ->
  cache = {}
  get: (path) ->
    packed = path.substr(path.length - 6, 2)
    packed_path = "#{path.substr(0, 6)}#{packed}.bin"
    if cache[packed] is undefined
      p = jQuery.Deferred()
      getBinary(
        packed_path
        (data) -> p.resolve data
        (err) -> p.reject err
        (event) -> p.notify event
      )
      cache[packed] = p
    cache[packed]

binaryCache = CacheBinary()

fetchStrokeJSONFromBinary = (path, success, fail, progress) ->
  if root.window
    file_id = parseInt path.substr(6, path.length - 12), 16
    binaryCache.get(path).
      done((data) -> jsonFromBinary(data, file_id, success, fail)).
      fail(fail).
      progress(progress)
  else
    console.log "not implemented"

# expose StrokeData
StrokeData = undefined

forEach = Array.prototype.forEach

# http://stackoverflow.com/questions/6885879/javascript-and-string-manipulation-w-utf-16-surrogate-pairs
# with @audreyt's code
sortSurrogates = (str) ->
  cps = []                                      # array to hold code points
  while str.length                              # loop till we've done the whole string
    if /[\uD800-\uDBFF]/.test(str.substr(0,1))  # test the first character
                                                # High surrogate found low surrogate follows
      text = str.substr(0, 2)
      code_point = (text.charCodeAt(0) - 0xD800) * 0x400 + text.charCodeAt(1) - 0xDC00 + 0x10000 # au++
      cps.push                                  # push two onto array
        cp: code_point.toString(16)
        text: text
      str = str.substr(2)                       # clip the two off the string
    else                                        # else BMP code point
      cps.push                                  # push one onto array
        cp: str.charCodeAt(0).toString(16)
        text: str.substr(0, 1)
      str = str.substr(1)                       # clip one from string 
  cps

transform = (mat2d, x, y) ->
  vec = glMatrix.vec2.clone [x, y]
  mat = glMatrix.mat2d.clone mat2d
  out = glMatrix.vec2.create()
  glMatrix.vec2.transformMat2d out, vec, mat
  {
    x: out[0]
    y: out[1]
  }

transformWithMatrix = (strokes, mat2d) ->
  ret = []
  for stroke in strokes
    new_stroke =
      outline: []
      track: []
    for cmd in stroke.outline
      switch cmd.type
        when "M"
          out = transform mat2d, cmd.x, cmd.y
          new_stroke.outline.push
            type: cmd.type
            x: out.x
            y: out.y
        when "L"
          out = transform mat2d, cmd.x, cmd.y
          new_stroke.outline.push
            type: cmd.type
            x: out.x
            y: out.y
        when "C"
          new_cmd =
            type: cmd.type
          out = transform mat2d, cmd.begin.x, cmd.begin.y
          new_cmd.begin =
            x: out.x
            y: out.y
          out = transform mat2d, cmd.mid.x, cmd.mid.y
          new_cmd.mid =
            x: out.x
            y: out.y
          out = transform mat2d, cmd.end.x, cmd.end.y
          new_cmd.end =
            x: out.x
            y: out.y
          new_stroke.outline.push new_cmd
        when "Q"
          new_cmd =
            type: cmd.type
          out = transform mat2d, cmd.begin.x, cmd.begin.y
          new_cmd.begin =
            x: out.x
            y: out.y
          out = transform mat2d, cmd.end.x, cmd.end.y
          new_cmd.end =
            x: out.x
            y: out.y
          new_stroke.outline.push new_cmd
    for v in stroke.track
      out = transform mat2d, v.x, v.y
      new_stroke.track.push
        x: out.x
        y: out.y
    ret.push new_stroke
  ret

fetchers =
  "xml": fetchStrokeJSONFromXml
  "json": fetchStrokeJSON
  "bin": fetchStrokeJSONFromBinary

# now cache globally
CacheJSON = ->
  cache = {}
  get: (cp, url, type) ->
    if cache[cp] is undefined
      p = jQuery.Deferred()
      fetchers[type](
        "#{url}#{cp}.#{type}"
        (json) -> p.resolve json
        (err) -> p.reject err
        (event) -> p.notify event
      )
      cache[cp] = p
    cache[cp]

jsonCache = CacheJSON()

StrokeData = (options) ->
  options = $.extend(
    url: "./json/"
    dataType: "json"
  , options)

  get: (cp, success, fail, progress) ->
    jsonCache.get(cp, options.url, options.dataType).
      done(success).
      fail(fail).
      progress(progress)

StrokeData.transform = transformWithMatrix

if root.window #web
  window.WordStroker or= {}
  window.WordStroker.utils =
    sortSurrogates: sortSurrogates
    StrokeData: StrokeData
    fetchStrokeXml: fetchStrokeXml
    fetchStrokeJSON: fetchStrokeJSON
    fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
else # node
  WordStroker =
    utils:
      sortSurrogates: sortSurrogates
      StrokeData: StrokeData
      fetchStrokeXml: fetchStrokeXml
      fetchStrokeJSON: fetchStrokeJSON
      fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
  module.exports = WordStroker
