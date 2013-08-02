$ ->
  filterNodes = (childNodes) ->
    nodes = []
    for n in childNodes
      nodes.push n if n.nodeType == 1
    return nodes

  drawOutline = (paper, outline ,pathAttrs) ->
    path = []
    for node in outline.childNodes
      continue if node.nodeType != 1
      a = node.attributes
      continue unless a
      switch node.nodeName
        when "MoveTo"
          path.push [ "M", parseFloat(a.x.value) , parseFloat(a.y.value) ]
        when "LineTo"
          path.push [ "L", parseFloat(a.x.value) , parseFloat(a.y.value) ]
        when "CubicTo"
          path.push [ "C", parseFloat(a.x1.value) , parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value), parseFloat(a.x3.value), parseFloat(a.y3.value) ]
        when "QuadTo"
          path.push [ "Q", parseFloat(a.x1.value) , parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value) ]
    paper.path(path).attr(pathAttrs).transform("s0.2,0.2,0,0")

  fetchStrokeXml = (code, cb) -> $.get "utf8/" + code.toLowerCase() + ".xml", cb, "xml"

  strokeWord = (element, word) ->
    utf8code = escape(word).replace(/%u/ , "")
    fetchStrokeXml utf8code, (doc) ->
      dim = 430
      paper = Raphael(element, dim, dim)
      gridLines = [
        "M0,0 L0,#{dim}",
        "M#{dim},0 L#{dim},#{dim}",
        "M0,0 L#{dim},0",
        "M0,#{dim},0 L#{dim},#{dim}",
        "M#{Math.round( dim / 3 )},0 L#{Math.round( dim / 3 )},#{dim}",
        "M#{Math.round( dim / 3 *2 )},0 L#{Math.round( dim / 3 *2 )},#{dim}",
        "M0,#{Math.round( dim / 3 )} L#{dim},#{Math.round( dim / 3 )}",
        "M0,#{Math.round( dim / 3 *2 )} L#{dim},#{Math.round( dim / 3 *2 )}"
      ]
      for line in gridLines
        paper.path(line).attr({'stroke-width': 1, 'stroke': '#a33'})

      # color = "hsb(.8, .75, .75)"
      Raphael.getColor() # skip 1st color
      Raphael.getColor() # skip 2second color
      color = Raphael.getColor()
      pathAttrs = { stroke: color, "stroke-width": 5, "stroke-linecap": "round", "fill": color }
      timeoutSeconds = 0
      delay = 500
      for outline in doc.getElementsByTagName 'Outline'
        do (outline) ->
          setTimeout (->
            drawOutline(paper,outline,pathAttrs)
          ), timeoutSeconds += delay

  strokeWords = (element, words) ->
    strokeWord(element, a) for a in words.split //

  window.WordStroker or= {}
  window.WordStroker.raphael =
    strokeWords: strokeWords

  #$('#word').change (e) ->
  #  word = $(this).val()
  #  strokeWords(word)
  #strokeWords($('#word').val())
