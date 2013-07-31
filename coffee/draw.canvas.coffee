$ ->
  fetchStrokeXml = (code, cb) -> $.get "utf8/" + code.toLowerCase() + ".xml", cb, "xml"

  config =
    scale: 0.4
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
    for i in [1..config.updatesPerStep]
      this.time += 0.02
      this.time = 1 if this.time >= 1
      ctx.beginPath()
      ctx.arc(
        (stroke.track[this.currentTrack].x + this.vector.x * this.time) * config.scale,
        (stroke.track[this.currentTrack].y + this.vector.y * this.time) * config.scale,
        (this.vector.size * 2) * config.scale,
        0,
        2 * Math.PI
      )
      ctx.fill()
      break if this.time >= 1
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
    ctx.beginPath()
    ctx.lineWidth = 10
    ctx.moveTo(0, 0)
    ctx.lineTo(0, dim)
    ctx.lineTo(dim, dim)
    ctx.lineTo(dim, 0)
    ctx.lineTo(0, 0)
    ctx.stroke()
    ctx.beginPath()
    ctx.lineWidth = 2
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
        when "C"
          ctx.bezierCurveTo(
            path.begin.x * config.scale,
            path.begin.y * config.scale,
            path.mid.x * config.scale,
            path.mid.y * config.scale,
            path.end.x * config.scale,
            path.end.y * config.scale
          )
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
            size: if a.size then parseFloat(a.size.value) else config.trackWidth
    path

  createWordAndView = (element, val) ->
    $canvas = $ "<canvas></canvas>"
    $canvas.css 'transform', 'scale(0.25)'
    $canvas.css 'transform-origin', '0 0'
    $(element).append($canvas)

    canvas = $canvas.get()[0]
    canvas.width = config.dim * config.scale
    canvas.height = config.dim * config.scale
    ctx = canvas.getContext("2d")

    word = new Word(val)
    fetchStrokeXml word.utf8code, (doc) ->
      tracks = doc.getElementsByTagName "Track"
      for outline, index in doc.getElementsByTagName 'Outline'
        word.strokes.push
          outline: parseOutline outline
          track: parseTrack tracks[index]

    return {
      draw: () ->
        word.draw ctx
    }

  createWordsAndViews = (element, words) ->
    Array.prototype.map.call words, (word) ->
      return createWordAndView element, word

  window.WordStroker or= {}
  window.WordStroker.canvas =
    Word: Word
    createWordsAndViews: createWordsAndViews

  #$('#word').change (e) ->
  #  word = createWord $(this).val()
  #  word.draw ctx
  #word = createWord $("#word").val()
  #word.draw ctx
  #strokeWord(ctx, $('#word').val())
