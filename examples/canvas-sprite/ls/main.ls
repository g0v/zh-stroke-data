$ ->
  { SpriteStroker, PrintingStroker } = zh-stroke-data
  var ss, ps
  $sprite   = $ \#sprite
  $printing = $ \#printing
  $sdelay   = $ \#sdelay
  $cdelay   = $ \#cdelay
  $speed    = $ \#speed
  $stroke   = $ \#stroke
  $char     = $ \#char
  $arrows   = $ \#arrows
  $debug    = $ \#debug
  src =
    moe:
      url: '../../json/'
    scanline:
      url: './', dataType: 'txt'

  inputChanged = ->
    $sprite.empty!
    ss := new SpriteStroker it, src.scanline
    $(\#sprite).append ss.dom-element
    $speed.val   ss.speed
    $stroke.val  ss.stroke-delay
    $sdelay.text ss.stroke-delay
    $char.val    ss.char-delay
    $cdelay.text ss.char-delay
    $arrows.attr \checked, ss.arrows
    $debug.attr \checked, ss.debug
    $printing.empty!
    ps := new PrintingStroker it, src.scanline
    $(\#printing).append ps.dom-element

  $speed.change !-> ss?speed = +$(@).val!
  $stroke.change !->
    ss?stroke-delay = +$(@).val!
    $sdelay.text ss?stroke-delay
  $char.change !->
    ss?char-delay = +$(@).val!
    $cdelay.text ss?char-delay
  $arrows.change !-> ss?arrows = @checked
  $debug.change !-> ss?debug = @checked
  $(\#play).click !->
    ss?pause no
    ss?play!
  $(\#pause).click !-> ss?pause yes
  $(\#words).change !->
    inputChanged $(@).val!
  .change!

  $progress = $ \#progress
  update = !->
    $progress.val ss?currentTime
    requestAnimationFrame update
  requestAnimationFrame update

