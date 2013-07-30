$ ->
  filterNodes = (childNodes) ->
    nodes = []
    for n in childNodes
      nodes.push n if n.nodeType == 1
    return nodes

  #drawOutline = (paper, outline ,pathAttrs) ->
  #  path = []
  #  for node in outline.childNodes
  #    continue if node.nodeType != 1
  #    a = node.attributes
  #    continue unless a
  #    switch node.nodeName
  #      when "MoveTo"
  #        path.push [ "M", parseFloat(a.x.value) , parseFloat(a.y.value) ]
  #      when "LineTo"
  #        path.push [ "L", parseFloat(a.x.value) , parseFloat(a.y.value) ]
  #      when "QuadTo"
  #        path.push [ "Q", parseFloat(a.x1.value) , parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value) ]
  #  paper.path(path).attr(pathAttrs).transform("s0.2,0.2,0,0")

  fetchStrokeXml = (code, cb) -> $.get "utf8/" + code.toLowerCase() + ".xml", cb, "xml"

  config =
    dim: 430
    scale: .2
    trackWidth: 50

  drawBackground = (ctx) ->
    ctx.strokeStyle = "#A33"
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.lineTo(0, config.dim)
    ctx.lineTo(config.dim, config.dim)
    ctx.lineTo(config.dim, 0)
    ctx.lineTo(0, 0)
    ctx.moveTo(0, config.dim / 3)
    ctx.lineTo(config.dim, config.dim / 3)
    ctx.moveTo(0, config.dim / 3 * 2)
    ctx.lineTo(config.dim, config.dim / 3 * 2)
    ctx.moveTo(config.dim / 3, 0)
    ctx.lineTo(config.dim / 3, config.dim)
    ctx.moveTo(config.dim / 3 * 2, 0)
    ctx.lineTo(config.dim / 3 * 2, config.dim)
    ctx.stroke()

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
            size: if a.size then parseFloat(a.size.value) else config.trackWidth
    path

  createWord = (val) ->
    word =
      value: val
      utf8code: escape(val).replace(/%u/, "")
      strokes: []
    fetchStrokeXml word.utf8code, (doc) ->
      tracks = doc.getElementsByTagName "Track"
      for outline, index in doc.getElementsByTagName 'Outline'
        word.strokes.push
          outline: parseOutline outline
          track: parseTrack tracks[index]
    word

  drawStroke = (ctx, outline, track, time) ->
    ctx.beginPath()
    for node in outline.childNodes
      continue if node.nodeType != 1
      a = node.attributes
      continue unless a
      switch node.nodeName
        when "MoveTo"
          ctx.moveTo(parseFloat(a.x.value) * .2, parseFloat(a.y.value) * .2)
        when "LineTo"
          ctx.lineTo(parseFloat(a.x.value) * .2, parseFloat(a.y.value) * .2)
        when "QuadTo"
          ctx.quadraticCurveTo(
            parseFloat(a.x1.value) * .2,
            parseFloat(a.y1.value) * .2,
            parseFloat(a.x2.value) * .2,
            parseFloat(a.y2.value) * .2
          )
    ctx.fill()

  strokeWord = (ctx, word) ->
    ctx.clearRect(0, 0, config.dim, config.dim)
    utf8code = escape(word).replace(/%u/ , "")
    fetchStrokeXml utf8code, (doc) ->
      drawBackground(ctx)
      ctx.strokeStyle = "#000"
      ctx.fillStyle = "#000"
      ctx.lineWidth = 5
      ctx.lineCap = "round"
      tracks = doc.getElementsByTagName "Track"
      for outline, index in doc.getElementsByTagName 'Outline'
        do (outline) ->
          drawStroke(ctx, outline, tracks[index])

  strokeWords = (words) -> strokeWord(a) for a in words.split //

  $canvas = $("<canvas></canvas>")
  $("#holder").append($canvas)
  canvas = $canvas.get()[0]
  canvas.width = config.dim
  canvas.height = config.dim
  ctx = canvas.getContext("2d")
  
  $('#word').change (e) ->
    word = $(this).val()
    console.log createWord(word)
    strokeWord(ctx, word)
  console.log createWord($("#word").val())
  strokeWord(ctx, $('#word').val())
