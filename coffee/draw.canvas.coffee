$ ->
  internalOptions =
    dim: 2150
    trackWidth: 150

  demoMatrix = [
    1, 0,
    0, 1,
    100, 100
  ]

  Word = (options) ->
    @options = $.extend(
      scales:
        fill: 0.4
        style: 0.25
      updatesPerStep: 10 # speed, higher is faster
      delays:
        stroke: 0.25
        word: 0.5
      progress: null
    , options, internalOptions)
    @matrix = [
      @options.scales.fill, 0,
      0, @options.scales.fill,
      0, 0
    ]

    # temp hack for custom canvas
    @myCanvas = document.createElement("canvas")
    $canvas = $ @myCanvas
    $canvas.css "width", @styleWidth() + "px"
    $canvas.css "height", @styleHeight() + "px"
    @myCanvas.width = @fillWidth()
    @myCanvas.height = @fillHeight()
    @canvas = @myCanvas

    return this

  Word.prototype.init = ->
    @currentStroke = 0
    @currentTrack = 0
    @time = 0.0

  Word.prototype.width = ->
    @options.dim

  Word.prototype.height = ->
    @options.dim

  Word.prototype.fillWidth = ->
    @width() * @options.scales.fill

  Word.prototype.fillHeight = ->
    @height() * @options.scales.fill

  Word.prototype.styleWidth = ->
    @fillWidth() * @options.scales.style

  Word.prototype.styleHeight = ->
    @fillHeight() * @options.scales.style

  Word.prototype.drawBackground = (canvas) ->
    @canvas = if canvas then canvas else @myCanvas
    ctx = @canvas.getContext("2d")
    ctx.fillStyle = "#FFF"
    ctx.fillRect(0, 0, @fillWidth(), @fillHeight())
    drawBackground(ctx, @fillWidth())

  Word.prototype.draw = (strokeJSON, canvas) ->
    @init()
    @strokes = strokeJSON
    @canvas = if canvas then canvas else @myCanvas
    ctx = @canvas.getContext("2d")
    ctx.strokeStyle = "#000"
    ctx.fillStyle = "#000"
    ctx.lineWidth = 5
    requestAnimationFrame => @update()
    @promise = $.Deferred()

  Word.prototype.update = ->
    return if @currentStroke >= @strokes.length
    ctx = @canvas.getContext "2d"
    ctx.setTransform.apply ctx, @matrix
    stroke = @strokes[@currentStroke]
    # will stroke
    if @time == 0.0
      @vector =
        x: stroke.track[@currentTrack + 1].x - stroke.track[@currentTrack].x
        y: stroke.track[@currentTrack + 1].y - stroke.track[@currentTrack].y
        size: stroke.track[@currentTrack].size or @options.trackWidth
      ctx.save()
      ctx.beginPath()
      pathOutline(ctx, stroke.outline)
      ctx.clip()
    for i in [1..@options.updatesPerStep]
      @time += 0.02
      @time = 1 if @time >= 1
      ctx.beginPath()
      ctx.arc(
        stroke.track[@currentTrack].x + @vector.x * @time,
        stroke.track[@currentTrack].y + @vector.y * @time,
        @vector.size * 2,
        0,
        2 * Math.PI
      )
      ctx.fill()
      break if @time >= 1
    delay = 0
    # did track stroked
    if @time >= 1.0
      ctx.restore()
      @time = 0.0
      @currentTrack += 1
    # did stroked
    if @currentTrack >= stroke.track.length - 1
      @currentTrack = 0
      @currentStroke += 1
      delay = @options.delays.stroke
    # did word stroked
    if @currentStroke >= @strokes.length
      setTimeout =>
        @promise.resolve()
      , @options.delays.word * 1000
    else
      if delay
        setTimeout =>
          requestAnimationFrame => @update()
        , delay * 1000
      else
        requestAnimationFrame => @update()

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

  pathOutline = (ctx, outline) ->
    for path in outline
      switch path.type
        when "M"
          ctx.moveTo path.x, path.y
        when "L"
          ctx.lineTo path.x, path.y
        when "C"
          ctx.bezierCurveTo(
            path.begin.x,
            path.begin.y,
            path.mid.x,
            path.mid.y,
            path.end.x,
            path.end.y
          )
        when "Q"
          ctx.quadraticCurveTo(
            path.begin.x,
            path.begin.y,
            path.end.x,
            path.end.y
          )

  drawElementWithWord = (element, word, options) ->
    promise = jQuery.Deferred()
    stroker = new Word(options)
    $word = $("<div class=\"word\"></div>")
    $loader = $("<div class=\"loader\"><div style=\"width: 0\"></div></div>")
    $word.append(stroker.canvas).append($loader)
    $(element).append $word
    WordStroker.utils.StrokeData.get(
      word.cp,
      # success
      (json) ->
        $loader.remove()
        promise.resolve {
          drawBackground: ->
            do stroker.drawBackground
          draw: ->
            stroker.draw json
          remove: ->
            do $(stroker.canvas).remove
        }
      # fail
      , ->
        $loader.remove()
        promise.resolve {
          drawBackground: ->
            do stroker.drawBackground
          draw: ->
            p = jQuery.Deferred()
            $(stroker.canvas).fadeTo("fast", 0.5, -> p.resolve())
            p
          remove: ->
            do $(stroker.canvas).remove
        }
      , (e) ->
        if e.lengthComputable
          $loader.find("> div").css("width", e.loaded / e.total * 100 + "%")
        promise.notifyWith e, [e, word.text]
    )
    promise

  drawElementWithWords = (element, words, options) ->
    WordStroker.utils.sortSurrogates(words).map (word) ->
      drawElementWithWord element, word, options

  window.WordStroker or= {}
  window.WordStroker.canvas =
    Word: Word
    drawElementWithWords: drawElementWithWords
