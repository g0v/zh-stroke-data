class SpriteStroker
  (options) ->
    @options = $.extend do
      autoplay: off
      controls: off
      width: 0
      height: 0
      loop: off
      muted: yes
      preload: 'metadata' # or 'none' or 'auto'
      poster: ''
      src: ''
  # mimic MediaElement
  audioTracks        : 0
  videoTracks        : 0
  textTracks         : 0
  autoplay           : off
  buffered           : null # read only TimeRanges
  controller         : null # MediaController
  controls           : @options.consoles
  #crossOrigin       : ''
  currentSrc         : @src # read only
  src                : @options.src
  currentTime        : 0
  defaultMuted       : @options.muted
  muted              : @defaultMuted
  defaultPlaybackRate: 1.0
  PlaybackRate       : @defaultPlaybackRate
  duration           : 0    # read only
  ended              : no   # read only
  error              : null # read only MediaError
  initialTime        : 0    # read only
  loop               : @options.loop
  mediaGroup         : ''
  #networkState      : 0
  paused             : no   # read only
  played             : no   # read only TimeRanges
  preload            : @options.preload
  #readyState        : 0
  seekable           : null # read only TimeRanges
  seeking            : no   # read only
  volume             : 0
  canPlayType        : (str) -> 'probably' or 'maybe' or ''
  fastSeek           : (time) !->
  load               : !->
  pause              : !->
  play               : !->
  # mimic VideoElement
  width              : @options.width
  height             : @options.height
  videoWidth         : 0    # read only
  videoHeight        : 0    # read only
  poster             : @options.poster

(window.zh-stroke-data ?= {}).stroker ?= {}
window.zh-stroke-data.SpriteStroker = SpriteStroker
