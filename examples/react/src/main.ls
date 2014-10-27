$ = require 'jquery'
React = require 'react'

{ W } = require './Stroker/view'
W = React.createFactory W

data <- $.getJSON '../../json/4e00.json'
console.log data
React.render do
  W { data }
  document.getElementById \app
