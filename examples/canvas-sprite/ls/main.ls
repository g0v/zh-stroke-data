$ ->
  ss = new zh-stroke-data.SpriteStroker \宅度不同 url: '../../json/'

  $sdelay = $ \#sdelay
  $cdelay = $ \#cdelay
  $(\body).append ss.dom-element
  $(\#speed)
    .change !->
      ss.speed = +$(@).val!
    .val ss.speed
  $(\#stroke)
    .change !->
      ss.stroke-delay = +$(@).val!
      $sdelay.text ss.stroke-delay
    .val ss.stroke-delay
  $sdelay.text ss.stroke-delay
  $(\#char)
    .change !->
      ss.char-delay = +$(@).val!
      $cdelay.text ss.char-delay
    .val ss.char-delay
  $cdelay.text ss.char-delay
  $(\#play).click !->
    ss.pause no
    ss.play!
  $(\#pause).click !-> ss.pause yes

  update = !->
    $(\#progress).val ss.currentTime
    requestAnimationFrame update
  requestAnimationFrame update
