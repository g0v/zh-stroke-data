(function() {
  $(function() {
    var $canvas, $holder, $word, AABB, Stroke, Track, Word, canvas, data, options, words;
    options = {
      dim: 2150,
      scales: {
        fill: 0.4,
        style: 0.25
      },
      delays: {
        stroke: 0.25,
        word: 0.5
      }
    };
    $holder = $("#holder");
    $word = $("#word");
    $canvas = $("<canvas></canvas>");
    $canvas.css("width", options.dim * options.scales.fill * options.scales.style + "pt");
    $canvas.css("height", options.dim * options.scales.fill * options.scales.style + "pt");
    canvas = $canvas.get()[0];
    canvas.width = options.dim * options.scales.fill;
    canvas.height = options.dim * options.scales.fill;
    $holder.append($canvas);
    data = WordStroker.utils.StrokeData({
      url: "./json/",
      dataType: "json"
    });
    AABB = (function() {
      function AABB(min, max) {
        if (max == null) {
          max = min;
        }
        this.min = {
          x: Math.min(min.x, max.x),
          y: Math.min(min.y, max.y)
        };
        this.max = {
          x: Math.max(min.x, max.x),
          y: Math.max(min.y, max.y)
        };
        Object.defineProperty(this, "width", {
          get: function() {
            return this.max.x - this.min.x;
          }
        });
        Object.defineProperty(this, "height", {
          get: function() {
            return this.max.y - this.min.y;
          }
        });
        Object.defineProperty(this, "size", {
          get: function() {
            return this.width * this.height;
          }
        });
      }

      AABB.prototype.clone = function() {
        return new AABB(this.min, this.max);
      };

      AABB.prototype.addPoint = function(pt) {
        if (pt.x < this.min.x) {
          this.min.x = pt.x;
        }
        if (pt.y < this.min.y) {
          this.min.y = pt.y;
        }
        if (pt.x > this.max.x) {
          this.max.x = pt.x;
        }
        if (pt.y > this.max.y) {
          return this.max.y = pt.y;
        }
      };

      AABB.prototype.delta = function(box) {
        return new AABB(this.min, box.min).size + new AABB(this.max, box.max).size;
      };

      AABB.prototype.render = function(canvas) {
        var ctx;
        ctx = canvas.getContext("2d");
        ctx.strokeStyle = "#F00";
        ctx.lineWidth = 10;
        ctx.beginPath();
        ctx.rect(this.min.x, this.min.y, this.width, this.height);
        return ctx.stroke();
      };

      return AABB;

    })();
    Track = (function() {
      function Track(data, options) {
        this.data = data;
        this.options = options;
        this.length = Math.sqrt(this.data.vector.x * this.data.vector.x + this.data.vector.y * this.data.vector.y);
        this.aabb = null;
      }

      Track.prototype.render = function(canvas, percent) {
        var ctx, size;
        size = this.data.size || this.options.trackWidth;
        ctx = canvas.getContext("2d");
        ctx.beginPath();
        ctx.strokeStyle = "#000";
        ctx.fillStyle = "#000";
        ctx.lineWidth = 2 * size;
        ctx.lineCap = "round";
        ctx.moveTo(this.data.x, this.data.y);
        ctx.lineTo(this.data.x + this.data.vector.x * percent, this.data.y + this.data.vector.y * percent);
        return ctx.stroke();
      };

      return Track;

    })();
    Stroke = (function() {
      function Stroke(data, options) {
        var current, i, path, prev, _i, _j, _len, _ref, _ref1;
        this.options = options;
        this.outline = data.outline;
        this.tracks = [];
        for (i = _i = 1, _ref = data.track.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
          prev = data.track[i - 1];
          current = data.track[i];
          this.tracks.push(new Track({
            x: prev.x,
            y: prev.y,
            vector: {
              x: current.x - prev.x,
              y: current.y - prev.y
            },
            size: prev.size
          }, this.options));
        }
        this.length = this.tracks.reduce(function(prev, current) {
          return prev + current.length;
        }, 0);
        this.aabb = new AABB(data.track[0]);
        _ref1 = this.outline;
        for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
          path = _ref1[_j];
          if ("x" in path) {
            console.log(this.aabb);
            this.aabb.addPoint(path);
          }
          if ("begin" in path) {
            this.aabb.addPoint(path.begin);
            this.aabb.addPoint(path.end);
          }
          if ("mid" in path) {
            this.aabb.addPoint(path.mid);
          }
        }
      }

      Stroke.prototype.pathOutline = function(ctx, outline) {
        var path, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = outline.length; _i < _len; _i++) {
          path = outline[_i];
          switch (path.type) {
            case "M":
              _results.push(ctx.moveTo(path.x, path.y));
              break;
            case "L":
              _results.push(ctx.lineTo(path.x, path.y));
              break;
            case "C":
              _results.push(ctx.bezierCurveTo(path.begin.x, path.begin.y, path.mid.x, path.mid.y, path.end.x, path.end.y));
              break;
            case "Q":
              _results.push(ctx.quadraticCurveTo(path.begin.x, path.begin.y, path.end.x, path.end.y));
              break;
            default:
              _results.push(void 0);
          }
        }
        return _results;
      };

      Stroke.prototype.render = function(canvas, percent) {
        var ctx, len, track, _i, _len, _ref;
        ctx = canvas.getContext("2d");
        ctx.save();
        ctx.beginPath();
        this.pathOutline(ctx, this.outline);
        ctx.clip();
        len = this.length * percent;
        _ref = this.tracks;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          track = _ref[_i];
          if (len > 0) {
            track.render(canvas, Math.min(track.length, len) / track.length);
            len -= track.length;
          }
        }
        return ctx.restore();
      };

      return Stroke;

    })();
    Word = (function() {
      function Word(data, options) {
        var _this = this;
        this.options = $.extend({
          scale: 0.4,
          trackWidth: 150
        }, options);
        this.matrix = [this.options.scale, 0, 0, this.options.scale, 0, 0];
        this.strokes = [];
        this.aabb = null;
        data.map(function(strokeData) {
          var stroke;
          stroke = new Stroke(strokeData, _this.options);
          _this.strokes.push(stroke);
          if (!_this.aabb) {
            return _this.aabb = stroke.aabb.clone();
          } else {
            _this.aabb.addPoint(stroke.aabb.min);
            return _this.aabb.addPoint(stroke.aabb.max);
          }
        });
        this.length = this.strokes.reduce(function(prev, current) {
          return prev + current.length;
        }, 0);
        this.strokeGaps = this.strokes.reduce(function(results, current) {
          return results.concat([results[results.length - 1] + current.length / _this.length]);
        }, [0]);
        this.strokeGaps.shift();
      }

      Word.prototype.render = function(canvas, percent) {
        var ctx, len, stroke, _i, _len, _ref;
        ctx = canvas.getContext("2d");
        ctx.setTransform.apply(ctx, this.matrix);
        len = this.length * percent;
        _ref = this.strokes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          stroke = _ref[_i];
          if (len > 0) {
            stroke.render(canvas, Math.min(stroke.length, len) / stroke.length);
            stroke.aabb.render(canvas);
            len -= stroke.length;
          }
        }
        return this.aabb.render(canvas);
      };

      return Word;

    })();
    words = WordStroker.utils.sortSurrogates($word.val());
    return data.get(words[0].cp, function(json) {
      var dec, inc, prev, step, time, update, word;
      word = new Word(json, {
        scale: options.scales.fill
      });
      /*
      pixel_per_second = 2000
      step = word.length / pixel_per_second * 60
      i = 0
      before = time = 0
      update = ->
        word.render canvas, time
        before = time
        time += 1 / step
        if time < 1.0
          if before < word.strokeGaps[i] and word.strokeGaps[i] < time
            setTimeout ->
              ++i
              requestAnimationFrame update
            , 500
          else
            requestAnimationFrame update
      requestAnimationFrame update
      */

      inc = false;
      dec = false;
      $(document).keydown(function(e) {
        if (e.which === 37) {
          dec = true;
        }
        if (e.which === 39) {
          return inc = true;
        }
      }).keyup(function(e) {
        if (e.which === 37) {
          dec = false;
        }
        if (e.which === 39) {
          return inc = false;
        }
      });
      prev = time = 0;
      step = 0.0025;
      update = function() {
        if (prev !== time) {
          canvas.width = canvas.width;
          word.render(canvas, time);
        }
        prev = time;
        if (inc) {
          time += step;
        }
        if (time > 1.0) {
          time = 1.0;
        }
        if (dec) {
          time -= step;
        }
        if (time < 0) {
          time = 0;
        }
        return requestAnimationFrame(update);
      };
      return requestAnimationFrame(update);
    }, function(err) {
      return console.log("failed");
    }, null);
  });

}).call(this);
