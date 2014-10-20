class AABB
  axises = <[ x y ]>
  scan = (group, axis) ->
    | not Array.isArray group         => throw new Error 'first argument should be an array'
    | group.0.min[axis] is undefined  => throw new Error 'axis not found'
    | otherwise
      points = []
      for box in group
        if not box.isEmpty!
          # should not do this over and over again
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
    | not Array.isArray g => throw new Error 'first argument should be an array'
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
  @collide = ->
    | not Array.isArray it => throw new Error 'first argument should be an array'
    | otherwise
      result = []
      for i from 0 til it.length
        for j from i+1 til it.length
          if it[i].intersect it[j]
            result.push [it[i], it[j]]
      result
  @hit = ->
    | not Array.isArray it => throw new Error 'first argument should be an array'
    | otherwise
      Array::concat.apply [], for g in @rdc it => @collide g
  (
    @min = x: Infinity, y: Infinity
    @max = x: -Infinity, y: -Infinity
  ) ->
    if isNaN @min.x then @min.x = Infinity
    if isNaN @min.y then @min.y = Infinity
    if isNaN @max.x then @max.x = -Infinity
    if isNaN @max.y then @max.y = -Infinity
  width:~
    -> @max.x - @min.x
  height:~
    -> @max.y - @min.y
  size:~
    -> @width * @height
  isEmpty: ->
    @min.x >= @max.x or @min.y >= @max.y
  clone: ->
    new AABB(@min, @max)
  # lame solution
  transform: (m00, m01, m10, m11, m20, m21) ->
    aabb = new AABB {
      x: m00 * @min.x + m10 * @min.y + m20
      y: m01 * @min.x + m11 * @min.y + m21
    },{
      x: m00 * @max.x + m10 * @max.y + m20
      y: m01 * @max.x + m11 * @max.y + m21
    }
    aabb
  addPoint: (pt) !->
    @min.x = pt.x if pt.x < @min.x
    @min.y = pt.y if pt.y < @min.y
    @max.x = pt.x if pt.x > @max.x
    @max.y = pt.y if pt.y > @max.y
  addBox: (aabb) !->
    @min.x = aabb.min.x if aabb.min.x < @min.x
    @min.y = aabb.min.y if aabb.min.y < @min.y
    @max.x = aabb.max.x if aabb.max.x > @max.x
    @max.y = aabb.max.y if aabb.max.y > @max.y
  containPoint: (pt) ->
    @min.x < pt.x < @max.x and
    @min.y < pt.y < @max.y
  intersect: ->
    @min.x <= it.max.x and @max.x >= it.min.x and
    @min.y <= it.max.y and @max.y >= it.min.y
  render: (ctx, color = \#f90, width = 10px) !->
    return if @isEmpty!
    ctx
      ..strokeStyle = color
      ..lineWidth = width
      ..beginPath!
      ..rect @min.x, @min.y, @width, @height
      ..stroke!

class Comp
  (@children = []) ->
    for child in @children
      child.parent = this
    @computeAABB!
    @computeLength!
    @time = 0.0
    @x = @y = 0px
    @scale-x = @scale-y = 1.0
    @parent = null
  computeLength: ->
    @length = @children.reduce (prev, current) ->
      prev + current.length
    , 0
  computeAABB: ->
    @aabb = new AABB
    for c in @children
      @aabb.addBox c.aabb.transform do
        c.scale-x, 0,
        0, c.scale-y,
        c.x,     c.y
    @aabb
  globalAABB: ->
    aabb = @aabb
    p = this
    while p
      aabb = aabb.transform p.scale-x, 0, 0, p.scale-y, p.x, p.y
      p = p.parent
    aabb
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
  beforeRender: (ctx) !->
    ctx
      ..save!
      ..transform @scale-x, 0, 0, @scale-y, @x, @y
  doRender:     (ctx) !->
  afterRender:  (ctx) !-> ctx.restore!
  # please dont override this method
  render: (ctx, aabb = off) !->
    #ctx.transform @scale-x, 0, 0, @scale-y, @x, @y
    @beforeRender ctx
    @aabb.render ctx if aabb
    len = @length * @time
    for child in @children | len > 0
      continue if child.length is 0
      child.time = Math.min(child.length, len) / child.length
      child.render ctx, aabb
      len -= child.length
    @doRender ctx
    @afterRender ctx

class Empty extends Comp
  (@data) -> super!
  computeLength: ->
    @length = @data.speed * @data.delay
  computeAABB: ->
    @aabb = new AABB
  render: ~>

class Track extends Comp
  (@data, @options = {}) ->
    # TODO: should mv init value out here
    @options.trackWidth or= 150px
    @data.size or= @options.trackWidth
    super!
  computeLength: ->
    @length = Math.sqrt @data.vector.x * @data.vector.x + @data.vector.y * @data.vector.y
  computeAABB: ->
    @aabb = new AABB {
      x: @data.x
      y: @data.y
    },{
      x: @data.x + @data.vector.x
      y: @data.y + @data.vector.y
    }
  doRender: (ctx) !->
    ctx
      ..beginPath!
      ..strokeStyle = \#000
      ..fillStyle = \#000
      ..lineWidth = 4 * @data.size
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
    super children
  computeAABB: ->
    @aabb = new AABB
    for path in @outline
      if path.x isnt undefined
        @aabb.addPoint path
      if path.end isnt undefined
        @aabb.addPoint path.begin
        @aabb.addPoint path.end
      if path.mid isnt undefined
        @aabb.addPoint path.mid
    @aabb
  pathOutline: (ctx) !->
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
  beforeRender: (ctx) !->
    super ctx
    ctx
      ..save!
      ..beginPath!
    @pathOutline ctx
    ctx.clip!
  afterRender: (ctx) !->
    ctx.restore!
    super ctx

class ScanlineTrack extends Comp
  (@data) ->
    @scale-x = @scale-y = 4
  computeLength: ->
    @length = @data.lines.length *
      if @data.direction is 0
        then @scale-x
        else @scale-y
  computeAABB: ->
    direction = @data.direction
    @aabb = new AABB
    for {idx, start, end} in @data.lines
      if direction is 0 # vertical
        @aabb.addBox new AABB {
          x: start * @scale-x + @x
          y: idx   * @scale-y + @y
        }, {
          x: end       * @scale-x + @x
          y: (idx + 1) * @scale-y + @y
        }
      else if direction is 1 # horizontal
        @aabb.addBox new AABB {
          x: idx   * @scale-x + @x
          y: start * @scale-y + @y
        }, {
          x: (idx + 1) * @scale-x + @x
          y: end       * @scale-y + @y
        }
    @aabb
  doRender: (ctx) !->
    direction = @data.direction
    ctx.fillStyle = \#000
    for i from 0 til ~~(@data.lines.length * @time)
      {idx, start, end}
      if direction is 0
        ctx.fillRect do
          idx   * @scale.x + @x
          start * @scale.y + @y
          @scale.x
          (end - start) * @scale.y
      else if dircetion is 1
        ctx.fillRect do
          start * @scale.x + @x
          idx   * @scale.y + @y
          (end - start) * @scale.x
          @scale.y

class ScanlineStroke extends Comp
  (data) ->
    console.log data
    children = for track in data
      new ScanlineTrack track
    super children

class Arrow extends Comp
  (@stroke, @index) ->
    max = stroke.children.reduce (c, n) ->
      if c.length > n.length then c else n
    @track0 = stroke.children.0
    var track
    for t in stroke.children
      if t.length > max.length / 2.5
        track = t
        break
    data = track.data
    @offset =
      x: 0
      y: 0
    @vector =
      x: data.vector.x / track.length
      y: data.vector.y / track.length
    @angle = Math.atan2(@vector.y, @vector.x)
    angle = if Math.PI/2 > @angle >= - Math.PI/2 then @angle - Math.PI/2 else @angle + Math.PI/2
    @up =
      x: Math.cos angle
      y: Math.sin angle
    @dir = 1
    @size = 160
    super!
    @computeOffset 0
    @x = stroke.x + @track0.data.x
    @y = stroke.y + @track0.data.y
  computeLength: ->
    @length = @stroke.length
  computeAABB: ->
    @aabb = new AABB
    @aabb.addPoint do
      x: @offset.x
      y: @offset.y
    @aabb.addPoint do
      x: @offset.x + @size * @vector.x
      y: @offset.y + @size * @vector.y
    @aabb.addPoint do
      x: @offset.x + @vector.x * @size * 0.5 + (if @dir >= 0 then 1 else -1) * @up.x * @size * 0.5
      y: @offset.y + @vector.y * @size * 0.5 + (if @dir >= 0 then 1 else -1) * @up.y * @size * 0.5
    @aabb
  ##
  # At first, move the arrow forward,         (0 <= it < 1)
  # if still collide, swap to the other side. (1 <= it)
  computeOffset: ->
    it = +it
    if it < 0
      it = 0
    else if it < 1
      @dir = 1
    else
      @dir = -~~(it - 1) - 1
    p = Math.abs it
    percent = p - ~~p
    @offset
      ..x = @dir * @track0.data.size * @up.x / 2 + percent * @size * @vector.x
      ..y = @dir * @track0.data.size * @up.y / 2 + percent * @size * @vector.y
    @computeAABB!
  #render: !-> super it, on
  drawArrow: (ctx, color = \#c00, width = 16, bold = no) !->
    ctx
      ..lineCap = \round
      ..strokeStyle = color
      ..lineWidth = width
      ..beginPath!
      ..moveTo @offset.x, @offset.y
      ..lineTo do
        @offset.x + @vector.x * @size * 0.66
        @offset.y + @vector.y * @size * 0.66
      ..stroke!
      ..fillStyle = color
      ..beginPath!
      ..moveTo do
        @offset.x + @vector.x * @size * 0.66
        @offset.y + @vector.y * @size * 0.66
      ..lineTo do
        @offset.x + @vector.x * @size
        @offset.y + @vector.y * @size
      ..lineTo do
        @offset.x + @vector.x * @size * 0.66 + (if @dir >= 0 then 1 else -1) * @up.x * @size * 0.25
        @offset.y + @vector.y * @size * 0.66 + (if @dir >= 0 then 1 else -1) * @up.y * @size * 0.25
      ..stroke!
      ..fill!
      ..font = "#{@size*2/3}px sans-serif" + if bold then ' bold' else ''
      ..textAlign = \center
      ..textBaseline = \middle
      ..fillText do
        @index
        @offset.x + @vector.x * @size * 0.33 + (if @dir >= 0 then 1 else -1) * @up.x * @size * 0.33
        @offset.y + @vector.y * @size * 0.33 + (if @dir >= 0 then 1 else -1) * @up.y * @size * 0.33
  doRender: (ctx) !->
    @drawArrow ctx, \#fff, 32, yes
    @drawArrow ctx

(window.zh-stroke-data ?= {}) <<< {
  AABB, Comp, Empty, Track, Stroke, ScanlineTrack, ScanlineStroke, Arrow
}
