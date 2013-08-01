$ ->
  fetchStrokeXml = (code, cb) -> $.get "utf8/" + code.toLowerCase() + ".xml", cb, "xml"

  Word = (val, options) ->
    this.options = $.extend(
      dim: 2150
      scales:
        fill: 0.4
        style: 0.25
      trackWidth: 150
      updatesPerStep: 10 # speed, higher is faster
      delays:
        stroke: 0.25
        word: 0.5
    , options)
    this.val = val
    this.utf8code = escape(val).replace(/%u/, "")
    this.strokes = []

    this.canvas = document.createElement("canvas")
    $canvas = $ this.canvas
    $canvas.css "width", this.styleWidth() + "px"
    $canvas.css "height", this.styleHeight() + "px"
    this.canvas.width = this.fillWidth()
    this.canvas.height = this.fillHeight()

    return this

  Word.prototype.init = ->
    this.currentStroke = 0
    this.currentTrack = 0
    this.time = 0.0

  Word.prototype.width = ->
    this.options.dim

  Word.prototype.height = ->
    this.options.dim

  Word.prototype.fillWidth = ->
    this.width() * this.options.scales.fill

  Word.prototype.fillHeight = ->
    this.height() * this.options.scales.fill

  Word.prototype.styleWidth = ->
    this.fillWidth() * this.options.scales.style

  Word.prototype.styleHeight = ->
    this.fillHeight() * this.options.scales.style

  Word.prototype.drawBackground = ->
    ctx = this.canvas.getContext("2d")
    ctx.fillStyle = "#FFF"
    ctx.fillRect(0, 0, this.fillWidth(), this.fillHeight())
    drawBackground(ctx, this.fillWidth())

  Word.prototype.draw = ->
    this.init()
    ctx = this.canvas.getContext("2d")
    ctx.strokeStyle = "#000"
    ctx.fillStyle = "#000"
    ctx.lineWidth = 5
    requestAnimationFrame => this.update()
    this.promise = $.Deferred()

  Word.prototype.update = ->
    return if this.currentStroke >= this.strokes.length
    ctx = this.canvas.getContext("2d")
    stroke = this.strokes[this.currentStroke]
    # will stroke
    if this.time == 0.0
      this.vector =
        x: stroke.track[this.currentTrack + 1].x - stroke.track[this.currentTrack].x
        y: stroke.track[this.currentTrack + 1].y - stroke.track[this.currentTrack].y
        size: stroke.track[this.currentTrack].size
      ctx.save()
      ctx.beginPath()
      pathOutline(ctx, stroke.outline, this.options.scales.fill)
      ctx.clip()
    for i in [1..this.options.updatesPerStep]
      this.time += 0.02
      this.time = 1 if this.time >= 1
      ctx.beginPath()
      ctx.arc(
        (stroke.track[this.currentTrack].x + this.vector.x * this.time) * this.options.scales.fill,
        (stroke.track[this.currentTrack].y + this.vector.y * this.time) * this.options.scales.fill,
        (this.vector.size * 2) * this.options.scales.fill,
        0,
        2 * Math.PI
      )
      ctx.fill()
      break if this.time >= 1
    delay = 0
    # did track stroked
    if this.time >= 1.0
      ctx.restore()
      this.time = 0.0
      this.currentTrack += 1
    # did stroked
    if this.currentTrack >= stroke.track.length - 1
      this.currentTrack = 0
      this.currentStroke += 1
      delay = this.options.delays.stroke
    # did word stroked
    if this.currentStroke >= this.strokes.length
      setTimeout =>
        this.promise.resolve()
      , this.options.delays.word * 1000
    else
      if delay
        setTimeout =>
          requestAnimationFrame => this.update()
        , delay * 1000
      else
        requestAnimationFrame => this.update()

  drawBackground = (ctx, dim) ->
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

  pathOutline = (ctx, outline, scale) ->
    for path in outline
      switch path.type
        when "M"
          ctx.moveTo path.x * scale, path.y * scale
        when "L"
          ctx.lineTo path.x * scale, path.y * scale
        when "C"
          ctx.bezierCurveTo(
            path.begin.x * scale,
            path.begin.y * scale,
            path.mid.x * scale,
            path.mid.y * scale,
            path.end.x * scale,
            path.end.y * scale
          )
        when "Q"
          ctx.quadraticCurveTo(
            path.begin.x * scale,
            path.begin.y * scale,
            path.end.x * scale,
            path.end.y * scale
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

  parseTrack = (track, defaultWidth) ->
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
            size: if a.size then parseFloat(a.size.value) else defaultWidth
    path

  createWordAndView = (element, val, options) ->
    promise = jQuery.Deferred()
    word = new Word(val, options)
    $(element).append word.canvas
    fetchStrokeXml word.utf8code, (doc) ->
      tracks = doc.getElementsByTagName "Track"
      for outline, index in doc.getElementsByTagName 'Outline'
        word.strokes.push
          outline: parseOutline outline
          track: parseTrack tracks[index], word.options.trackWidth
        promise.resolve {
          drawBackground: () ->
            word.drawBackground()
          draw: () ->
            word.draw()
        }
    promise

  createWordsAndViews = (element, words, options) ->
    Array.prototype.map.call words, (word) ->
      return createWordAndView element, word, options

  window.WordStroker or= {}
  window.WordStroker.canvas =
    Word: Word
    createWordsAndViews: createWordsAndViews
