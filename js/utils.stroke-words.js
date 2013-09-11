(function() {
  var StrokeData, WordStroker, fetchStrokeJSON, fetchStrokeJSONFromBinary, fetchStrokeJSONFromXml, fetchStrokeXml, forEach, getBinary, glMatrix, jsonFromXml, root, sax, sortSurrogates;

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

  getBinary = function(path, success, fail, progress) {
    var xhr;
    xhr = new XMLHttpRequest;
    xhr.open("GET", path, true);
    xhr.responseType = "arraybuffer";
    xhr.onprogress = progress;
    xhr.onreadystatechange = function(e) {
      if (this.readyState === 4) {
        if (this.status === 200) {
          return typeof success === "function" ? success(this.response) : void 0;
        } else {
          return typeof fail === "function" ? fail(this.status) : void 0;
        }
      }
    };
    return xhr.send();
  };

  fetchStrokeJSONFromBinary = function(path, success, fail, progress) {
    var file_id, packed_path;
    if (root.window) {
      packed_path = "" + (path.substr(0, 6)) + (path.substr(path.length - 6, 2)) + ".bin";
      file_id = parseInt(path.substr(6, path.length - 12), 16);
      return getBinary(packed_path, function(data) {
        var cmd, cmd_len, data_view, i, id, index, node, offset, outline, p, ret, scale, size_indices, size_len, stroke_count, strokes_len, track, track_len, _i, _j, _k, _l, _len, _len1, _len2, _len3, _m, _n, _o, _p, _q;
        scale = 2060.0 / 256;
        data_view = new DataView(data);
        stroke_count = data_view.getUint16(0, true);
        for (i = _i = 0; 0 <= stroke_count ? _i < stroke_count : _i > stroke_count; i = 0 <= stroke_count ? ++_i : --_i) {
          id = data_view.getUint16(2 + i * 6, true);
          if (id === file_id) {
            offset = data_view.getUint32(2 + i * 6 + 2, true);
            break;
          }
        }
        if (i === stroke_count) {
          return typeof fail === "function" ? fail(new Error("stroke not found")) : void 0;
        }
        p = 0;
        ret = [];
        strokes_len = data_view.getUint8(offset + p++);
        for (_j = 0; 0 <= strokes_len ? _j < strokes_len : _j > strokes_len; 0 <= strokes_len ? _j++ : _j--) {
          outline = [];
          cmd_len = data_view.getUint8(offset + p++);
          for (_k = 0; 0 <= cmd_len ? _k < cmd_len : _k > cmd_len; 0 <= cmd_len ? _k++ : _k--) {
            outline.push({
              type: String.fromCharCode(data_view.getUint8(offset + p++))
            });
          }
          for (_l = 0, _len = outline.length; _l < _len; _l++) {
            cmd = outline[_l];
            switch (cmd.type) {
              case "M":
                cmd.x = scale * data_view.getUint8(offset + p++);
                break;
              case "L":
                cmd.x = scale * data_view.getUint8(offset + p++);
                break;
              case "Q":
                cmd.begin = {
                  x: scale * data_view.getUint8(offset + p++)
                };
                cmd.end = {
                  x: scale * data_view.getUint8(offset + p++)
                };
                break;
              case "C":
                cmd.begin = {
                  x: scale * data_view.getUint8(offset + p++)
                };
                cmd.mid = {
                  x: scale * data_view.getUint8(offset + p++)
                };
                cmd.end = {
                  x: scale * data_view.getUint8(offset + p++)
                };
            }
          }
          for (_m = 0, _len1 = outline.length; _m < _len1; _m++) {
            cmd = outline[_m];
            switch (cmd.type) {
              case "M":
                cmd.y = scale * data_view.getUint8(offset + p++);
                break;
              case "L":
                cmd.y = scale * data_view.getUint8(offset + p++);
                break;
              case "Q":
                cmd.begin.y = scale * data_view.getUint8(offset + p++);
                cmd.end.y = scale * data_view.getUint8(offset + p++);
                break;
              case "C":
                cmd.begin.y = scale * data_view.getUint8(offset + p++);
                cmd.mid.y = scale * data_view.getUint8(offset + p++);
                cmd.end.y = scale * data_view.getUint8(offset + p++);
            }
          }
          track = [];
          track_len = data_view.getUint8(offset + p++);
          size_indices = [];
          size_len = data_view.getUint8(offset + p++);
          for (_n = 0; 0 <= size_len ? _n < size_len : _n > size_len; 0 <= size_len ? _n++ : _n--) {
            size_indices.push(data_view.getUint8(offset + p++));
          }
          for (_o = 0; 0 <= track_len ? _o < track_len : _o > track_len; 0 <= track_len ? _o++ : _o--) {
            track.push({
              x: scale * data_view.getUint8(offset + p++)
            });
          }
          for (_p = 0, _len2 = track.length; _p < _len2; _p++) {
            node = track[_p];
            node.y = scale * data_view.getUint8(offset + p++);
          }
          for (_q = 0, _len3 = size_indices.length; _q < _len3; _q++) {
            index = size_indices[_q];
            track[index].size = scale * data_view.getUint8(offset + p++);
          }
          ret.push({
            outline: outline,
            track: track
          });
        }
        return typeof success === "function" ? success(ret) : void 0;
      }, fail, progress);
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
    if (window.isCordova) {
      dirs = {
        "xml": "http://stroke.moedict.tw/",
        "json": "http://stroke-json.moedict.tw/",
        "bin": "http://stroke-bin.moedict.tw/"
      };
    } else {
      dirs = {
        "xml": "./utf8/",
        "json": "./json/",
        "bin": "./bin/"
      };
    }
    exts = {
      "xml": ".xml",
      "json": ".json",
      "bin": ".bin"
    };
    fetchers = {
      "xml": fetchStrokeJSONFromXml,
      "json": fetchStrokeJSON,
      "bin": fetchStrokeJSONFromBinary
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
        if (val === "json" || val === "xml" || val === "bin") {
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