class SpriteStroker
  (@comp, options) ->
  # mimic MediaElement
  audioTracks        : 0
  videoTracks        : 0
  textTracks         : 0
  autoplay           : off
  buffered           : null # read only TimeRanges
  controller         : null # MediaController
  controls           : off
  #crossOrigin       : ''
  currentSrc         : ''   # read only
  currentTime        : 0
  defaultMuted       : yes
  defaultPlaybackRate: 1.0
  PlaybackRate       : 1.0
  duration           : 0    # read only
  ended              : no   # read only
  error              : null # read only MediaError
  initialTime        : 0    # read only
  loop               : off
  mediaGroup         : ''
  muted              : yes
  #networkState      : 0
  paused             : no   # read only
  played             : no   # read only
  preload            : ''
  #readyState        : 0
  seekable           : null # read only TimeRanges
  seeking            : no   # read only
  src                : ''
  volume             : 0
  canPlayType        : (str) -> 'probably' or 'maybe' or ''
  fastSeek           : (time) !->
  load               : !->
  pause              : !->
  play               : !->
  # mimic VideoElement
  width              : 0
  height             : 0
  videoWidth         : 0
  videoHeight        : 0
  poster             : ''

(window.zh-stroke-data ?= {}).stroker ?= {}
window.zh-stroke-data.SpriteStroker = SpriteStroker
