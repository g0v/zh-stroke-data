$ = require 'jquery'
React = require 'react'

{ W }             = require './Stroker/view'
{ computeLength } = require './Stroker/data'

W = React.createFactory W

data <- $.getJSON '../../json/4e00.json'
data = computeLength data
React.render do
  W { data }
  document.getElementById \app
