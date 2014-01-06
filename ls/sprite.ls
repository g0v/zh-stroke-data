class AABB
  axises = <[ x y ]>
  scan = (group, axis = \x) ->
    | not Array.isArray group         => throw new Error 'first argument should be an array'
    | group.0.min[axis] is undefined  => throw new Error 'axis not found'
    | otherwise
      points = []
      for box in group
        if not box.isEmpty!
          points.push do
            box:   box
            value: box.min[axis]
            depth: 1
          points.push do
            value: box.max[axis]
            depth: -1
      points.sort (a, b) ->
        | a.value <  b.value => -1
        | a.value == b.value => 0
        | a.value >  b.value => 1
      groups = []
      g = []
      d = 0
      for p in points
        d += p.depth
        if d isnt 0
          g.push p.box if p.box
        else
          groups.push g
          g = []
      groups
  @rdc = (g, todo = axises.slice!) ->
    | not Array.isArray g         => throw new Error 'first argument should be an array'
    | otherwise
      # 
      results = for axis in todo
        gs = scan g, axis
        if gs.length > 1
          # group split, do rdc in other axises
          next = axises.slice!
          next.splice next.indexOf(axis), 1
          # collect all sub groups
          Array::concat.apply [], for g in gs => @rdc g, next
        else
          gs
      # return longest groups
      results.reduce (c, n) -> if c.length > n.length then c else n
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
  isEmpty: ->
    @min.x >= @max.x or @min.y >= @max.y
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
  render: (canvas, color = \#f00, width = 10px) ->
    canvas.getContext \2d
      ..strokeStyle = color
      ..lineWidth = width
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
  doRender: (ctx) ->
  afterRender: (ctx) ->
  # please dont override this method
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
    @doRender ctx
    @afterRender ctx

class Empty extends Comp
  (@data) -> super!
  computeLength: ->
    @length = @data.speed * @data.delay
  render: ->

class Track extends Comp
  (@data, @options = {}) ->
    super!
    # TODO: should mv init value out here
    @options.trackWidth or= 150px
    @data.size or= @options.trackWidth
  computeLength: ->
    @length = Math.sqrt @data.vector.x * @data.vector.x + @data.vector.y * @data.vector.y
  doRender: (ctx) ->
    ctx
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

class Arrow extends Comp
  (@stroke, @index) ->
    super!
    track = stroke.children.0
    data = track.data
    @vector =
      x: data.vector.x / track.length
      y: data.vector.y / track.length
    angle = Math.atan2(@vector.y, @vector.x)
    angle = if Math.PI/2 > angle >= - Math.PI/2 then angle - Math.PI/2 else angle + Math.PI/2
    @up =
      x: Math.cos angle
      y: Math.sin angle
    x  = data.size / 2 * @vector.x
    y  = data.size / 2 * @vector.y
    x += data.size * 2 / 3 * @up.x
    y += data.size * 2 / 3 * @up.y
    @arrow =
      rear:
        x: x - 64 * @vector.x
        y: y - 64 * @vector.y
      tip:
        x: x + 128 * @vector.x
        y: y + 128 * @vector.y
      text:
        x: x + 64 * @up.x
        y: y + 64 * @up.y
      head:
        x: x + 64 * @vector.x
        y: y + 64 * @vector.y
      edge:
        x: x + 64 * @vector.x + 32 * @up.x
        y: y + 64 * @vector.y + 32 * @up.y
  computeLength: ->
    @length = @stroke.length
  doRender: (ctx) ->
    /*
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
    */

(window.zh-stroke-data ?= {})
  ..AABB   = AABB
  ..Comp   = Comp
  ..Empty  = Empty
  ..Track  = Track
  ..Stroke = Stroke
  ..Arrow  = Arrow
