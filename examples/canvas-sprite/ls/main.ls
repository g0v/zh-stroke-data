$ ->
  var ss, ps
  $sprite =   $ \#sprite
  $printing = $ \#printing
  $sdelay =   $ \#sdelay
  $cdelay =   $ \#cdelay
  $speed =    $ \#speed
  $stroke =   $ \#stroke
  $char =     $ \#char

  inputChanged = ->
    $sprite.empty!
    ss := new zh-stroke-data.SpriteStroker it, url: '../../json/'
    $(\#sprite).append ss.dom-element
    $speed.val   ss.speed
    $stroke.val  ss.stroke-delay
    $sdelay.text ss.stroke-delay
    $char.val    ss.char-delay
    $cdelay.text ss.char-delay
    $printing.empty!
    ps := new zh-stroke-data.PrintingStroker it, url: '../../json/'
    $(\#printing).append ps.dom-element

  $speed.change !-> ss?speed = +$(@).val!
  $stroke.change !->
    ss?stroke-delay = +$(@).val!
    $sdelay.text ss?stroke-delay
  $char.change !->
    ss?char-delay = +$(@).val!
    $cdelay.text ss?char-delay
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

