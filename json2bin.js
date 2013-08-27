(function() {
  var push, scale_down;

  push = Array.prototype.push;

  scale_down = function(val) {
    return Math.floor(val / 9);
  };

  process.argv.forEach(function(path, index) {
    var result, strokes;
    if (index === 0 || index === 1) {
      return;
    }
    result = [];
    strokes = require(path);
    strokes.forEach(function(stroke) {
      push.call(result, 0);
      stroke.outline.forEach(function(cmd) {
        switch (cmd.type) {
          case "M":
            return push.call(result, 4, scale_down(cmd.x), scale_down(cmd.y));
          case "L":
            return push.call(result, 5, scale_down(cmd.x), scale_down(cmd.y));
          case "Q":
            return push.call(result, 6, scale_down(cmd.begin.x), scale_down(cmd.begin.y), scale_down(cmd.end.x), scale_down(cmd.end.y));
          case "C":
            return push.call(result, 7, scale_down(cmd.begin.x), scale_down(cmd.begin.y), scale_down(cmd.mid.x), scale_down(cmd.mid.y), scale_down(cmd.end.x), scale_down(cmd.end.y));
        }
      });
      push.call(result, 1);
      return stroke.track.forEach(function(pos) {
        return push.call(result, scale_down(pos.x), scale_down(pos.y));
      });
    });
    return process.stdout.write(new Buffer(result));
  });

}).call(this);

/*
//@ sourceMappingURL=json2bin.js.map
*/