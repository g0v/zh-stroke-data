$ ->
  filterNodes = (childNodes) ->
    nodes = []
    for n in childNodes
      nodes.push n if n.nodeType == 1
    return nodes

  strokeOutline = (paper, outline ,pathAttrs) ->
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
        when "QuadTo"
          path.push [ "Q", parseFloat(a.x1.value) , parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value) ]
    paper.path(path).attr(pathAttrs).transform("s0.2,0.2,0,0")

  fetchStrokeXml = (code, cb) -> $.get "utf8/" + code.toLowerCase() + ".xml", cb, "xml"

  strokeWord = (word, cb) ->
    utf8code = escape(word).replace(/%u/ , "")
    fetchStrokeXml utf8code, (doc) ->
      outlines = doc.getElementsByTagName 'Outline'

      paper = Raphael("holder", 430, 430)
      # color = "hsb(.8, .75, .75)"
      Raphael.getColor() # skip 1st color
      Raphael.getColor() # skip 2second color
      color = Raphael.getColor()
      pathAttrs = { stroke: color, "stroke-width": 5, "stroke-linecap": "round", "fill": color }
      timeoutSeconds = 0
      delay = 350
      for outline in outlines
        do (outline) ->
          setTimeout (->
            strokeOutline(paper, outline, pathAttrs)
          ), timeoutSeconds += delay

  strokeWords = (words) -> strokeWord(a) for a in words.split(//).reverse()

  $('#word').change (e) ->
    $('#holder').empty()
    word = $(this).val()
    strokeWords(word)

  w = location.hash.replace /^#/, ""
  $('#word').val(w) if w
  strokeWords($('#word').val())
