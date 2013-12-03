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
      width: 0
      height: 0
      loop: off
      #muted: yes
      preload: 4chars
      poster: ''
      url: './json/'
      dataType: \json
      ###
      # others
      ###
      speed: 150px_per_sec
      strokeDelay: 0.1s
      charDelay: 0.2s
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

    @promises = for ch in str.sortSurrogates!
      @@loaders[@dataType] "#{@url}#{ch.codePointAt!toString 16}.#{@dataType}"
    for p in @promises => p.then -> console.log it
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
  currentTime        : 0
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
  fastSeek           : (time) !->
  load               : !->
  pause              : !->
  play               : !->
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
