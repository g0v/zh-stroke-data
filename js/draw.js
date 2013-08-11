(function() {
  $(function() {
    var drawOutline, fetchStrokeXml, filterNodes, strokeWord, strokeWords;
    filterNodes = function(childNodes) {
      var n, nodes, _i, _len;
      nodes = [];
      for (_i = 0, _len = childNodes.length; _i < _len; _i++) {
        n = childNodes[_i];
        if (n.nodeType === 1) {
          nodes.push(n);
        }
      }
      return nodes;
    };
    drawOutline = function(paper, outline, pathAttrs) {
      var a, node, path, _i, _len, _ref;
      path = [];
      _ref = outline.childNodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (node.nodeType !== 1) {
          continue;
        }
        a = node.attributes;
        if (!a) {
          continue;
        }
        switch (node.nodeName) {
          case "MoveTo":
            path.push(["M", parseFloat(a.x.value), parseFloat(a.y.value)]);
            break;
          case "LineTo":
            path.push(["L", parseFloat(a.x.value), parseFloat(a.y.value)]);
            break;
          case "CubicTo":
            path.push(["C", parseFloat(a.x1.value), parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value), parseFloat(a.x3.value), parseFloat(a.y3.value)]);
            break;
          case "QuadTo":
            path.push(["Q", parseFloat(a.x1.value), parseFloat(a.y1.value), parseFloat(a.x2.value), parseFloat(a.y2.value)]);
        }
      }
      return paper.path(path).attr(pathAttrs).transform("s0.2,0.2,0,0");
    };
    fetchStrokeXml = function(code, cb) {
      return $.get("utf8/" + code.toLowerCase() + ".xml", cb, "xml");
    };
    strokeWord = function(element, word) {
      var utf8code;
      utf8code = escape(word).replace(/%u/, "");
      return fetchStrokeXml(utf8code, function(doc) {
        var color, delay, dim, gridLines, line, outline, paper, pathAttrs, timeoutSeconds, _i, _j, _len, _len1, _ref, _results;
        dim = 430;
        paper = Raphael(element, dim, dim);
        gridLines = ["M0,0 L0," + dim, "M" + dim + ",0 L" + dim + "," + dim, "M0,0 L" + dim + ",0", "M0," + dim + ",0 L" + dim + "," + dim, "M" + (Math.round(dim / 3)) + ",0 L" + (Math.round(dim / 3)) + "," + dim, "M" + (Math.round(dim / 3 * 2)) + ",0 L" + (Math.round(dim / 3 * 2)) + "," + dim, "M0," + (Math.round(dim / 3)) + " L" + dim + "," + (Math.round(dim / 3)), "M0," + (Math.round(dim / 3 * 2)) + " L" + dim + "," + (Math.round(dim / 3 * 2))];
        for (_i = 0, _len = gridLines.length; _i < _len; _i++) {
          line = gridLines[_i];
          paper.path(line).attr({
            'stroke-width': 1,
            'stroke': '#a33'
          });
        }
        Raphael.getColor();
        Raphael.getColor();
        color = Raphael.getColor();
        pathAttrs = {
          stroke: color,
          "stroke-width": 5,
          "stroke-linecap": "round",
          "fill": color
        };
        timeoutSeconds = 0;
        delay = 500;
        _ref = doc.getElementsByTagName('Outline');
        _results = [];
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          outline = _ref[_j];
          _results.push((function(outline) {
            return setTimeout((function() {
              return drawOutline(paper, outline, pathAttrs);
            }), timeoutSeconds += delay);
          })(outline));
        }
        return _results;
      });
    };
    strokeWords = function(element, words) {
      var a, _i, _len, _ref, _results;
      _ref = words.split(/(?:)/);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        a = _ref[_i];
        _results.push(strokeWord(element, a));
      }
      return _results;
    };
    window.WordStroker || (window.WordStroker = {});
    return window.WordStroker.raphael = {
      strokeWords: strokeWords
    };
  });

}).call(this);

/*
//@ sourceMappingURL=draw.js.map
*/