React = require 'react'
view = require './Stroker/view'

console.log view

React.renderComponent do
  view.W!
  document.getElementById \app
