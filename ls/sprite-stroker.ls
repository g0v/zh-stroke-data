class SpriteStroker
  @loaders =
    xml : zh-stroke-data.loaders.XML
    json: zh-stroke-data.loaders.JSON
    bin : zh-stroke-data.loaders.Binary
  (str, options) ->
    @options = $.extend do
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
      speed: 1000px_per_sec #px in original resolution
      strokeDelay: 0.2s
      charDelay: 0.4s
      options
    @loop        = @options.loop
    @preload     = @options.preload
    @width       = @options.width
    @height      = @options.height
    @posters     = @options.posters
    @url         = @options.url
    @dataType    = @options.dataType
    @speed       = @options.speed
    @strokeDelay = @options.strokeDelay
    @charDelay   = @options.charDelay
    @dom-element = document.createElement \canvas
    @dom-element.width  = @options.width
    @dom-element.height = @options.height

    @promises = for ch in str.sortSurrogates!
      @@loaders[@dataType] "#{@url}#{ch.codePointAt!toString 16}.#{@dataType}"
    p = @promises[0]
    p.then ~>
      strokes = []
      for i, data of it
        strokes.push new zh-stroke-data.Stroke data
        continue if +i is it.length - 1
        empty = new zh-stroke-data.Empty
        empty.length = @options.speed * @options.strokeDelay
        strokes.push empty
      (@sprite = new zh-stroke-data.Comp strokes)
        ..scale-x = @options.width  / 2150
        ..scale-y = @options.height / 2150
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
  duration           : 0    # rea:qd only
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
      total-time = @sprite.length / @options.speed
      @sprite.time = if @currentTime > total-time then 1 else @currentTime / total-time
      @sprite.render @dom-element
    # should get interval from Date
    @currentTime += 1/60
    requestAnimationFrame @play if not @paused
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
