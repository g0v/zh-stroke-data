class AABB
  (
    @min = x: Infinity, y: Infinity
    @max = x: -Infinity, y: -Infinity
  ) ->
    Object.defineProperty @, "width",
      get: -> @max.x - @min.x
    Object.defineProperty @, "height",
      get: -> @max.y - @min.y
    Object.defineProperty @, "size",
      get: -> @width * @height
  clone: ->
    new AABB(@min, @max)
  addPoint: (pt) ->
    @min.x = pt.x if pt.x < @min.x
    @min.y = pt.y if pt.y < @min.y
    @max.x = pt.x if pt.x > @max.x
    @max.y = pt.y if pt.y > @max.y
  addBox: (aabb) ->
    @min.x = aabb.min.x if aabb.min.x < @min.x
    @min.y = aabb.min.y if aabb.min.y < @min.y
    @max.x = aabb.max.x if aabb.max.x > @max.x
    @max.y = aabb.max.y if aabb.max.y > @max.y
  containPoint: (pt) ->
    @min.x < pt.x < @max.x and
    @min.y < pt.y < @max.y
  delta: (box) ->
    new AABB(@min, box.min).size + new AABB(@max, box.max).size
  render: (canvas) ->
    canvas.getContext \2d
      ..strokeStyle = \#f00
      ..lineWidth = 10px
      ..beginPath!
      ..rect @min.x, @min.y, @width, @height
      ..stroke!

class Comp
  (@children = [], @aabb = new AABB) ->
    for child in @children
      child.parent = this
      @aabb.addBox child.aabb
    @computeLength!
    @time = 0.0
    @x = @y = 0px
    @scale-x = @scale-y = 1.0
    @parent = null
  computeLength: ->
    @length = @children.reduce (prev, current) ->
      prev + current.length
    , 0
  childrenChanged: !->
    @computeLength!
    len = 0
    for child in @children
      len += child.time * child.length
    @time = len / @length
    @parent?childrenChanged!
  breakUp: (strokeNums = []) ->
    comps = []
    strokeNums.reduce (start, len) ~>
      end = start + len
      comps.push new Comp @children.slice start, end
      end
    , 0
    new Comp comps
  hitTest: (pt) ->
    results = []
    results.push this if @aabb.containPoint pt
    @children.reduce (prev, child) ->
      prev.concat child.hitTest pt
    , results
  beforeRender: (ctx) ->
  afterRender: (ctx) ->
  render: (canvas) ->
    # calculating scale and position
    x = @x
    y = @y
    scaleX = @scaleX
    scaleY = @scaleY
    p = @parent
    while p
      x += p.x
      y += p.y
      scaleX *= p.scaleX
      scaleY *= p.scaleY
      p = p.parent
    (ctx = canvas.getContext \2d)
      .setTransform scaleX, 0, 0, scaleY, x, y
    @beforeRender ctx
    len = @length * @time
    for child in @children | len > 0
      continue if child.length is 0
      child.time = Math.min(child.length, len) / child.length
      child.render canvas
      len -= child.length
    @afterRender ctx

class Empty extends Comp
  (@data) -> super!
  computeLength: ->
    @length = @data.speed * @data.delay
  render: ->

class Track extends Comp
  (@data, @options = {}) ->
    # TODO: should mv init value out here
    @options.trackWidth or= 150px
    @data.size or= @options.trackWidth
    super!
  computeLength: ->
    @length = Math.sqrt @data.vector.x * @data.vector.x + @data.vector.y * @data.vector.y
  render: (canvas) ->
    canvas.getContext \2d
      ..beginPath!
      ..strokeStyle = \#000
      ..fillStyle = \#000
      ..lineWidth = 2 * @data.size
      ..lineCap = \round
      ..moveTo @data.x, @data.y
      ..lineTo do
        @data.x + @data.vector.x * @time
        @data.y + @data.vector.y * @time
      ..stroke!

class Stroke extends Comp
  (data) ->
    children = []
    for i from 1 til data.track.length
      prev = data.track[i-1]
      current = data.track[i]
      children.push new Track do
        x: prev.x
        y: prev.y
        vector:
          x: current.x - prev.x
          y: current.y - prev.y
        size: prev.size
    @outline = data.outline
    aabb = new AABB
    for path in @outline
      if path.x isnt undefined
        aabb.addPoint path
      if path.end isnt undefined
        aabb.addPoint path.begin
        aabb.addPoint path.end
      if path.mid isnt undefined
        aabb.addPoint path.mid
    super children, aabb
  pathOutline: (ctx) ->
    for path in @outline
      switch path.type
        when \M
          ctx.moveTo path.x, path.y
        when \L
          ctx.lineTo path.x, path.y
        when \C
          ctx.bezierCurveTo do
            path.begin.x, path.begin.y,
            path.mid.x, path.mid.y,
            path.end.x, path.end.y
        when \Q
          ctx.quadraticCurveTo do
            path.begin.x, path.begin.y,
            path.end.x, path.end.y
  hitTest: (pt) ->
    if @aabb.containPoint pt then [@] else []
  beforeRender: (ctx) ->
    ctx
      ..save!
      ..beginPath!
    @pathOutline ctx
    ctx.clip!
  afterRender: (ctx) ->
    ctx.restore!

class IndexedStroke extends Stroke
  (data, @index) ->
    super data
    track = @children.0
    x = track.data.x
    y = track.data.y
    vx = track.data.vector.x / track.length
    vy = track.data.vector.y / track.length
    up = Math.atan2(vy, vx)
    up = if Math.PI/2 > up >= - Math.PI/2 then up - Math.PI/2 else up + Math.PI/2
    upx = Math.cos up
    upy = Math.sin up
    x += track.data.size / 2 * vx
    x += track.data.size * 2 / 3 * upx
    y += track.data.size / 2 * vy
    y += track.data.size * 2 / 3 * upy
    @arrow =
      rear:
        x: x - 64 * vx
        y: y - 64 * vy
      tip:
        x: x + 128 * vx
        y: y + 128 * vy
      text:
        x: x + 64 * upx
        y: y + 64 * upy
      head:
        x: x + 64 * vx
        y: y + 64 * vy
      edge:
        x: x + 64 * vx + 32 * upx
        y: y + 64 * vy + 32 * upy
  afterRender: (ctx) ->
    super ctx
    ctx
      ..strokeStyle = \#c00
      ..lineWidth = 12
      ..beginPath!
      ..moveTo @arrow.rear.x, @arrow.rear.y
      ..lineTo @arrow.tip.x, @arrow.tip.y
      ..stroke!
      ..fillStyle = \#c00
      ..beginPath!
      ..moveTo @arrow.head.x, @arrow.head.y
      ..lineTo @arrow.tip.x, @arrow.tip.y
      ..lineTo @arrow.edge.x, @arrow.edge.y
      ..fill!
      ..font = "128px sans-serif"
      ..textAlign = \center
      ..textBaseline = \middle
      ..fillText @index, @arrow.text.x, @arrow.text.y

(window.zh-stroke-data ?= {})
  ..Comp   = Comp
  ..Empty  = Empty
  ..Track  = Track
  ..Stroke = Stroke
  ..IndexedStroke = IndexedStroke

