React = require 'react'

{ svg, g, path, defs, clip-path } = React.DOM
package-name = 'zhStroker'

Track = React.createClass do
  displayName: "#package-name.Track"
  getDefaultProps: ->
    data:
      bgn:
        x: 0
        y: 0
        length: 0
      end:
        x: 0
        y: 0
    x: 0
    y: 0
    progress: Infinity
  render: ->
    { bgn, end } = @props.data
    { progress } = @props
    progress = 0      if progress < 0
    progress = bgn.length if progress > bgn.length
    ratio = progress / bgn.length
    dx = (end.x - bgn.x) * ratio
    dy = (end.y - bgn.y) * ratio
    track = "M#{bgn.x} #{bgn.y} L#{bgn.x + dx} #{bgn.y + dy}"
    valid = not isNaN ratio     and
            ratio isnt Infinity and
            ratio isnt 0
    g do
      x: @props.x
      y: @props.y
      path do
        d: if valid
          then track
          else 'M0 0 L0 0'
        fill: \transparent
        stroke: \#000
        stroke-width: if valid
          then 4 * bgn.size or 250
          else 0
        stroke-linecap: \round
comp-track = React.createFactory Track

Stroke = React.createClass do
  displayName: "#package-name.Stroke"
  getDefaultProps: ->
    data:
      outline: []
      track:   []
      length:  0
    x: 0
    y: 0
    progress: Infinity
    onEnterStroke: ->
    onLeaveStroke: ->
  injectClipPath: ->
    @refs.stroke.getDOMNode!setAttribute 'clip-path' "url(##{@id})"
  componentWillReceiveProps: (next) ->
    { length } = @props.data
    # XXX: one way
    if @props.progress <= 0 and next.progress > 0
      @props.onEnterStroke!
    if @props.progress <= length and next.progress > length
      @props.onLeaveStroke!
  componentDidMount:  -> @injectClipPath ...
  componentDidUpdate: -> @injectClipPath ...
  render: ->
    { length }   = @props.data
    { progress } = @props
    # XXX: guard
    progress = 0      if progress < 0
    progress = length if progress > length
    outline = for cmd in @props.data.outline
      switch cmd.type
        | \M => "M #{cmd.x} #{cmd.y}"
        | \L => "L #{cmd.x} #{cmd.y}"
        | \Q => "Q #{cmd.begin.x} #{cmd.begin.y}, #{cmd.end.x} #{cmd.end.y}"
        | \C => "C #{cmd.begin.x} #{cmd.begin.y}, #{cmd.mid.x} #{cmd.mid.y}, #{cmd.end.x} #{cmd.end.y}"
    outline = "#{outline.join ' '} Z"
    @id = outline.replace new RegExp(' ', \g), '%20'
    track = @props.data.track
    g do
      ref: \stroke
      x: @props.x
      y: @props.y
      defs {},
        # SVG element clip-path is not support yet
        React.createElement do
          \clipPath
          id: @id
          path do
            d: outline
            fill: \#F00
      for i til track.length - 1
        bgn = track[i]
        end = track[i + 1]
        comp = comp-track do
          key:      i
          data:     { bgn, end }
          progress: progress
        progress -= bgn.length
        comp
comp-stroke = React.createFactory Stroke

Word = React.createClass do
  displayName: "#package-name.Word"
  getDefaultProps: ->
    data:
      word:   []
      length: 0
    x: 0
    y: 0
    width:  410
    height: 410
    progress: Infinity
    onEnter: ->
    onLeave: ->
    onEnterStroke: ->
    onLeaveStroke: ->
  componentWillReceiveProps: (next) ->
    { length } = @props.data
    if @props.progress <= 0 and next.progress > 0
      @props.onEnter!
    if @props.progress <= length and next.progress > length
      @props.onLeave!
  render: ->
    { length, word } = @props.data
    { progress }     = @props
    progress = 0      if progress < 0
    progress = length if progress > length
    svg do
      width:  @props.width
      height: @props.height
      view-box: "0 0 2050 2050"
      version: 1.1
      xmlns: '"http://www.w3.org/2000/svg'
      g do
        x: @props.x
        y: @props.y
        for i, stroke of word
          comp = comp-stroke do
            key:      i
            data:     stroke
            progress: progress
            onEnterStroke: @props.onEnterStroke
            onLeaveStroke: @props.onLeaveStroke
          progress -= stroke.length
          comp



/**
class ScanlineTrack extends Comp
  (@data) ->
    super!
    @scale-x = @scale-y = 2
    # FIXME: rethink the workflow in super
    @computeAABB!
    @length *= 2
  computeLength: ->
    @length = @data.lines.length
  computeAABB: ->
    direction = @data.direction
    @aabb = new AABB
    for { idx, start, end } in @data.lines
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
    ctx
      ..beginPath!
      ..fillStyle = \#000
    for i from 0 til ~~(@data.lines.length * @time)
      { idx, start, end } = @data.lines[i]
      if direction is 0
        ctx.fillRect do
          start     * @scale-x + @x
          (idx - 1) * @scale-y + @y
          (end - start) * @scale-x
          @scale-y * 2
      else if direction is 1
        ctx.fillRect do
          (idx - 1) * @scale-x + @x
          start     * @scale-y + @y
          @scale-x * 2
          (end - start) * @scale-y

class ScanlineStroke extends Comp
  (data) ->
    children = for track in data
      new ScanlineTrack track
    super children
/**/

module.exports = { Word, Stroke, Track }
