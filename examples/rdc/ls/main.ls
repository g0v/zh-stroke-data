$ ->
  (canvas = document.createElement \canvas)
    ..width  = 2150
    ..height = 2150
    ..style
      ..width  = \430px
      ..height = \430px
  $ \#sprite .append canvas

  colors = <[ #1abc9c #2ecc71 #3498db #9b59b6 #34495e ]>

  p = zh-stroke-data.loaders.JSON "../../json/#{'品'.codePointAt!toString 16}.json"
  p.then ->
    ss = for data in it => new zh-stroke-data.Stroke data
    boxes = for s in ss => s.aabb
    ctx = canvas.getContext \2d
    for i, g of zh-stroke-data.AABB.rdc boxes
      for b in g => b.render ctx, colors[i]
    console.log zh-stroke-data.AABB.hit boxes
