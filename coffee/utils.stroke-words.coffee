root = this

fetchStrokeXml = (path, success, fail) ->
  if root.window # web
    jQuery.get(path, success, "xml").fail(fail)
  else # node
    fs = require "fs"
    fs.readFile path, (err, data) ->
      if err
        do fail
      else
        success data.toString()

parseOutline = (outline) ->
  path = []
  for node in outline.childNodes
    continue if node.nodeType != 1
    a = node.attributes
    continue unless a
    switch node.nodeName
      when "MoveTo"
        path.push
          type: "M"
          x: parseFloat a.x.value
          y: parseFloat a.y.value
      when "LineTo"
        path.push
          type: "L"
          x: parseFloat a.x.value
          y: parseFloat a.y.value
      when "CubicTo"
        path.push
          type: "C"
          begin:
            x: parseFloat a.x1.value
            y: parseFloat a.y1.value
          mid:
            x: parseFloat a.x2.value
            y: parseFloat a.y2.value
          end:
            x: parseFloat a.x3.value
            y: parseFloat a.y3.value
      when "QuadTo"
        path.push
          type: "Q"
          begin:
            x: parseFloat a.x1.value
            y: parseFloat a.y1.value
          end:
            x: parseFloat a.x2.value
            y: parseFloat a.y2.value
  path

parseTrack = (track) ->
  path = []
  for node in track.childNodes
    continue if node.nodeType != 1
    a = node.attributes
    continue unless a
    switch node.nodeName
      when "MoveTo"
        path.push
          x: parseFloat a.x.value
          y: parseFloat a.y.value
          size: if a.size then parseFloat(a.size.value) else undefined
  path

jsonFromXml = (doc, cb) ->
  ret = []
  if root.window # doc is an element
    outlines = doc.getElementsByTagName "Outline"
    tracks = doc.getElementsByTagName "Track"
    for outline, i in outlines
      track = tracks[i]
      ret.push
        outline: parseOutline outline
        track: parseTrack track
    cb ret
  else # doc is a string
    outlines = []
    tracks = []
    outline = undefined
    track = undefined
    # thank you for this package! @isaacs
    sax = require "sax"
    strict = true
    parser = sax.parser strict
    parser.onopentag = (node) ->
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
      else if track isnt undefined
        switch node.name
          when "MoveTo"
            track.push
              x: parseFloat node.attributes.x
              y: parseFloat node.attributes.y
              size: if node.attributes.size then parseFloat(node.attributes.size) else undefined
      else
        if node.name is "Outline"
          outline = []
        if node.name is "Track"
          track = []
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
        cb ret
    parser.write(doc).close()

fetchStrokeJSONFromXml = (path, success, fail) ->
  fetchStrokeXml(path, (doc) ->
    jsonFromXml doc, success
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
      fetchStrokeXml: fetchStrokeXml
      fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
  module.exports = WordStroker
