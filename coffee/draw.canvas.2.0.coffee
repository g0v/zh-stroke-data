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

  class AABB
    constructor: (min, max = min) ->
      @min =
        x: Math.min(min.x, max.x)
        y: Math.min(min.y, max.y)
      @max =
        x: Math.max(min.x, max.x)
        y: Math.max(min.y, max.y)
      Object.defineProperty @, "width",
        get: -> @max.x - @min.x
      Object.defineProperty @, "height",
        get: -> @max.y - @min.y
      Object.defineProperty @, "size",
        get: -> @width * @height
    clone: ->
      new AABB(@min, @max)
    addPoint: (pt) ->
      @min.x = pt.x if pt.x < @min.x
      @min.y = pt.y if pt.y < @min.y
      @max.x = pt.x if pt.x > @max.x
      @max.y = pt.y if pt.y > @max.y
    delta: (box) ->
      new AABB(@min, box.min).size + new AABB(@max, box.max).size
    render: (canvas) ->
      ctx = canvas.getContext "2d"
      ctx.strokeStyle = "#F00"
      ctx.lineWidth = 10
      ctx.beginPath()
      ctx.rect @min.x, @min.y, @width, @height
      ctx.stroke()

  class Track
    constructor: (@data, @options) ->
      @length = Math.sqrt @data.vector.x * @data.vector.x + @data.vector.y * @data.vector.y
      @aabb = null
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
      # assert track 0 is inside the outline
      @aabb = new AABB(data.track[0])
      for path in @outline
        if "x" of path
          console.log @aabb
          @aabb.addPoint path
        if "begin" of path
          @aabb.addPoint path.begin
          @aabb.addPoint path.end
        if "mid" of path
          @aabb.addPoint path.mid
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
      @aabb = null
      data.map (strokeData) =>
        stroke = new Stroke strokeData, @options
        @strokes.push stroke
        if not @aabb
          @aabb = stroke.aabb.clone()
        else
          @aabb.addPoint stroke.aabb.min
          @aabb.addPoint stroke.aabb.max
      @length = @strokes.reduce (prev, current) ->
        prev + current.length
      , 0
      @strokeGaps = @strokes.reduce (results, current) =>
        results.concat [results[results.length - 1] + current.length / @length]
      , [0]
      @strokeGaps.shift()
    render: (canvas, percent) ->
      ctx = canvas.getContext "2d"
      ctx.setTransform.apply ctx, @matrix
      len = @length * percent
      for stroke in @strokes
        if len > 0
          stroke.render canvas, Math.min(stroke.length, len) / stroke.length
          stroke.aabb.render canvas
          len -= stroke.length
      @aabb.render canvas

  words = WordStroker.utils.sortSurrogates($word.val())

  data.get(
    words[0].cp
    (json) ->
      word = new Word json,
        scale: options.scales.fill
      # normal animation
      ###
      pixel_per_second = 2000
      step = word.length / pixel_per_second * 60
      i = 0
      before = time = 0
      update = ->
        word.render canvas, time
        before = time
        time += 1 / step
        if time < 1.0
          if before < word.strokeGaps[i] and word.strokeGaps[i] < time
            setTimeout ->
              ++i
              requestAnimationFrame update
            , 500
          else
            requestAnimationFrame update
      requestAnimationFrame update
      ###
      # interactive animation
      inc = false
      dec = false
      $(document)
        .keydown (e) ->
          dec = true if e.which is 37
          inc = true if e.which is 39
        .keyup (e) ->
          dec = false if e.which is 37
          inc = false if e.which is 39
      prev = time = 0
      step = 0.0025
      update = ->
        if prev isnt time
          canvas.width = canvas.width # clear rect
          word.render canvas, time
        prev = time
        time += step if inc
        time = 1.0 if time > 1.0
        time -= step if dec
        time = 0 if time < 0
        requestAnimationFrame update
      requestAnimationFrame update
    (err) ->
      console.log "failed"
    null
  )
