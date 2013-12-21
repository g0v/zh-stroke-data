$ ->
  internal-options =
    dim:        2150px
    track-width: 150px

  demo-matrix =
    1   0
    0   1
    100 100

  draw-background = (ctx, dim) ->
    ctx
      ..strokeStyle = \#A33
      ..beginPath!
      ..lineWidth = 10
      ..moveTo   0,   0
      ..lineTo   0, dim
      ..lineTo dim, dim
      ..lineTo dim,   0
      ..lineTo   0,   0
      ..stroke!
      ..beginPath!
      ..lineWidth = 2
      ..moveTo       0,   dim/3
      ..lineTo     dim,   dim/3
      ..moveTo       0, dim/3*2
      ..lineTo     dim, dim/3*2
      ..moveTo   dim/3,       0
      ..lineTo   dim/3,     dim
      ..moveTo dim/3*2,       0
      ..lineTo dim/3*2,     dim
      ..stroke!

  path-outline = (ctx, outline) ->
    for path in outline
      switch path.type
        when \M
          ctx.moveTo path.x, path.y
        when \L
          ctx.lineTo path.x, path.y
        when \C
          ctx.bezierCurveTo do
            path.begin.x
            path.begin.y
            path.mid.x
            path.mid.y
            path.end.x
            path.end.y
        when \Q
          ctx.quadraticCurveTo do
            path.begin.x
            path.begin.y
            path.end.x
            path.end.y

  class Word
    (options) ->
      @options = $.extend do
        scales:
          fill: 0.4
          style: 0.25
        updatesPerStep: 10 # speed, higher is faster
        delays:
          stroke: 0.25
          word: 0.5
        progress: null
        url: "./"
        dataType: "json"
        options
        internalOptions
      @matrix =
        @options.scales.fill, 0,
        0, @options.scales.fill,
        0, 0
      # temp hack for custom canvas
      @myCanvas = document.createElement \canvas
      $ @myCanvas
        .css \width "#{@style-width!}px"
        .css \height "#{@style-height!}px"
      @myCanvas.width = @fill-width!
      @myCanvas.height = @fill-height!
      @canvas = @myCanvas
    init: ->
      @currentStroke = 0
      @currentTrack  = 0
      @time          = 0.0
    width: ->
      @options.dim
    height: ->
      @options.dim
    fill-width: ->
      @width! * @options.scales.fill
    fill-height:->
      @height! * @options.scales.fill
    style-width: ->
      @fill-width! * @options.scales.style
    style-height: ->
      @fill-height! * @options.scales.style
    draw-background: (canvas) ->
      @canvas = if canvas then canvas else @myCanvas
      ctx = @canvas.getContext \2d
      ctx.fillStyle = \#fff
      ctx.fillRect 0, 0, @fillWidth!, @fillHeight!
      drawBackground ctx, @fillWidth!
    draw: (strokeJSON, canvas) ->
      @init!
      @strokes = strokeJSON
      @canvas = if canvas then canvas else @myCanvas
      @canvas.getContext \2d
        ..strokeStyle = \#000
        ..fillStyle = \#000
        ..lineWidth = 5px
      requestAnimationFrame ~> @update!
      @promise = $.Deferred!
    update: ->
      return if @currentStroke >= @strokes.length
      ctx = @canvas.getContext \2d
      ctx.setTransform.apply ctx, @matrix
      stroke = @strokes[@currentStroke]
      # will stroke
      if @time is 0.0
        @vector =
          x:    stroke.track[@currentTrack + 1].x - stroke.track[@currentTrack].x
          y:    stroke.track[@currentTrack + 1].y - stroke.track[@currentTrack].y
          size: stroke.track[@currentTrack].size or @options.trackWidth
        ctx
          ..save!
          ..beginPath!
        path-outline ctx, stroke.outline
        ctx.clip!
      for from 0 til @options.updatesPerStep
        @time += 0.02
        @time = 1 if @time >= 1
        ctx
          ..beginPath!
          ..arc do
            stroke.track[@currentTrack].x + @vector.x * @time
            stroke.track[@currentTrack].y + @vector.y * @time
            @vector.size * 2
            0
            2 * Math.PI
          ..fill()
        break if @time >= 1
      delay = 0
      # did track stroked
      if @time >= 1.0
        ctx.restore!
        @time = 0.0
        @currentTrack += 1
      # did stroked
      if @currentTrack >= stroke.track.length - 1
        @currentTrack = 0
        @currentStroke += 1
        delay = @options.delays.stroke
      # did word stroked
      if @currentStroke >= @strokes.length
        return @promise.resolve! unless @options.delays.word
        setTimeout ~>
          @promise.resolve!
        , @options.delays.word * 1000
      else
        if delay
          setTimeout ~>
            requestAnimationFrame ~> @update!
          , delay * 1000
        else
          @update!

  stroke-word = (element, word, options) ->
    options or= {}
    stroker = new Word(options)
    $word = $ '<div class="word"></div>'
    $loader = $ '<div class="loader"><div style="width: 0"></div><i class="icon-spinner icon-spin icon-large icon-fixed-width"></i></div>'
    $word.append stroker.canvas
    $(element).append $word
    loader = zh-stroke-data.loaders.JSON
    return do
      load: ->
        promise = it or $.Deferred!
        $word.append $loader
        # deal with options.dataType later
        data = loader "#{options.url}json/#{word.codePointAt!toString 16}.json"
        data.then (json) ->
          $loader.remove()
          promise.resolve do
            drawBackground: -> stroker.draw-background!
            draw:           -> stroker.draw json
            remove:         -> $(stroker.canvas).remove!
        .fail ->
          $loader.remove!
          promise.resolve do
            drawBackground: -> stroker.draw-background!
            draw: ->
              p = jQuery.Deferred!
              $(stroker.canvas).fadeTo \fast, 0.5, -> p.resolve!
              p
            remove:         -> $(stroker.canvas).remove!
          # progress
        .progress (e) ->
          if e.lengthComputable
            $loader
              .find '> div'
              .css \width", "#{e.loaded/e.total*100}%"
          promise.notifyWith e, [e, word]
        promise

  window.zh-stroke-data ?= {}
  window.zh-stroke-data.strokers ?= {}
  window.zh-stroke-data.strokers.canvas = (element, words, options) ->
    words.sortSurrogates!map (word) ->
      stroke-word element, word, options
