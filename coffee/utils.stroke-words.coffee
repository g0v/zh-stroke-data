root = this

sax = root.sax or require "sax"

# expose StrokeData
StrokeData = undefined

do ->
  buffer = {}
  source = "xml" # "xml" or "json"
  dirs =
    "xml": "./utf8/"
    "json": "./json/"
  StrokeData =
    source: (val) ->
      source = val if val is "json" or val is "xml"
    get: (str, success, fail) ->
      forEach.call str, (c) ->
        if not buffer[c]
          utf8code = escape(c).replace(/%u/, "").toLowerCase()
          fetchStrokeJSONFromXml(
            dirs[source] + utf8code + "." + source,
            # success
            (json) ->
              buffer[c] = json
              success? json
            # fail
            (err) ->
              fail? err
          )
        else
          success? buffer[c]

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

if root.window #web
  window.WordStroker or= {}
  window.WordStroker.utils =
    fetchStrokeXml: fetchStrokeXml
    jsonFromXml: jsonFromXml
    fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
else # node
  WordStroker =
    utils:
      StrokeData: StrokeData
      fetchStrokeXml: fetchStrokeXml
      fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
  module.exports = WordStroker
