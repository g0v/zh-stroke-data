root = this

sax = root.sax or require "sax"

fetchStrokeXml = (path, success, fail) ->
  if root.window # web
    jQuery.get(path, success, "text").fail(fail)
  else # node
    fs = require "fs"
    fs.readFile path, { encoding: "utf8" }, (err, data) ->
      if err
        fail err
      else
        success data

fetchStrokeJSON = (path, success, fail) ->
  if root.window # web
    jQuery.get(path, success, "json").fail(fail)
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

# expose StrokeData
StrokeData = undefined

forEach = Array.prototype.forEach

# http://stackoverflow.com/questions/6885879/javascript-and-string-manipulation-w-utf-16-surrogate-pairs
# with @audreyt's code
sortSurrogates = (str) ->
  cp = []                                       # array to hold code points
  while str.length                              # loop till we've done the whole string
    if /[\uD800-\uDBFF]/.test(str.substr(0,1))  # test the first character
                                                # High surrogate found low surrogate follows
      text = str.substr(0, 2)
      code_point = (text.charCodeAt(0) - 0xD800) * 0x400 + text.charCodeAt(1) - 0xDC00 + 0x10000 # au++
      cp.push(code_point.toString(16))                       # push the two onto array
      str = str.substr(2)                       # clip the two off the string
    else                                        # else BMP code point
      cp.push(str.charCodeAt(0).toString(16))    # push one onto array
      str = str.substr(1)                       # clip one from string 
  cp

do ->
  buffer = {}
  source = "json" # "xml" or "json"
  dirs =
    "xml": "./utf8/"
    "json": "./json/"
  fetchers =
    "xml": fetchStrokeJSONFromXml
    "json": fetchStrokeJSON
  StrokeData =
    source: (val) ->
      source = val if val is "json" or val is "xml"
    get: (cp, success, fail) ->
      if not buffer[cp]
        fetchers[source](
          dirs[source] + cp + "." + source,
          # success
          (json) ->
            buffer[cp] = json
            success? json
          # fail
          (err) ->
            fail? err
        )
      else
        success? buffer[cp]

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
