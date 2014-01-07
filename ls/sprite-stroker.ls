class SpriteStroker
  @loaders =
    xml : zh-stroke-data.loaders.XML
    json: zh-stroke-data.loaders.JSON
    bin : zh-stroke-data.loaders.Binary
  (str, options) ->
    options = $.extend do
      ###
      # mimic <video>
      ###
      autoplay: off
      #controls: off
      width: 215
      height: 215
      loop: off
      #muted: yes
      preload: 4chars
      poster: ''
      url: './json/'
      dataType: \json
      ###
      # others
      ###
      speed: 5000px_per_sec #px in original resolution
      stroke-delay: 0.2s
      char-delay: 1s
      options
    @autoplay = options.autoplay
    @loop     = options.loop
    @preload  = options.preload
    @width    = options.width
    @height   = options.height
    @posters  = options.posters
    @url      = options.url
    @dataType = options.dataType
    @dom-element        = document.createElement \canvas
    @dom-element.width  = @width
    @dom-element.height = @height
    @stroke-gap =
      speed: options.speed
      delay: options.strokeDelay
      objs: []
      update: !->
        for o in @objs
          o.computeLength!
          #bad
          o.parent.childrenChanged!
    @char-gap =
      speed: options.speed
      delay: options.charDelay
      objs: []
      update: !->
        for o in @objs
          o.computeLength!
          o.parent.childrenChanged!
    Object.defineProperty do
      this
      \speed
        set: ->
          @stroke-gap
            ..speed = it
            ..update!
          @char-gap
            ..speed = it
            ..update!
          @stroke-gap.speed
        get: -> @stroke-gap.speed
    Object.defineProperty do
      this
      \strokeDelay
        set: ->
          @stroke-gap
            ..delay = it
            ..update!
          @stroke-gap.delay
        get: -> @stroke-gap.delay
    Object.defineProperty do
      this
      \charDelay
        set: ->
          @char-gap
            ..delay = it
            ..update!
          @char-gap.delay
        get: -> @char-gap.delay

    promises = for ch in str.sortSurrogates!
      @@loaders[@dataType] "#{@url}#{ch.codePointAt!toString 16}.#{@dataType}"
    @arrows = []
    Q.all(promises).then ~>
      chars = []
      # WTF XDDDD
      arrowGroupGroup = []
      for i, char-data of it
        strokes = []
        arrows  = []
        for j, data of char-data
          strokes.push (stroke = new zh-stroke-data.Stroke data)
          arrows.push  (arrow = new zh-stroke-data.Arrow stroke, +j+1)
          arrow.length = stroke.length
          @arrows.push arrow
          continue if +j is it.length - 1
          gap = new zh-stroke-data.Empty @stroke-gap
          @stroke-gap.objs.push gap
          strokes.push gap
          gap = new zh-stroke-data.Empty @stroke-gap
          @stroke-gap.objs.push gap
          arrows.push  gap
        char = new zh-stroke-data.Comp strokes
        arrowGroup = new zh-stroke-data.Comp arrows
        # should be char width
        char.x = 2150 * +i
        arrowGroup.x = char.x
        chars.push char
        arrowGroupGroup.push arrowGroup
        continue if +i is it.length - 1
        gap = new zh-stroke-data.Empty @char-gap
        @char-gap.objs.push gap
        chars.push gap
        gap = new zh-stroke-data.Empty @char-gap
        @char-gap.objs.push gap
        arrowGroupGroup.push gap
      (@sprite = new zh-stroke-data.Comp chars)
        ..scale-x = @width  / 2150
        ..scale-y = @height / 2150
      (@arrowSprite = new zh-stroke-data.Comp arrowGroupGroup)
        ..scale-x = @width  / 2150
        ..scale-y = @height / 2150
      @dom-element.width  = @width * promises.length
      # simple force layout
      step = 0.5
      do
        pairs = zh-stroke-data.AABB.hit do
          for a in @arrows
            (a.globalAABB!)
              ..entity = a
        for p in pairs
          c0 =
            x: (p.0.min.x + p.0.max.x) / 2
            y: (p.0.min.y + p.0.max.y) / 2
          c1 =
            x: (p.1.min.x + p.1.max.x) / 2
            y: (p.1.min.y + p.1.max.y) / 2
          v =
            x: (c1.x - c0.x) * step
            y: (c1.y - c0.y) * step
          p.0.entity
            ..x -= v.x
            ..y -= v.y
          p.1.entity
            ..x += v.x
            ..y += v.y
      while pairs.length isnt 0
  ###
  # mimic MediaElement
  ###
  #audioTracks        : 0
  videoTracks        : 1
  #textTracks         : 0
  autoplay           : off
  buffered           : null # read only TimeRanges
  #controller         : null # MediaController
  #controls           : options.controls
  #crossOrigin       : ''
  #src                : options.src
  #currentSrc         : src # read only
  currentTime        : 0sec
  #defaultMuted       : @options.muted
  #muted              : @defaultMuted
  defaultPlaybackRate: 1.0
  PlaybackRate       : 1.0
  duration           : 0    # read only
  ended              : no   # read only
  error              : null # read only MediaError
  #initialTime        : 0    # read only
  loop               : off
  #mediaGroup         : ''
  #networkState      : 0
  paused             : no   # read only
  played             : no   # read only TimeRanges
  preload            : 4
  #readyState        : 0
  seekable           : null # read only TimeRanges
  seeking            : no   # read only
  #volume             : 0
  canPlayType        : (str) -> 'probably' or 'maybe' or ''
  fastSeek           : (time) !-> @currentTime = time
  load               : !->
  pause              : !-> @paused = !!it
  play               : !~>
    if @sprite
      @dom-element.width = @dom-element.width
      ctx = @dom-element.getContext \2d
      @sprite.render ctx
      @arrowSprite.render ctx#, on
      step = @speed * 1 / 60
      @sprite.time += step / @sprite.length
      @arrowSprite.time = @sprite.time
      @currentTime = @sprite.time * @sprite.length / @speed
    # should get interval from Date
    requestAnimationFrame @play if not @paused and @sprite.time < 1
  ###
  # mimic VideoElement
  ###
  width              : 0
  height             : 0
  videoWidth         : 0    # read only
  videoHeight        : 0    # read only
  poster             : 0

(window.zh-stroke-data ?= {})
  ..SpriteStroker = SpriteStroker
