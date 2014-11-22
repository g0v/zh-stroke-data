$ = require 'jquery'
React = require 'react'

{ Word }          = require './Stroker/view'
{ computeLength } = require './Stroker/data'

Word = React.createFactory Word

data <- $.getJSON '../../json/840c.json'
data     = computeLength data
progress = 0

onEnter = -> console.log 'enter'
onLeave = -> console.log 'leave'
onEnterStroke = -> console.log 'enter stroke'
onLeaveStroke = -> console.log 'leave stroke'

word = React.render do
  Word {
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
