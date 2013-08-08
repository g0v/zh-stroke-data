$ ->
  fetchStrokeXml = (path, success, fail) ->
    $.get(path, success, "xml").fail(fail)

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

  jsonFromXml = (doc) ->
    ret = []
    outlines = doc.getElementsByTagName "Outline"
    tracks = doc.getElementsByTagName "Track"
    for outline, i in outlines
      track = tracks[i]
      ret.push
        outline: parseOutline(outline)
        track: parseTrack(track)
    ret

  fetchStrokeJSONFromXml = (path, success, fail) ->
    fetchStrokeXml(path, (doc) ->
      success(jsonFromXml(doc))
    , fail)

  window.WordStroker or= {}
  window.WordStroker.utils =
    fetchStrokeXml: fetchStrokeXml
    jsonFromXml: jsonFromXml
    fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
