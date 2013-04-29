$ ->
  $.get "data/c678.xml", ((doc) ->
    paper = Raphael("holder", 430, 430)
    discattr = { fill: "#fff", stroke: "none" }
    color = "hsb(.8, .75, .75)"
    for outline in doc.getElementsByTagName 'Outline'
      path = []
      for node in outline.childNodes
        continue if node.nodeType != 1
        do (node) ->
          a = node.attributes
          # console.log node.nodeType, node.nodeName, node.attributes
          switch node.nodeName
            when "MoveTo"
              path.push [ "M", parseFloat(a.x.value) , parseFloat(a.y.value) ]
            when "LineTo"
              path.push [ "L", parseFloat(a.x.value) , parseFloat(a.y.value) ]
            when "QuadTo"
              path.push [ "Q", parseFloat(a.x1.value) , parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value) ]
      curve = paper.path(path).attr({stroke: color || Raphael.getColor(), "stroke-width": 4, "stroke-linecap": "round", "fill": color })
      curve.transform("s0.2,0.2,0,0")
  ), "xml"
