$ ->
  drawOutline = (paper, outline ,pathAttrs) ->
    path = []
    for cmd in outline
      switch cmd.type
        when "M"
          path.push [ "M", cmd.x, cmd.y ]
        when "L"
          path.push [ "L", cmd.x, cmd.y ]
        when "C"
          path.push [ "C", cmd.begin.x, cmd.begin.y, cmd.mid.x, cmd.mid.y, cmd.end.x, cmd.mid.y ]
        when "Q"
          path.push [ "Q", cmd.begin.x, cmd.begin.y, cmd.end.x, cmd.end.y ]
    paper.path(path).attr(pathAttrs).transform("s0.2,0.2,0,0")

  strokeWord = (element, word) ->
    utf8code = escape(word).replace(/%u/ , "").toLowerCase()
    console.log(utf8code)
    zhStrokeData.loaders.XML("../data/utf8/" + utf8code + ".xml").then (strokes) ->
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
      for stroke in strokes
        do (stroke) ->
          setTimeout (->
            drawOutline(paper,stroke.outline,pathAttrs)
          ), timeoutSeconds += delay

  window.strokeWords = (element, words) ->
    strokeWord(element, a) for a in words.split //

  #window.WordStroker or= {}
  #window.WordStroker.raphael =
  #  strokeWords: strokeWords

  #$('#word').change (e) ->
  #  word = $(this).val()
  #  strokeWords(word)
  #strokeWords($('#word').val())
