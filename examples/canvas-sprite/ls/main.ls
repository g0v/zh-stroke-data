$ ->
  ss = new zh-stroke-data.SpriteStroker \你那邊幾點 url: '../../json/'

  $(\body).append ss.dom-element
  $(\#speed)
    .change !->
      ss.speed = +$(@).val!
    .val ss.speed
  $(\#stroke)
    .change !->
      ss.stroke-delay = +$(@).val!
    .val ss.stroke-delay
  $(\#char)
    .change !->
      ss.char-delay = +$(@).val!
    .val ss.char-delay
  $(\#play).click !->
    ss.pause no
    ss.play!
  $(\#pause).click !-> ss.pause yes
