(function() {
  var fs, hexFromNumber, push, scale, scale_factor;

  fs = require("fs");

  push = Array.prototype.push;

  scale_factor = 2060.0 / 256;

  scale = function(num) {
    if (num >= 2060) {
      throw "coordinate out of range: " + num;
    }
    return ~~((num + scale_factor / 2) / scale_factor);
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
    var i, offset, offsets, offsetsBuffer, path, prev, results, strokes, _i;
    if (index === 0 || index === 1) {
      return;
    }
    offsets = [];
    results = [];
    for (i = _i = 0; _i <= 255; i = ++_i) {
      strokes = void 0;
      path = "./json/" + packed + (hexFromNumber(i)) + ".json";
      offsets[i] = 0;
      results[i] = [];
      if (fs.existsSync(path)) {
        strokes = require(path);
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
          xs = xs.map(scale);
          ys = ys.map(scale);
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
          xs = xs.map(scale);
          ys = ys.map(scale);
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
    prev = 256 * 4;
    for (i in offsets) {
      if (offsets[i] !== 0) {
        offset = offsets[i];
        offsets[i] = prev;
        prev += offset;
      }
    }
    offsetsBuffer = new Buffer(256 * 4);
    offsets.forEach(function(offset, i) {
      return offsetsBuffer.writeUInt32LE(offset, i * 4);
    });
    process.stdout.write(offsetsBuffer);
    return results.forEach(function(result) {
      var buffer;
      buffer = new Buffer(result);
      if (buffer.length !== result.length) {
        throw "buffer is not a pure uint8 buffer";
      }
      return process.stdout.write(new Buffer(result));
    });
  });

}).call(this);

/*
//@ sourceMappingURL=pack.js.map
*/