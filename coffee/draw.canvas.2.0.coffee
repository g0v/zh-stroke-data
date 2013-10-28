$ ->
  options =
    dim: 2150
    scales:
      fill: 0.4
      style: 0.5
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
  $canvas.css "width", options.dim * options.scales.fill * options.scales.style + "px"
  $canvas.css "height", options.dim * options.scales.fill * options.scales.style + "px"
  canvas = $canvas.get()[0]
  canvas.width = canvas.offsetWidth = options.dim * options.scales.fill
  canvas.height = canvas.offsetHieght = options.dim * options.scales.fill
  $holder.append $canvas

  data = WordStroker.utils.StrokeData
    url: "./json/"
    dataType: "json"

  class AABB
    constructor: (
      @min = {x: Infinity, y: Infinity}
      @max = {x: -Infinity, y: -Infinity}
    ) ->
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
    containPoint: (pt) ->
      pt.x > @min.x and
      pt.y > @min.y and
      pt.x < @max.x and
      pt.y < @max.y
    delta: (box) ->
      new AABB(@min, box.min).size + new AABB(@max, box.max).size
    render: (canvas) ->
      ctx = canvas.getContext "2d"
      ctx.strokeStyle = "#F00"
      ctx.lineWidth = 10
      ctx.beginPath()
      ctx.rect @min.x, @min.y, @width, @height
      ctx.stroke()

  class Comp
    constructor: (@children = [], @aabb) ->
      if not @aabb
        @aabb = new AABB
        @children.forEach (child) =>
          @aabb.addPoint child.aabb.min
          @aabb.addPoint child.aabb.max
      @length = @children.reduce (prev, current) ->
        prev + current.length
      , 0
      @gaps = @children.reduce (results, current) =>
        results.concat [results[results.length - 1] + current.length / @length]
      , [0]
      @gaps.shift()
    breakUp: (strokeNums = []) ->
      comps = []
      strokeNums.reduce (start, len) =>
        end = start + len
        comps.push new Comp @children.slice(start, end)
        end
      , 0
      new Comp comps
    hitTest: (pt) ->
      results = []
      results.push @ if @aabb.containPoint pt
      @children.reduce (prev, child) ->
        prev.concat child.hitTest pt
      , results
    render: (canvas, percent, matrix = [1, 0, 0, 1, 0, 0]) ->
      ctx = canvas.getContext "2d"
      ctx.setTransform.apply ctx, matrix
      len = @length * percent
      for child in @children
        if len > 0
          child.render canvas, Math.min(child.length, len) / child.length, matrix
          len -= child.length

  class Track
    constructor: (@data, @options = {}) ->
      @options.trackWidth or= 150
      @length = Math.sqrt @data.vector.x * @data.vector.x + @data.vector.y * @data.vector.y
      @aabb = new AABB
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

  class Stroke extends Comp
    constructor: (data) ->
      children = []
      for i in [1...data.track.length]
        prev = data.track[i-1]
        current = data.track[i]
        children.push new Track
          x: prev.x
          y: prev.y
          vector:
            x: current.x - prev.x
            y: current.y - prev.y
          size: prev.size
      @outline = data.outline
      aabb = new AABB
      for path in @outline
        if "x" of path
          aabb.addPoint path
        if "end" of path
          aabb.addPoint path.begin
          aabb.addPoint path.end
        if "mid" of path
          aabb.addPoint path.mid
      super children, aabb
    pathOutline: (ctx) ->
      for path in @outline
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
    hitTest: (pt) ->
      if @aabb.containPoint pt then [@] else []
    render: (canvas, percent, matrix) ->
      ctx = canvas.getContext "2d"
      ctx.save()
      ctx.beginPath()
      @pathOutline ctx
      ctx.clip()
      super canvas, percent, matrix
      ctx.restore()

  words = WordStroker.utils.sortSurrogates($word.val())

  data.get(
    words[0].cp
    (json) ->
      strokes = json.map (strokeData) ->
        new Stroke strokeData
      word = new Comp strokes, [
      ]
      word = word.breakUp [4, 4, 4]

      hits = []
      $(canvas).mousemove (e) ->
        pos = $(@).offset()
        mouse =
          x: (e.pageX - pos.left) / options.scales.fill / options.scales.style
          y: (e.pageY - pos.top) / options.scales.fill / options.scales.style
        hits = word.hitTest mouse

      update = ->
        canvas.width = canvas.width # clear rect
        word.render canvas, 1, [
          options.scales.fill,                   0,
                            0, options.scales.fill,
                            0,                   0
        ]
        draw = (o, canvas) ->
          if o.aabb
            o.aabb.render canvas
          else if Array.isArray o
            for c in o
              draw c, canvas
        draw hits, canvas
        requestAnimationFrame update
      requestAnimationFrame update
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
      ###
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
      ###
    (err) ->
      console.log "failed"
    null
  )
