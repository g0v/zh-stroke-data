$ ->
  options =
    dim: 2150
    scales:
      fill: 0.4
      style: 0.25
    ##
    # TODO
    ##
    # It's hard to do delays now
    ##
    delays:
      stroke: 0.25
      word: 0.5

  $holder = $ "#holder"
  $word = $ "#word"
  $canvas = $ "<canvas></canvas>"
  $canvas.css "width", options.dim * options.scales.fill * options.scales.style + "pt"
  $canvas.css "height", options.dim * options.scales.fill * options.scales.style + "pt"
  canvas = $canvas.get()[0]
  canvas.width = options.dim * options.scales.fill
  canvas.height = options.dim * options.scales.fill
  $holder.append $canvas

  data = WordStroker.utils.StrokeData
    url: "./json/"
    dataType: "json"

  class Track
    constructor: (@data, @options) ->
      @length = Math.sqrt @data.vector.x * @data.vector.x + @data.vector.y * @data.vector.y
    render: (canvas, percent) ->
      size = @data.size or @options.trackWidth
      ctx = canvas.getContext "2d"
      ctx.beginPath()
      ctx.strokeStyle = "#000"
      ctx.fillStyle = "#000"
      ctx.lineWidth = 2 * size
      ctx.lineCap = "round"
      ctx.moveTo @data.x, @data.y
      ctx.lineTo(
        @data.x + @data.vector.x * percent
        @data.y + @data.vector.y * percent
      )
      ctx.stroke()

  class Stroke
    constructor: (data, @options) ->
      @outline = data.outline
      @tracks = []
      for i in [1...data.track.length]
        prev = data.track[i-1]
        current = data.track[i]
        @tracks.push new Track
          x: prev.x
          y: prev.y
          vector:
            x: current.x - prev.x
            y: current.y - prev.y
          size: prev.size
        , @options
      @length = @tracks.reduce (prev, current) ->
        prev + current.length
      , 0
    pathOutline: (ctx, outline) ->
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
    render: (canvas, percent) ->
      ctx = canvas.getContext "2d"
      ctx.save()
      ctx.beginPath()
      @pathOutline ctx, @outline
      ctx.clip()
      len = @length * percent
      for track in @tracks
        if len > 0
          track.render canvas, Math.min(track.length, len) / track.length
          len -= track.length
      ctx.restore()

  class Word
    constructor: (data, options) ->
      @options = $.extend(
        scale: 0.4
        trackWidth: 150
      , options)
      @matrix = [
        @options.scale,              0,
                     0, @options.scale,
                     0,              0
      ]
      @strokes = []
      data.map (strokeData) =>
        @strokes.push new Stroke strokeData, @options
      @length = @strokes.reduce (prev, current) ->
        prev + current.length
      , 0
    render: (canvas, percent) ->
      ctx = canvas.getContext "2d"
      ctx.setTransform.apply ctx, @matrix
      len = @length * percent
      for stroke in @strokes
        if len > 0
          stroke.render canvas, Math.min(stroke.length, len) / stroke.length
          len -= stroke.length

  words = WordStroker.utils.sortSurrogates($word.val())

  data.get(
    words[0].cp
    (json) ->
      word = new Word json,
        scale: options.scales.fill
      pixel_per_second = 2000
      step = word.length / pixel_per_second * 60
      time = 0
      update = ->
        word.render canvas, time
        time += 1 / step
        if time < 1.0
          requestAnimationFrame update
      requestAnimationFrame update
    (err) ->
      console.log "failed"
    null
  )
