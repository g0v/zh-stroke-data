(function() {
  var StrokeData, WordStroker, fetchStrokeJSON, fetchStrokeJSONFromRaw, fetchStrokeJSONFromXml, fetchStrokeXml, forEach, getBinary, glMatrix, jsonFromXml, root, sax, sortSurrogates;

  root = this;

  sax = root.sax || require("sax");

  glMatrix = root.glMatrix || require("./gl-matrix-min");

  fetchStrokeXml = function(path, success, fail, progress) {
    var fs;
    if (root.window) {
      return jQuery.ajax({
        type: "GET",
        url: path,
        dataType: "text",
        progress: progress
      }).done(success).fail(fail);
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

  fetchStrokeJSON = function(path, success, fail, progress) {
    var fs;
    if (root.window) {
      return jQuery.ajax({
        type: "GET",
        url: path,
        dataType: "json",
        progress: progress
      }).done(success).fail(fail);
    } else {
      fs = require("fs");
      return fs.readFile(path, {
        encoding: "utf8"
      }, function(err, data) {
        if (err) {
          return fail(err);
        } else {
          return success(JSON.parse(data));
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

  getBinary = function(path, success, fail) {
    var xhr;
    xhr = new XMLHttpRequest;
    xhr.open("GET", path, true);
    xhr.responseType = "arraybuffer";
    xhr.onreadystatechange = function(e) {
      if (this.readyState === 4) {
        if (this.status === 200) {
          return success(this.response);
        } else {
          return fail(this.status);
        }
      }
    };
    return xhr.send();
  };

  fetchStrokeJSONFromRaw = function(path, success, fail, progress) {
    if (root.window) {
      return getBinary(path, function(data) {
        var c, data_view, i, j, len, outline, outlines, ret, scale, track;
        scale = 9;
        data_view = new DataView(data);
        ret = [];
        outlines = void 0;
        i = 0;
        c = void 0;
        while (i < data.byteLength) {
          if (data_view.getUint8(i) !== 0) {
            throw new Error("ill-formated outline: " + i.toString(16));
          }
          i += 1;
          outline = [];
          len = data_view.getUint8(i);
          i += 1;
          j = 0;
          while (j < len) {
            c = data_view.getUint8(i);
            switch (c) {
              case 4:
                outline.push({
                  type: "M",
                  x: scale * data_view.getUint8(i + 1),
                  y: scale * data_view.getUint8(i + 2)
                });
                i += 3;
                break;
              case 5:
                outline.push({
                  type: "L",
                  x: scale * data_view.getUint8(i + 1),
                  y: scale * data_view.getUint8(i + 2)
                });
                i += 3;
                break;
              case 6:
                outline.push({
                  type: "Q",
                  begin: {
                    x: scale * data_view.getUint8(i + 1),
                    y: scale * data_view.getUint8(i + 2)
                  },
                  end: {
                    x: scale * data_view.getUint8(i + 3),
                    y: scale * data_view.getUint8(i + 4)
                  }
                });
                i += 5;
                break;
              case 7:
                outline.push({
                  type: "C",
                  begin: {
                    x: scale * data_view.getUint8(i + 1),
                    y: scale * data_view.getUint8(i + 2)
                  },
                  mid: {
                    x: scale * data_view.getUint8(i + 3),
                    y: scale * data_view.getUint8(i + 4)
                  },
                  end: {
                    x: scale * data_view.getUint8(i + 5),
                    y: scale * data_view.getUint8(i + 6)
                  }
                });
                i += 7;
                break;
              default:
                console.log("unknown cmd: " + c.toString(16) + " at: " + i.toString(16));
            }
            j += 1;
          }
          if (data_view.getUint8(i) !== 1) {
            throw new Error("ill-formated track: " + i.toString(16));
          }
          i += 1;
          track = [];
          len = data_view.getUint8(i);
          i += 1;
          j = 0;
          while (j < len) {
            track.push({
              x: scale * data_view.getUint8(i),
              y: scale * data_view.getUint8(i + 1)
            });
            i += 2;
            j += 1;
          }
          ret.push({
            outline: outline,
            track: track
          });
        }
        return success(ret);
      }, fail);
    } else {
      return console.log("not implement");
    }
  };

  StrokeData = void 0;

  forEach = Array.prototype.forEach;

  sortSurrogates = function(str) {
    var code_point, cps, text;
    cps = [];
    while (str.length) {
      if (/[\uD800-\uDBFF]/.test(str.substr(0, 1))) {
        text = str.substr(0, 2);
        code_point = (text.charCodeAt(0) - 0xD800) * 0x400 + text.charCodeAt(1) - 0xDC00 + 0x10000;
        cps.push({
          cp: code_point.toString(16),
          text: text
        });
        str = str.substr(2);
      } else {
        cps.push({
          cp: str.charCodeAt(0).toString(16),
          text: str.substr(0, 1)
        });
        str = str.substr(1);
      }
    }
    return cps;
  };

  (function() {
    var buffer, dirs, exts, fetchers, source, transform;
    buffer = {};
    source = "json";
    dirs = {
      "xml": "./utf8/",
      "json": "./json/",
      "raw": "./raw/"
    };
    exts = {
      "xml": ".xml",
      "json": ".json",
      "raw": ""
    };
    fetchers = {
      "xml": fetchStrokeJSONFromXml,
      "json": fetchStrokeJSON,
      "raw": fetchStrokeJSONFromRaw
    };
    transform = function(mat2d, x, y) {
      var mat, out, vec;
      vec = glMatrix.vec2.clone([x, y]);
      mat = glMatrix.mat2d.clone(mat2d);
      out = glMatrix.vec2.create();
      glMatrix.vec2.transformMat2d(out, vec, mat);
      return {
        x: out[0],
        y: out[1]
      };
    };
    return StrokeData = {
      source: function(val) {
        if (val === "json" || val === "xml" || val === "raw") {
          return source = val;
        }
      },
      transform: function(strokes, mat2d) {
        var cmd, new_cmd, new_stroke, out, ret, stroke, v, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
        ret = [];
        for (_i = 0, _len = strokes.length; _i < _len; _i++) {
          stroke = strokes[_i];
          new_stroke = {
            outline: [],
            track: []
          };
          _ref = stroke.outline;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            cmd = _ref[_j];
            switch (cmd.type) {
              case "M":
                out = transform(mat2d, cmd.x, cmd.y);
                new_stroke.outline.push({
                  type: cmd.type,
                  x: out.x,
                  y: out.y
                });
                break;
              case "L":
                out = transform(mat2d, cmd.x, cmd.y);
                new_stroke.outline.push({
                  type: cmd.type,
                  x: out.x,
                  y: out.y
                });
                break;
              case "C":
                new_cmd = {
                  type: cmd.type
                };
                out = transform(mat2d, cmd.begin.x, cmd.begin.y);
                new_cmd.begin = {
                  x: out.x,
                  y: out.y
                };
                out = transform(mat2d, cmd.mid.x, cmd.mid.y);
                new_cmd.mid = {
                  x: out.x,
                  y: out.y
                };
                out = transform(mat2d, cmd.end.x, cmd.end.y);
                new_cmd.end = {
                  x: out.x,
                  y: out.y
                };
                new_stroke.outline.push(new_cmd);
                break;
              case "Q":
                new_cmd = {
                  type: cmd.type
                };
                out = transform(mat2d, cmd.begin.x, cmd.begin.y);
                new_cmd.begin = {
                  x: out.x,
                  y: out.y
                };
                out = transform(mat2d, cmd.end.x, cmd.end.y);
                new_cmd.end = {
                  x: out.x,
                  y: out.y
                };
                new_stroke.outline.push(new_cmd);
            }
          }
          _ref1 = stroke.track;
          for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
            v = _ref1[_k];
            out = transform(mat2d, v.x, v.y);
            new_stroke.track.push({
              x: out.x,
              y: out.y
            });
          }
          ret.push(new_stroke);
        }
        return ret;
      },
      get: function(cp, success, fail, progress) {
        if (!buffer[cp]) {
          return fetchers[source](dirs[source] + cp + exts[source], function(json) {
            buffer[cp] = json;
            return typeof success === "function" ? success(json) : void 0;
          }, function(err) {
            return typeof fail === "function" ? fail(err) : void 0;
          }, progress);
        } else {
          return typeof success === "function" ? success(buffer[cp]) : void 0;
        }
      }
    };
  })();

  if (root.window) {
    window.WordStroker || (window.WordStroker = {});
    window.WordStroker.utils = {
      sortSurrogates: sortSurrogates,
      StrokeData: StrokeData,
      fetchStrokeXml: fetchStrokeXml,
      fetchStrokeJSON: fetchStrokeJSON,
      fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
    };
  } else {
    WordStroker = {
      utils: {
        sortSurrogates: sortSurrogates,
        StrokeData: StrokeData,
        fetchStrokeXml: fetchStrokeXml,
        fetchStrokeJSON: fetchStrokeJSON,
        fetchStrokeJSONFromXml: fetchStrokeJSONFromXml
      }
    };
    module.exports = WordStroker;
  }

}).call(this);

/*
//@ sourceMappingURL=utils.stroke-words.js.map
*/