$ = require 'jquery'
React = require 'react'
view = require './Stroker/view'

data <- $.getJSON '../../json/4e00.json'
console.log data
React.renderComponent do
  view.W { data }
  document.getElementById \app
