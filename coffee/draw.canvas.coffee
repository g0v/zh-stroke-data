$ ->
  internalOptions =
    dim: 2150
    trackWidth: 150

  Word = (val, options) ->
    @options = $.extend(
      scales:
        fill: 0.4
        style: 0.25
      updatesPerStep: 10 # speed, higher is faster
      delays:
        stroke: 0.25
        word: 0.5
    , options, internalOptions)
    @val = val
    @utf8code = escape(val).replace(/%u/, "")
    @strokes = []

    @canvas = document.createElement("canvas")
    $canvas = $ @canvas
    $canvas.css "width", @styleWidth() + "px"
    $canvas.css "height", @styleHeight() + "px"
    @canvas.width = @fillWidth()
    @canvas.height = @fillHeight()

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

  Word.prototype.drawBackground = ->
    ctx = @canvas.getContext("2d")
    ctx.fillStyle = "#FFF"
    ctx.fillRect(0, 0, @fillWidth(), @fillHeight())
    drawBackground(ctx, @fillWidth())

  Word.prototype.draw = ->
    @init()
    ctx = @canvas.getContext("2d")
    ctx.strokeStyle = "#000"
    ctx.fillStyle = "#000"
    ctx.lineWidth = 5
    requestAnimationFrame => @update()
    @promise = $.Deferred()

  Word.prototype.update = ->
    return if @currentStroke >= @strokes.length
    ctx = @canvas.getContext("2d")
    stroke = @strokes[@currentStroke]
    # will stroke
    if @time == 0.0
      @vector =
        x: stroke.track[@currentTrack + 1].x - stroke.track[@currentTrack].x
        y: stroke.track[@currentTrack + 1].y - stroke.track[@currentTrack].y
        size: stroke.track[@currentTrack].size or @options.trackWidth
      ctx.save()
      ctx.beginPath()
      pathOutline(ctx, stroke.outline, @options.scales.fill)
      ctx.clip()
    for i in [1..@options.updatesPerStep]
      @time += 0.02
      @time = 1 if @time >= 1
      ctx.beginPath()
      ctx.arc(
        (stroke.track[@currentTrack].x + @vector.x * @time) * @options.scales.fill,
        (stroke.track[@currentTrack].y + @vector.y * @time) * @options.scales.fill,
        (@vector.size * 2) * @options.scales.fill,
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

  createWordAndView = (element, val, options) ->
    promise = jQuery.Deferred()
    word = new Word(val, options)
    $(element).append word.canvas
    WordStroker.utils.fetchStrokeJSONFromXml(
      "utf8/" + word.utf8code.toLowerCase() + ".xml",
      # success
      (json) ->
        word.strokes = json
        promise.resolve {
          drawBackground: ->
            do word.drawBackground
          draw: ->
            do word.draw
          remove: ->
            do $(word.canvas).remove
        }
      # fail
      , ->
        promise.resolve {
          drawBackground: ->
            do word.drawBackground
          draw: ->
            p = jQuery.Deferred()
            $(word.canvas).fadeTo("fast", 0.5, -> p.resolve())
            p
          remove: ->
            do $(word.canvas).remove
        }
    )
    promise

  createWordsAndViews = (element, words, options) ->
    Array.prototype.map.call words, (word) ->
      return createWordAndView element, word, options

  window.WordStroker or= {}
  window.WordStroker.canvas =
    Word: Word
    createWordsAndViews: createWordsAndViews
