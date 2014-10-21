{
  AABB, loaders, Stroke, ScanlineStroke, Empty, Comp,
  hintDataFromMOE, hintDataFromScanline, Hint
} = zh-stroke-data

class SpriteStroker
  @loaders = loaders{ xml:XML, json:JSON, bin:Binary, txt:Scanline }
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
      arrows: no
      debug: no
      options
    @autoplay = options.autoplay
    @loop     = options.loop
    @preload  = options.preload
    @width    = options.width
    @height   = options.height
    @posters  = options.posters
    @url      = options.url
    @dataType = options.dataType
    @arrows   = options.arrows
    @debug    = options.debug
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
    @arrow-list = []
    Q.all(promises).then ~>
      chars = []
      # XXX: GroupGroup, WTF XDDDD
      arrowGroupGroup = []
      for i, char-data of it
        strokes = []
        arrows  = []
        count = char-data.length / 2
        arrow-size = (2150 - (count * 40)) / count
        for j, data of char-data
          if @dataType is 'txt'
            stroke = new ScanlineStroke data
            arrow = new Hint hintDataFromScanline data
          else
            stroke = new Stroke data
            arrow = new Hint hintDataFromMOE data
          strokes.push stroke
          arrow
            ..x = stroke.x
            ..y = stroke.y
            ..text = +j + 1
            ..size = Math.min arrow.size, arrow-size
            ..length = stroke.length
            ..step = 0
            ..computeOffset 0
          arrows.push arrow
          @arrow-list.push arrow
          continue if +j is it.length - 1
          gap = new Empty @stroke-gap
          @stroke-gap.objs.push gap
          strokes.push gap
          gap = new Empty @stroke-gap
          @stroke-gap.objs.push gap
          arrows.push gap
        char = new Comp strokes
        arrowGroup = new Comp arrows
        # should be char width
        char.x = 2150 * +i
        arrowGroup.x = char.x
        chars.push char
        arrowGroupGroup.push arrowGroup
        continue if +i is it.length - 1
        gap = new Empty @char-gap
        @char-gap.objs.push gap
        chars.push gap
        gap = new Empty @char-gap
        @char-gap.objs.push gap
        arrowGroupGroup.push gap
      (@sprite = new Comp chars)
        ..scale-x = @width  / 2150
        ..scale-y = @height / 2150
      (@arrowSprite = new Comp arrowGroupGroup)
        ..scale-x = @width  / 2150
        ..scale-y = @height / 2150
      @dom-element.width  = @width * promises.length
      # simple force layout
      /**/
      step = 0.05
      do
        pairs = zh-stroke-data.AABB.hit do
          for a in @arrow-list
            (a.globalAABB!)
              ..entity = a
        for p in pairs
          e = if p.0.entity.angle > p.1.entity.angle then p.0.entity else p.1.entity
          e
            ..step += step
            ..computeOffset e.step
      while pairs.length isnt 0
      /**/
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
      @sprite.render ctx, @debug
      @arrowSprite.render(ctx, @debug) if @arrows
      step = @speed * 1 / 60
      @sprite.time += step / @sprite.length
      @arrowSprite.time = @sprite.time if @arrows
      @currentTime = @sprite.time * @sprite.length / @speed
    # should get interval from Date
    requestAnimationFrame @play if not @paused and @sprite?time < 1
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
