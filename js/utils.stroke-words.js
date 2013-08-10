(function() {
  var StrokeData, WordStroker, fetchStrokeJSONFromXml, fetchStrokeXml, forEach, jsonFromXml, root, sax;

  root = this;

  sax = root.sax || require("sax");

  StrokeData = void 0;

  forEach = Array.prototype.forEach;

  (function() {
    var buffer, dirs, source;
    buffer = {};
    source = "xml";
    dirs = {
      "xml": "./utf8/",
      "json": "./json/"
    };
    return StrokeData = {
      source: function(val) {
        if (val === "json" || val === "xml") {
          return source = val;
        }
      },
      get: function(str, success, fail) {
        return forEach.call(str, function(c) {
          var utf8code;
          if (!buffer[c]) {
            utf8code = escape(c).replace(/%u/, "").toLowerCase();
            return fetchStrokeJSONFromXml(dirs[source] + utf8code + "." + source, function(json) {
              buffer[c] = json;
              return typeof success === "function" ? success(json) : void 0;
            }, function(err) {
              return typeof fail === "function" ? fail(err) : void 0;
            });
          } else {
            return typeof success === "function" ? success(buffer[c]) : void 0;
          }
        });
      }
    };
  })();

  fetchStrokeXml = function(path, success, fail) {
    var fs;
    if (root.window) {
      return jQuery.get(path, success, "text").fail(fail);
    } else {
      fs = require("fs");
      return fs.readFile(path, {
        encoding: "utf8"
      }, function(err, data) {
        if (err) {
          return fail(err);
        } else {
          return success(data);
        }
      });
    }
  };

  jsonFromXml = function(doc, success, fail) {
    var outline, outlines, parser, ret, strict, track, tracks;
    ret = [];
    outlines = [];
    tracks = [];
    outline = void 0;
    track = void 0;
    strict = true;
    parser = sax.parser(strict);
    parser.onopentag = function(node) {
      if (outline !== void 0) {
        switch (node.name) {
          case "MoveTo":
            return outline.push({
              type: "M",
              x: parseFloat(node.attributes.x),
              y: parseFloat(node.attributes.y)
            });
          case "LineTo":
            return outline.push({
              type: "L",
              x: parseFloat(node.attributes.x),
              y: parseFloat(node.attributes.y)
            });
          case "CubicTo":
            return outline.push({
              type: "C",
              begin: {
                x: parseFloat(node.attributes.x1),
                y: parseFloat(node.attributes.y1)
              },
              mid: {
                x: parseFloat(node.attributes.x2),
                y: parseFloat(node.attributes.y2)
              },
              end: {
                x: parseFloat(node.attributes.x3),
                y: parseFloat(node.attributes.y3)
              }
            });
          case "QuadTo":
            return outline.push({
              type: "Q",
              begin: {
                x: parseFloat(node.attributes.x1),
                y: parseFloat(node.attributes.y1)
              },
              end: {
                x: parseFloat(node.attributes.x2),
                y: parseFloat(node.attributes.y2)
              }
            });
        }
      } else if (track !== void 0) {
        switch (node.name) {
          case "MoveTo":
            return track.push({
              x: parseFloat(node.attributes.x),
              y: parseFloat(node.attributes.y),
              size: node.attributes.size ? parseFloat(node.attributes.size) : void 0
            });
        }
      } else {
        if (node.name === "Outline") {
          outline = [];
        }
        if (node.name === "Track") {
          return track = [];
        }
      }
    };
    parser.onclosetag = function(name) {
      if (name === "Outline") {
        outlines.push(outline);
        outline = void 0;
      }
      if (name === "Track") {
        tracks.push(track);
        return track = void 0;
      }
    };
    parser.onend = function() {
      var i, _i, _len;
      for (i = _i = 0, _len = outlines.length; _i < _len; i = ++_i) {
        outline = outlines[i];
        track = tracks[i];
        ret.push({
          outline: outline,
          track: track
        });
      }
      return success(ret);
    };
    parser.onerror = function(err) {
      return fail(err);
    };
    return parser.write(doc).close();
  };

  fetchStrokeJSONFromXml = function(path, success, fail) {
    return fetchStrokeXml(path, function(doc) {
      return jsonFromXml(doc, success, fail);
    }, fail);
  };

  if (root.window) {
    window.WordStroker || (window.WordStroker = {});
    window.WordStroker.utils = {
      fetchStrokeXml: fetchStrokeXml,
      jsonFromXml: jsonFromXml,
      fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
    };
  } else {
    WordStroker = {
      utils: {
        StrokeData: StrokeData,
        fetchStrokeXml: fetchStrokeXml,
        fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
      }
    };
    module.exports = WordStroker;
  }

}).call(this);

/*
//@ sourceMappingURL=utils.stroke-words.js.map
*/