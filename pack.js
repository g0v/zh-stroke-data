(function() {
  var delta, fs, hexFromNumber, push, scale, scale_factor, undelta,
    __hasProp = {}.hasOwnProperty;

  fs = require("fs");

  push = Array.prototype.push;

  scale_factor = 2060.0 / 256;

  scale = function(num) {
    if (num >= 2060) {
      throw "coordinate out of range: " + num;
    }
    return ~~((num + scale_factor / 2) / scale_factor);
  };

  delta = function(xs) {
    var i, results, _i, _ref;
    results = [xs[0]];
    for (i = _i = 1, _ref = xs.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
      results.push((xs[i] - xs[i - 1] + 256) % 256);
    }
    return results;
  };

  undelta = function(xs) {
    var i, results, _i, _ref;
    results = [xs[0]];
    for (i = _i = 1, _ref = xs.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
      results.push((results[i - 1] + xs[i] + 256) % 256);
    }
    return results;
  };

  hexFromNumber = function(num) {
    var ret;
    ret = num.toString(16);
    if (ret.length < 2) {
      return "0" + ret;
    } else {
      return ret;
    }
  };

  process.argv.forEach(function(packed, index) {
    var buffer, cp, i, key, offset, offsets, offsetsBuffer, path, prev, result, results, stroke_count, strokes, _i, _results;
    if (index === 0 || index === 1) {
      return;
    }
    stroke_count = 0;
    offsets = {};
    results = {};
    for (i = _i = 0; 0 <= 0x0fff ? _i <= 0x0fff : _i >= 0x0fff; i = 0 <= 0x0fff ? ++_i : --_i) {
      strokes = void 0;
      cp = (i << 8) + parseInt(packed, 16);
      path = "./json/" + (cp.toString(16)) + ".json";
      if (fs.existsSync(path)) {
        stroke_count += 1;
        results[i] = [];
        strokes = require(path);
        results[i].push(strokes.length);
        strokes.forEach(function(stroke) {
          var ss, types, with_size, xs, ys;
          if (stroke.outline.length >= 256) {
            throw "outline length out of range: " + stroke.outline.length;
          }
          types = [];
          xs = [];
          ys = [];
          results[i].push(stroke.outline.length);
          stroke.outline.forEach(function(cmd) {
            types.push(cmd.type.charCodeAt(0));
            switch (cmd.type) {
              case "M":
                xs.push(cmd.x);
                return ys.push(cmd.y);
              case "L":
                xs.push(cmd.x);
                return ys.push(cmd.y);
              case "Q":
                xs.push(cmd.begin.x);
                ys.push(cmd.begin.y);
                xs.push(cmd.end.x);
                return ys.push(cmd.end.y);
              case "C":
                xs.push(cmd.begin.x);
                xs.push(cmd.begin.x);
                ys.push(cmd.mid.y);
                ys.push(cmd.mid.y);
                xs.push(cmd.end.x);
                return ys.push(cmd.end.y);
              default:
                throw "unknow path type: " + cmd.type;
            }
          });
          xs = delta(xs.map(scale));
          ys = delta(ys.map(scale));
          push.apply(results[i], types);
          push.apply(results[i], xs);
          push.apply(results[i], ys);
          if (stroke.outline.length >= 256) {
            throw "track length out of range: " + stroke.track.length;
          }
          with_size = [];
          xs = [];
          ys = [];
          ss = [];
          results[i].push(stroke.track.length);
          stroke.track.forEach(function(node, index) {
            xs.push(node.x);
            ys.push(node.y);
            if (node.size !== void 0) {
              with_size.push(index);
              return ss.push(node.size);
            }
          });
          xs = delta(xs.map(scale));
          ys = delta(ys.map(scale));
          ss = ss.map(scale);
          results[i].push(with_size.length);
          push.apply(results[i], with_size);
          push.apply(results[i], xs);
          push.apply(results[i], ys);
          push.apply(results[i], ss);
          return offsets[i] = results[i].length;
        });
      }
    }
    i = 0;
    prev = 2 + stroke_count * 6;
    offsetsBuffer = new Buffer(prev);
    offsetsBuffer.writeUInt16LE(stroke_count, 0);
    for (key in offsets) {
      if (!__hasProp.call(offsets, key)) continue;
      offset = offsets[key];
      offsets[key] = prev;
      offsetsBuffer.writeUInt16LE(key, 2 + i * 6);
      offsetsBuffer.writeUInt32LE(prev, 2 + i * 6 + 2);
      prev += offset;
      i += 1;
    }
    process.stdout.write(offsetsBuffer);
    _results = [];
    for (i in results) {
      if (!__hasProp.call(results, i)) continue;
      result = results[i];
      buffer = new Buffer(result);
      if (buffer.length !== result.length) {
        throw "buffer is not a pure uint8 buffer";
      }
      _results.push(process.stdout.write(new Buffer(result)));
    }
    return _results;
  });

}).call(this);

/*
//@ sourceMappingURL=pack.js.map
*/