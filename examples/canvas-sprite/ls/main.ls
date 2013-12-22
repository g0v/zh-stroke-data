$ ->
  $body   = $ \body
  $word   = $ \#word
  /*
  ($canvas = $ \<canvas></canvas>)
    .css \width "#{$body.width!}px"
    .css \height "#{$body.height!}px"
    .css \position \absolute
    .css \top 0px
    .css \left" 0px
  canvas = $canvas.get!0
  canvas.width  = canvas.offsetWidth  = $body.width!  / 0.5
  canvas.height = canvas.offsetHieght = $body.height! / 0.5
  */

  /*
  for let i, ch of $word.val!sortSurrogates!
    i = parseInt i, 10
    w = 2150px * 0.025
    ww = 2150px * 0.025 * 0.5
    width = ~~($body.width() / ww)
    zh-stroke-data.loaders.JSON "../data/json/#{ch.codePointAt!toString 16}.json"
      .then ->
        strokes = it.map -> new zh-stroke-data.Stroke it
        word = new zh-stroke-data.Comp strokes
        word
          ..x = w * ~~(i % width)
          ..y = w * ~~(i / width)
          ..scaleX = 0.025
          ..scaleY = 0.025
          ..time = 1.0
          ..render canvas
      .fail -> console.log ch, it.status
  */

  ss = new zh-stroke-data.SpriteStroker \你那邊幾點 url: '../../json/'
  $(\#speed)
    .change !->
      console.log +$(@).val!
      ss.options.speed = +$(@).val!
    .val ss.options.speed
  $(\#play).click !->
    ss.pause no
    ss.play!
  $(\#pause).click !-> ss.pause yes
  $body.append ss.dom-element
