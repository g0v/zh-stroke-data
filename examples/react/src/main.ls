$ = require 'jquery'
React = require 'react'

{ W }             = require './Stroker/view'
{ computeLength } = require './Stroker/data'

W = React.createFactory W

data <- $.getJSON '../../json/840c.json'
data     = computeLength data
progress = 0

onEnter = -> console.log 'enter'
onLeave = -> console.log 'leave'
onEnterStroke = -> console.log 'enter stroke'
onLeaveStroke = -> console.log 'leave stroke'

word = React.render do
  W {
    data
    progress
    onEnter
    onLeave
    onEnterStroke
    onLeaveStroke
  }
  document.getElementById \app
update = ->
  word.setProps { progress }
  progress += 10
  requestAnimationFrame update
requestAnimationFrame update
