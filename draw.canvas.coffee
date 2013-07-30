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
    scale: 1
    dim: 2150
    trackWidth: 150
    updatesPerStep: 10 # speed, higher is faster

  Word = (val) ->
    this.val = val
    this.utf8code = escape(val).replace(/%u/, "")
    this.strokes = []
    this.init()

  Word.prototype.init = () ->
    this.currentStroke = 0
    this.currentTrack = 0
    this.time = 0.0

  Word.prototype.draw = (ctx) ->
    that = this
    this.init()
    ctx.fillStyle = "#FFF"
    ctx.fillRect(0, 0, config.dim * config.scale, config.dim * config.scale)
    drawBackground(ctx)
    ctx.strokeStyle = "#000"
    ctx.fillStyle = "#000"
    ctx.lineWidth = 5
    step = () ->
      that.update ctx
      setTimeout step, 250
    requestAnimationFrame step

  Word.prototype.update = (ctx) ->
    return if this.currentStroke >= this.strokes.length
    stroke = this.strokes[this.currentStroke]
    if this.time == 0.0
      this.vector =
        x: stroke.track[this.currentTrack + 1].x - stroke.track[this.currentTrack].x
        y: stroke.track[this.currentTrack + 1].y - stroke.track[this.currentTrack].y
        size: stroke.track[this.currentTrack].size
      ctx.save()
      ctx.beginPath()
      pathOutline(ctx, stroke.outline)
      ctx.clip()
    this.time += 0.02 * config.updatesPerStep
    this.time = 1 if this.time > 1
    # do something
    ctx.beginPath()
    ctx.arc(
      (stroke.track[this.currentTrack].x + this.vector.x * this.time) * config.scale,
      (stroke.track[this.currentTrack].y + this.vector.y * this.time) * config.scale,
      (this.vector.size * 1.5) * config.scale,
      0,
      2 * Math.PI
    )
    ctx.fill()
    if this.time >= 1.0
      ctx.restore()
      this.time = 0.0
      this.currentTrack += 1
      if this.currentTrack >= stroke.track.length - 1
        this.currentTrack = 0
        this.currentStroke += 1
        return
    requestAnimationFrame => this.update ctx

  drawBackground = (ctx) ->
    dim = config.dim * config.scale
    ctx.strokeStyle = "#A33"
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(0, 0)
    ctx.lineTo(0, dim)
    ctx.lineTo(dim, dim)
    ctx.lineTo(dim, 0)
    ctx.lineTo(0, 0)
    ctx.moveTo(0, dim / 3)
    ctx.lineTo(dim, dim / 3)
    ctx.moveTo(0, dim / 3 * 2)
    ctx.lineTo(dim, dim / 3 * 2)
    ctx.moveTo(dim / 3, 0)
    ctx.lineTo(dim / 3, dim)
    ctx.moveTo(dim / 3 * 2, 0)
    ctx.lineTo(dim / 3 * 2, dim)
    ctx.stroke()

  pathOutline = (ctx, outline) ->
    for path in outline
      switch path.type
        when "M"
          ctx.moveTo path.x * config.scale, path.y * config.scale
        when "L"
          ctx.lineTo path.x * config.scale, path.y * config.scale
        when "Q"
          ctx.quadraticCurveTo(
            path.begin.x * config.scale,
            path.begin.y * config.scale,
            path.end.x * config.scale,
            path.end.y * config.scale
          )

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
    word = new Word(val)
    fetchStrokeXml word.utf8code, (doc) ->
      tracks = doc.getElementsByTagName "Track"
      for outline, index in doc.getElementsByTagName 'Outline'
        word.strokes.push
          outline: parseOutline outline
          track: parseTrack tracks[index]
    word

  strokeWords = (words) -> strokeWord(a) for a in words.split //

  $canvas = $("<canvas></canvas>")
  $canvas.css 'transform', 'scale(0.2)'
  $canvas.css 'transform-origin', '0 0'
  $("#holder").append($canvas)
  canvas = $canvas.get()[0]
  canvas.width = config.dim * config.scale
  canvas.height = config.dim * config.scale
  ctx = canvas.getContext("2d")
  
  $('#word').change (e) ->
    word = createWord $(this).val()
    word.draw ctx
  word = createWord $("#word").val()
  word.draw ctx
  #strokeWord(ctx, $('#word').val())
